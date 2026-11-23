import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/alerts.dart';
import '../models/hardware.dart';
import '../models/history.dart';
import '../models/metric.dart';
import '../models/serialization.dart';
import '../models/snapshot.dart';
import 'station_repository.dart';

/// Données réelles depuis Firebase Realtime Database.
///
/// Structure attendue (écrite par l'ESP32, voir `firmware/` et `docs/`) :
///
/// ```
/// stations/{stationId}/
///   latest   : { t, temperature, humidity, pressure, light, rain, rainRaw, lightRaw }
///   history  : { <pushId>: { t, temperature, humidity, pressure, light, rain } }
///   info     : { name, transmitEverySec, rssi, firmware }
///   rules    : { <ruleId>: { metric, direction, threshold, enabled } }   (application)
///   events   : { <eventId>: { ... } }                                     (application)
/// ```
///
/// `t` est l'horodatage serveur en millisecondes (ServerValue.timestamp).
class FirebaseStationRepository implements StationRepository {
  FirebaseStationRepository({
    FirebaseDatabase? database,
    this.stationId = const String.fromEnvironment('ATMOS_STATION_ID',
        defaultValue: 'station01'),
    this.onlineWindow = const Duration(minutes: 2),
    this.staleWindow = const Duration(minutes: 30),
  }) : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final String stationId;

  /// Âge maximal d'une mesure pour considérer la station « en ligne ».
  final Duration onlineWindow;

  /// Au-delà de cet âge, la station est « hors ligne » (entre les deux :
  /// « données anciennes »).
  final Duration staleWindow;

  DateTime? _lastSeen;

  DatabaseReference get _root => _db.ref('stations/$stationId');

  // --- Relevé courant ----------------------------------------------------------

  @override
  Stream<StationSnapshot> watchSnapshot() {
    late final StreamController<StationSnapshot> controller;
    StreamSubscription<DatabaseEvent>? sub;
    Timer? clock;
    Map<Object?, Object?>? last;

    void emit() {
      final data = last;
      if (data == null || controller.isClosed) return;
      final snap = _parseLatest(data);
      if (snap != null) controller.add(snap);
    }

    controller = StreamController<StationSnapshot>(
      onListen: () {
        sub = _root.child('latest').onValue.listen(
          (event) {
            final v = event.snapshot.value;
            if (v is Map) {
              last = v;
              emit();
            }
          },
          onError: controller.addError,
        );
        // Réévalue l'état de liaison même sans nouvelle donnée
        // (en ligne → données anciennes → hors ligne).
        clock = Timer.periodic(const Duration(seconds: 15), (_) => emit());
      },
      onCancel: () async {
        clock?.cancel();
        await sub?.cancel();
      },
    );
    return controller.stream;
  }

  StationSnapshot? _parseLatest(Map<Object?, Object?> m) {
    final t = readTime(m['t']);
    if (t == null) return null;
    _lastSeen = t;
    final age = DateTime.now().difference(t);
    final link = age <= onlineWindow
        ? LinkStatus.online
        : age <= staleWindow
            ? LinkStatus.stale
            : LinkStatus.offline;
    return StationSnapshot(
      temperature: readDouble(m['temperature']) ?? double.nan,
      humidity: readDouble(m['humidity']) ?? double.nan,
      pressure: readDouble(m['pressure']) ?? double.nan,
      light: readDouble(m['light']) ?? double.nan,
      rainDetected: m['rain'] == true,
      measuredAt: t,
      link: link,
    );
  }

  @override
  Future<bool> refresh() async {
    final before = _lastSeen;
    final snap = await _root.child('latest/t').get();
    final t = readTime(snap.value);
    return t != null && (before == null || t.isAfter(before));
  }

  // --- Historique -----------------------------------------------------------------

