import 'alerts.dart';
import 'metric.dart';

/// Conversion des modèles vers / depuis les données JSON de Firebase
/// Realtime Database. Les dates sont stockées en millisecondes depuis 1970.

double? readDouble(Object? v) => v is num ? v.toDouble() : null;

int? readInt(Object? v) => v is num ? v.toInt() : null;

DateTime? readTime(Object? v) {
  final ms = readInt(v);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

MetricKind? _metric(Object? v) {
  for (final m in MetricKind.values) {
    if (m.name == v) return m;
  }
  return null;
}

ThresholdDirection _direction(Object? v) => v == ThresholdDirection.below.name
    ? ThresholdDirection.below
    : ThresholdDirection.above;

extension AlertRuleJson on AlertRule {
  Map<String, Object?> toJson() => {
        'metric': metric.name,
        'direction': direction.name,
        'threshold': threshold,
        'enabled': enabled,
      };
}

AlertRule? alertRuleFromJson(String id, Object? json) {
  if (json is! Map) return null;
  final metric = _metric(json['metric']);
  final threshold = readDouble(json['threshold']);
  if (metric == null || threshold == null) return null;
  return AlertRule(
    id: id,
    metric: metric,
    direction: _direction(json['direction']),
    threshold: threshold,
    enabled: json['enabled'] == true,
  );
}

extension AlertEventJson on AlertEvent {
  Map<String, Object?> toJson() => {
        'ruleId': ruleId,
        'metric': metric.name,
        'direction': direction.name,
        'threshold': threshold,
        'value': value,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
        'acknowledged': acknowledged,
      };
}

AlertEvent? alertEventFromJson(String id, Object? json) {
  if (json is! Map) return null;
  final metric = _metric(json['metric']);
  final startedAt = readTime(json['startedAt']);
  if (metric == null || startedAt == null) return null;
  return AlertEvent(
    id: id,
    ruleId: (json['ruleId'] ?? '').toString(),
    metric: metric,
    direction: _direction(json['direction']),
    threshold: readDouble(json['threshold']) ?? 0,
    value: readDouble(json['value']) ?? 0,
    startedAt: startedAt,
    resolvedAt: readTime(json['resolvedAt']),
    acknowledged: json['acknowledged'] == true,
  );
}

/// Règles proposées à la première connexion : un seuil bas et un seuil haut
/// par mesure chiffrée, plus la détection de pluie.
const defaultAlertRules = <AlertRule>[
  AlertRule(
      id: 'rule_temp_high',
      metric: MetricKind.temperature,
      direction: ThresholdDirection.above,
      threshold: 30,
      enabled: true),
  AlertRule(
      id: 'rule_temp_low',
      metric: MetricKind.temperature,
      direction: ThresholdDirection.below,
      threshold: 3,
      enabled: true),
  AlertRule(
      id: 'rule_humidity_high',
      metric: MetricKind.humidity,
      direction: ThresholdDirection.above,
      threshold: 85,
      enabled: true),
  AlertRule(
      id: 'rule_humidity_low',
      metric: MetricKind.humidity,
      direction: ThresholdDirection.below,
      threshold: 30,
      enabled: false),
  AlertRule(
      id: 'rule_pressure_low',
      metric: MetricKind.pressure,
      direction: ThresholdDirection.below,
      threshold: 1000,
      enabled: false),
  AlertRule(
      id: 'rule_pressure_high',
      metric: MetricKind.pressure,
      direction: ThresholdDirection.above,
      threshold: 1030,
      enabled: false),
  AlertRule(
      id: 'rule_light_high',
      metric: MetricKind.light,
      direction: ThresholdDirection.above,
      threshold: 70,
      enabled: false),
  AlertRule(
      id: 'rule_light_low',
      metric: MetricKind.light,
      direction: ThresholdDirection.below,
      threshold: 10,
      enabled: false),
  AlertRule(
      id: 'rule_rain',
      metric: MetricKind.rain,
      direction: ThresholdDirection.above,
      threshold: 0.5,
      enabled: true),
];
