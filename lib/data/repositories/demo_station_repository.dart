import 'dart:async';
import 'dart:math';

import '../models/alerts.dart';
import '../models/hardware.dart';
import '../models/history.dart';
import '../models/metric.dart';
import '../models/snapshot.dart';
import 'demo_history_generator.dart';
import 'station_repository.dart';

/// Situations prévisualisables depuis la puce « Mode démo ».
enum DemoScenario { normal, rain, dim, humid, stale, offline, emptyHistory }

extension DemoScenarioInfo on DemoScenario {
  String get label => switch (this) {
        DemoScenario.normal => 'Conditions normales',
        DemoScenario.rain => 'Pluie détectée',
        DemoScenario.dim => 'Lumière faible',
        DemoScenario.humid => 'Humidité élevée',
        DemoScenario.stale => 'Données anciennes',
        DemoScenario.offline => 'Station déconnectée',
        DemoScenario.emptyHistory => 'Historique vide',
      };

  String get description => switch (this) {
        DemoScenario.normal =>
          '24,6 °C · 62 % · 1013 hPa · lumière 74 % · pas de pluie',
        DemoScenario.rain => 'Gouttes sur le capteur, sol humide',
        DemoScenario.dim => 'Fin de journée, ambiance assombrie',
        DemoScenario.humid => 'Air saturé, brume localisée',
        DemoScenario.stale => 'Dernière réception il y a 47 min',
        DemoScenario.offline =>
          'Dernières mesures conservées avec leur horodatage',
        DemoScenario.emptyHistory => 'Aucun relevé enregistré pour le moment',
      };
}

/// Implémentation de démonstration, entièrement locale.
class DemoStationRepository implements StationRepository {
  DemoStationRepository({
    this.tick = const Duration(seconds: 5),
    this.initialDelay = const Duration(milliseconds: 1100),
    this.networkDelay = const Duration(milliseconds: 380),
    int seed = 7,
  }) : _random = Random(seed) {
    _current = _baseFor(DemoScenario.normal, DateTime.now());
    _events = _seedEvents(DateTime.now());
  }

  /// Intervalle entre deux relevés simulés (`null` : pas de mise à jour).
  final Duration? tick;
  final Duration initialDelay;
  final Duration networkDelay;

  final Random _random;
  final StreamController<StationSnapshot> _updates =
      StreamController<StationSnapshot>.broadcast();
  late StationSnapshot _current;
  late List<AlertEvent> _events;
  DemoScenario _scenario = DemoScenario.normal;
  Timer? _timer;
  String _stationName = 'Jardin — Station 01';

  final List<AlertRule> _rules = [
    const AlertRule(
      id: 'rule_temp_high',
      metric: MetricKind.temperature,
      direction: ThresholdDirection.above,
      threshold: 30,
      enabled: true,
    ),
    const AlertRule(
      id: 'rule_temp_low',
      metric: MetricKind.temperature,
      direction: ThresholdDirection.below,
      threshold: 3,
      enabled: true,
    ),
    const AlertRule(
      id: 'rule_humidity_high',
      metric: MetricKind.humidity,
      direction: ThresholdDirection.above,
      threshold: 85,
      enabled: true,
    ),
    const AlertRule(
      id: 'rule_pressure_low',
      metric: MetricKind.pressure,
      direction: ThresholdDirection.below,
      threshold: 1000,
      enabled: false,
    ),
    const AlertRule(
      id: 'rule_light_high',
      metric: MetricKind.light,
      direction: ThresholdDirection.above,
      threshold: 70,
      enabled: true,
    ),
    const AlertRule(
      id: 'rule_humidity_low',
      metric: MetricKind.humidity,
      direction: ThresholdDirection.below,
      threshold: 30,
      enabled: false,
    ),
    const AlertRule(
      id: 'rule_pressure_high',
      metric: MetricKind.pressure,
      direction: ThresholdDirection.above,
      threshold: 1030,
      enabled: false,
    ),
    const AlertRule(
      id: 'rule_light_low',
      metric: MetricKind.light,
      direction: ThresholdDirection.below,
      threshold: 10,
      enabled: false,
    ),
    const AlertRule(
      id: 'rule_rain',
      metric: MetricKind.rain,
      direction: ThresholdDirection.above,
      threshold: 0.5,
      enabled: true,
    ),
  ];

  DemoScenario get scenario => _scenario;

  void setScenario(DemoScenario scenario) {
    _scenario = scenario;
    _current = _baseFor(scenario, DateTime.now());
    if (!_updates.isClosed) _updates.add(_current);
  }

  @override
  Stream<StationSnapshot> watchSnapshot() async* {
    await Future<void>.delayed(initialDelay);
    _ensureTimer();
    yield _current;
    yield* _updates.stream;
  }