  @override
  Future<List<HistoryPoint>> fetchHistory(
      MetricKind metric, HistoryRange range) async {
    final end = DateTime.now();
    final start = end.subtract(range.span);
    final snap = await _root
        .child('history')
        .orderByChild('t')
        .startAt(start.millisecondsSinceEpoch)
        .get();

    final raw = <HistoryPoint>[];
    for (final child in snap.children) {
      final v = child.value;
      if (v is! Map) continue;
      final t = readTime(v['t']);
      if (t == null) continue;
      final double? value = metric.isBinary
          ? (v['rain'] == true ? 1.0 : (v.containsKey('rain') ? 0.0 : null))
          : readDouble(v[metric.name]);
      if (value == null || value.isNaN) continue;
      raw.add(HistoryPoint(t, value));
    }
    raw.sort((a, b) => a.time.compareTo(b.time));
    return _bucket(raw, range, metric);
  }

  /// Regroupe les relevés bruts par tranche (15 min, 1 h ou 6 h) :
  /// moyenne pour les mesures chiffrées, présence pour la pluie.
  List<HistoryPoint> _bucket(
      List<HistoryPoint> raw, HistoryRange range, MetricKind metric) {
    if (raw.isEmpty) return const [];
    final stepMs = range.step.inMilliseconds;
    final buckets = <int, List<double>>{};
    for (final p in raw) {
      final key = p.time.millisecondsSinceEpoch ~/ stepMs;
      (buckets[key] ??= []).add(p.value);
    }
    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        HistoryPoint(
          DateTime.fromMillisecondsSinceEpoch(k * stepMs + stepMs ~/ 2),
          metric.isBinary
              ? (buckets[k]!.any((v) => v >= 0.5) ? 1 : 0)
              : buckets[k]!.reduce((a, b) => a + b) / buckets[k]!.length,
        ),
    ];
  }

  // --- Règles et alertes --------------------------------------------------------------

  @override
  Future<List<AlertRule>> fetchRules() async {
    final snap = await _root.child('rules').get();
    final rules = <AlertRule>[];
    for (final child in snap.children) {
      final r = alertRuleFromJson(child.key ?? '', child.value);
      if (r != null) rules.add(r);
    }
    // Première utilisation : on enregistre les règles par défaut.
    if (rules.isEmpty) {
      await _root.child('rules').set({
        for (final r in defaultAlertRules) r.id: r.toJson(),
      });
      return List.of(defaultAlertRules);
    }
    // Complète les règles manquantes (nouvelles versions de l'application).
    for (final d in defaultAlertRules) {
      if (!rules.any((r) => r.id == d.id)) {
        rules.add(d);
        await _root.child('rules/${d.id}').set(d.toJson());
      }
    }
    return rules;
  }

  @override
  Future<void> saveRule(AlertRule rule) =>
      _root.child('rules/${rule.id}').set(rule.toJson());

  @override
  Future<List<AlertEvent>> fetchEvents() async {
    final snap = await _root
        .child('events')
        .orderByChild('startedAt')
        .limitToLast(100)
        .get();
    final events = <AlertEvent>[];
    for (final child in snap.children) {
      final e = alertEventFromJson(child.key ?? '', child.value);
      if (e != null) events.add(e);
    }
    return events;
  }

  @override
  Future<void> saveEvent(AlertEvent event) =>
      _root.child('events/${event.id}').set(event.toJson());

  // --- Appareil -----------------------------------------------------------------------

  @override
  Future<DeviceInfo> fetchDevice() async {
    final snap = await _root.child('info').get();
    final v = snap.value;
    final m = v is Map ? v : const {};
    final extensions = m['extensions'];
    return DeviceInfo(
      stationName: (m['name'] as String?)?.trim().isNotEmpty == true
          ? (m['name'] as String).trim()
          : 'Jardin — Station 01',
      wifiRssi: readInt(m['rssi']),
      transmitEvery: Duration(seconds: readInt(m['transmitEverySec']) ?? 5),
      installedExtensions: {
        if (extensions is Map)
          for (final e in extensions.entries)
            if (e.value == true) e.key.toString(),
      },
    );
  }

  @override
  Future<void> renameStation(String name) => _root.child('info/name').set(name);

  @override
  void dispose() {}
}
