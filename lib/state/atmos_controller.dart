import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/alerts.dart';
import '../data/models/hardware.dart';
import '../data/models/history.dart';
import '../data/models/metric.dart';
import '../data/models/snapshot.dart';
import '../data/repositories/demo_station_repository.dart';
import '../data/repositories/station_repository.dart';

/// État applicatif partagé. Ne dépend que de [StationRepository] :
/// remplacer le repository de démonstration par une implémentation Firebase
/// ne demande aucune modification des écrans.
class AtmosController extends ChangeNotifier {
  AtmosController(this.repository, {this.signOut, this.accountEmail});

  final StationRepository repository;

  /// Déconnexion du compte (null en mode démo).
  final Future<void> Function()? signOut;

  /// Adresse du compte connecté (null en mode démo).
  final String? accountEmail;

  StreamSubscription<StationSnapshot>? _subscription;
  bool _disposed = false;

  // --- Relevé courant -------------------------------------------------------
  StationSnapshot? _snapshot;
  StationSnapshot? get snapshot => _snapshot;
  bool get isLoading => _snapshot == null;

  // --- Navigation et sélection ---------------------------------------------
  int _tab = 0;
  int get tab => _tab;

  MetricKind _focus = MetricKind.temperature;
  MetricKind get focus => _focus;

  MetricKind _historyMetric = MetricKind.temperature;
  MetricKind get historyMetric => _historyMetric;

  HistoryRange _historyRange = HistoryRange.day;
  HistoryRange get historyRange => _historyRange;

  // --- Station --------------------------------------------------------------
  String _stationName = 'Jardin — Station 01';
  String get stationName => _stationName;

  DeviceInfo? _device;
  DeviceInfo? get device => _device;

  // --- Alertes --------------------------------------------------------------
  List<AlertRule> _rules = const [];

  /// Règles des capteurs installés (les autres restent enregistrées).
  List<AlertRule> get rules => _rules.where((r) => r.metric.isActive).toList();

  List<AlertEvent> _events = const [];

  /// Alertes actives en premier, puis les plus récentes.
  List<AlertEvent> get events {
    final list = List.of(_events);
    list.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.startedAt.compareTo(a.startedAt);
    });
    return list;
  }

  int get activeAlertCount => _events.where((e) => e.isActive).length;
  int get unseenAlertCount =>
      _events.where((e) => e.isActive && !e.acknowledged).length;
  int get enabledRuleCount =>
      _rules.where((r) => r.enabled && r.metric.isActive).length;

  // --- Historique -----------------------------------------------------------
  final Map<(MetricKind, HistoryRange), List<HistoryPoint>> _history = {};
  final Set<(MetricKind, HistoryRange)> _pendingHistory = {};
  int _historyGeneration = 0;

  // --- Démo -----------------------------------------------------------------
  DemoStationRepository? get demo {
    final r = repository;
    return r is DemoStationRepository ? r : null;
  }

  bool get isDemo => demo != null;
  DemoScenario? get scenario => demo?.scenario;

  // ==========================================================================

  Future<void> start() async {
    _listen();
    final rules = await repository.fetchRules();
    final events = await repository.fetchEvents();
    final device = await repository.fetchDevice();
    if (_disposed) return;
    _rules = rules;
    _events = events;
    _device = device;
    _stationName = device.stationName;
    _evaluateRules();
    _notify();
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = repository.watchSnapshot().listen(_onSnapshot);
  }

  void _onSnapshot(StationSnapshot snapshot) {
    _snapshot = snapshot;
    _evaluateRules();
    _notify();
  }

  void setTab(int index) {
    if (index == _tab) return;
    _tab = index;
    _notify();
  }

  void selectFocus(MetricKind metric) {
    if (metric == _focus) return;
    _focus = metric;
    _notify();
  }

  void openHistory(MetricKind metric) {
    _historyMetric = metric;
    _tab = 1;
    _notify();
  }

  void openAlerts() => setTab(2);

  void setHistoryMetric(MetricKind metric) {
    if (metric == _historyMetric) return;
    _historyMetric = metric;
    _notify();
  }

  void setHistoryRange(HistoryRange range) {
    if (range == _historyRange) return;
    _historyRange = range;
    _notify();
  }

  /// Renvoie la série en cache, ou `null` pendant son chargement.
  /// Peut être appelée pendant un `build` : la notification est asynchrone.
  List<HistoryPoint>? historyFor(MetricKind metric, HistoryRange range) {
    final key = (metric, range);
    final cached = _history[key];
    if (cached == null && _snapshot != null) _loadHistory(key);
    return cached;
  }

  Future<void> _loadHistory((MetricKind, HistoryRange) key) async {
    if (_pendingHistory.contains(key)) return;
    _pendingHistory.add(key);
    final generation = _historyGeneration;
    try {
      final points = await repository.fetchHistory(key.$1, key.$2);
      if (_disposed || generation != _historyGeneration) return;
      _history[key] = points;
    } finally {
      if (generation == _historyGeneration) _pendingHistory.remove(key);
    }
    _notify();
  }

  void _invalidateHistory() {
    _historyGeneration++;
    _history.clear();
    _pendingHistory.clear();
  }

  Future<bool> refresh() => repository.refresh();

  Future<void> rename(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    _stationName = value;
    _device = _device?.copyWith(stationName: value);
    _notify();
    await repository.renameStation(value);
  }

  // --- Règles d'alerte ------------------------------------------------------

  Future<void> updateRule(AlertRule rule) async {
    _rules = [
      for (final r in _rules) r.id == rule.id ? rule : r,
    ];
    _evaluateRules();
    _notify();
    await repository.saveRule(rule);
  }

  void acknowledge(String eventId) {
    _events = [
      for (final e in _events)
        e.id == eventId ? e.copyWith(acknowledged: true) : e,
    ];
    final updated = _events.firstWhere((e) => e.id == eventId);
    repository.saveEvent(updated);
    _notify();
  }

  /// Évaluation locale des seuils sur le dernier relevé reçu.
  /// Suspendue lorsque les données ne sont plus à jour.
  void _evaluateRules() {
    final s = _snapshot;
    if (s == null || !s.isLive || _rules.isEmpty) return;
    final now = s.measuredAt;
    final events = List.of(_events);
    for (final rule in _rules) {
      if (!rule.metric.isActive) continue;
      final active =
          events.where((e) => e.ruleId == rule.id && e.isActive).toList();
      final violated = rule.enabled && rule.isViolatedBy(s);
      if (violated && active.isEmpty) {
        final event = AlertEvent(
          id: 'evt_${now.microsecondsSinceEpoch}_${rule.id}',
          ruleId: rule.id,
          metric: rule.metric,
          direction: rule.direction,
          threshold: rule.threshold,
          value: s.valueOf(rule.metric),
          startedAt: now,
        );
        events.insert(0, event);
        repository.saveEvent(event);
      } else if (!violated && active.isNotEmpty) {
        for (final e in active) {
          final resolved = e.copyWith(resolvedAt: now);
          events[events.indexOf(e)] = resolved;
          repository.saveEvent(resolved);
        }
      }
    }
    _events = events;
  }

  // --- Démo -----------------------------------------------------------------

  void setScenario(DemoScenario scenario) {
    final d = demo;
    if (d == null) return;
    _invalidateHistory();
    d.setScenario(scenario);
    _notify();
  }

  /// Rejoue l'état de chargement initial.
  void replayLoading() {
    _snapshot = null;
    _invalidateHistory();
    _notify();
    _listen();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    repository.dispose();
    super.dispose();
  }
}