  @override
  Future<bool> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_scenario == DemoScenario.offline || _scenario == DemoScenario.stale) {
      return false;
    }
    _emitJitter();
    return true;
  }

  @override
  Future<List<HistoryPoint>> fetchHistory(
    MetricKind metric,
    HistoryRange range,
  ) async {
    await Future<void>.delayed(networkDelay);
    if (_scenario == DemoScenario.emptyHistory) return const [];
    return generateDemoHistory(metric, range, _current);
  }

  @override
  Future<List<AlertRule>> fetchRules() async => List.of(_rules);

  @override
  Future<void> saveRule(AlertRule rule) async {
    final i = _rules.indexWhere((r) => r.id == rule.id);
    if (i >= 0) {
      _rules[i] = rule;
    } else {
      _rules.add(rule);
    }
  }

  @override
  Future<List<AlertEvent>> fetchEvents() async => List.of(_events);

  @override
  Future<void> saveEvent(AlertEvent event) async {
    final i = _events.indexWhere((e) => e.id == event.id);
    if (i >= 0) {
      _events[i] = event;
    } else {
      _events.insert(0, event);
    }
  }

  @override
  Future<DeviceInfo> fetchDevice() async => DeviceInfo(
        stationName: _stationName,
        wifiRssi: -61,
        transmitEvery: tick ?? const Duration(seconds: 5),
      );

  @override
  Future<void> renameStation(String name) async {
    _stationName = name;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _updates.close();
  }

  // --- Simulation -----------------------------------------------------------

  void _ensureTimer() {
    final tick = this.tick;
    if (tick == null || _timer != null || _updates.isClosed) return;
    _timer = Timer.periodic(tick, (_) {
      if (_scenario == DemoScenario.offline ||
          _scenario == DemoScenario.stale) {
        return;
      }
      _emitJitter();
    });
  }

  void _emitJitter() {
    final base = _baseFor(_scenario, DateTime.now());
    double around(double value, double amplitude) =>
        value + (_random.nextDouble() - 0.5) * 2 * amplitude;
    _current = base.copyWith(
      temperature: around(base.temperature, 0.15),
      humidity: around(base.humidity, 0.6).clamp(0.0, 100.0).toDouble(),
      pressure: around(base.pressure, 0.3),
      light: around(base.light, 1.0).clamp(0.0, 100.0).toDouble(),
    );
    if (!_updates.isClosed) _updates.add(_current);
  }

  static StationSnapshot _baseFor(DemoScenario s, DateTime now) {
    final normal = StationSnapshot(
      temperature: 24.6,
      humidity: 62,
      pressure: 1013,
      light: 74,
      rainDetected: false,
      measuredAt: now,
    );
    return switch (s) {
      DemoScenario.rain => normal.copyWith(
          temperature: 18.4,
          humidity: 91,
          pressure: 1004,
          light: 31,
          rainDetected: true,
          measuredAt: now,
        ),
      DemoScenario.dim => normal.copyWith(
          temperature: 19.2,
          humidity: 68,
          pressure: 1012,
          light: 9,
          measuredAt: now,
        ),
      DemoScenario.humid => normal.copyWith(
          temperature: 20.8,
          humidity: 94,
          pressure: 1008,
          light: 46,
          measuredAt: now,
        ),
      DemoScenario.stale => normal.copyWith(
          measuredAt: now.subtract(const Duration(minutes: 47)),
          link: LinkStatus.stale,
        ),
      DemoScenario.offline => normal.copyWith(
          measuredAt: now.subtract(const Duration(hours: 3, minutes: 12)),
          link: LinkStatus.offline,
        ),
      DemoScenario.normal || DemoScenario.emptyHistory => normal,
    };
  }

  static List<AlertEvent> _seedEvents(DateTime now) => [
        AlertEvent(
          id: 'evt_seed_humidity',
          ruleId: 'rule_humidity_high',
          metric: MetricKind.humidity,
          direction: ThresholdDirection.above,
          threshold: 85,
          value: 89,
          startedAt: now.subtract(const Duration(hours: 9, minutes: 20)),
          resolvedAt: now.subtract(const Duration(hours: 7, minutes: 5)),
        ),
        AlertEvent(
          id: 'evt_seed_rain',
          ruleId: 'rule_rain',
          metric: MetricKind.rain,
          direction: ThresholdDirection.above,
          threshold: 0.5,
          value: 1,
          startedAt: now.subtract(const Duration(days: 1, hours: 3)),
          resolvedAt:
              now.subtract(const Duration(days: 1, hours: 1, minutes: 40)),
        ),
        AlertEvent(
          id: 'evt_seed_heat',
          ruleId: 'rule_temp_high',
          metric: MetricKind.temperature,
          direction: ThresholdDirection.above,
          threshold: 30,
          value: 31.4,
          startedAt: now.subtract(const Duration(days: 1, hours: 22)),
          resolvedAt:
              now.subtract(const Duration(days: 1, hours: 20, minutes: 15)),
        ),
        AlertEvent(
          id: 'evt_seed_frost',
          ruleId: 'rule_temp_low',
          metric: MetricKind.temperature,
          direction: ThresholdDirection.below,
          threshold: 3,
          value: 2.1,
          startedAt: now.subtract(const Duration(days: 4, hours: 2)),
          resolvedAt:
              now.subtract(const Duration(days: 3, hours: 23, minutes: 30)),
        ),
      ];
}
