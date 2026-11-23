import 'metric.dart';
import 'snapshot.dart';

enum ThresholdDirection { above, below }

extension ThresholdDirectionInfo on ThresholdDirection {
  String get phrase =>
      this == ThresholdDirection.above ? 'au-dessus de' : 'en dessous de';
  String get symbol => this == ThresholdDirection.above ? '>' : '<';
  String get label =>
      this == ThresholdDirection.above ? 'Au-dessus' : 'En dessous';
}

String describeThreshold(
  MetricKind metric,
  ThresholdDirection direction,
  double threshold,
) {
  if (metric.isBinary) return 'Pluie détectée';
  return '${metric.label} ${direction.phrase} ${metric.formatWithUnit(threshold)}';
}

/// Règle d'alerte configurable localement.
class AlertRule {
  const AlertRule({
    required this.id,
    required this.metric,
    required this.direction,
    required this.threshold,
    required this.enabled,
  });

  final String id;
  final MetricKind metric;
  final ThresholdDirection direction;
  final double threshold;
  final bool enabled;

  bool isViolatedBy(StationSnapshot s) {
    if (metric.isBinary) return s.rainDetected;
    final v = s.valueOf(metric);
    return direction == ThresholdDirection.above
        ? v > threshold
        : v < threshold;
  }

  String get title => describeThreshold(metric, direction, threshold);

  /// Forme courte : « > 30 °C ».
  String get condition => metric.isBinary
      ? 'Détectée'
      : '${direction.symbol} ${metric.formatWithUnit(threshold)}';

  String get sentence => metric.isBinary
      ? 'Prévenir dès que le capteur détecte de la pluie.'
      : 'Prévenir quand ${metric.withArticle} passe ${direction.phrase} '
          '${metric.formatWithUnit(threshold)}.';

  AlertRule copyWith({
    ThresholdDirection? direction,
    double? threshold,
    bool? enabled,
  }) =>
      AlertRule(
        id: id,
        metric: metric,
        direction: direction ?? this.direction,
        threshold: threshold ?? this.threshold,
        enabled: enabled ?? this.enabled,
      );
}

/// Franchissement d'un seuil, actif tant que la condition persiste.
class AlertEvent {
  const AlertEvent({
    required this.id,
    required this.ruleId,
    required this.metric,
    required this.direction,
    required this.threshold,
    required this.value,
    required this.startedAt,
    this.resolvedAt,
    this.acknowledged = false,
  });

  final String id;
  final String ruleId;
  final MetricKind metric;
  final ThresholdDirection direction;
  final double threshold;

  /// Valeur relevée au moment du franchissement.
  final double value;
  final DateTime startedAt;
  final DateTime? resolvedAt;

  /// L'utilisateur a pris connaissance de l'alerte active.
  final bool acknowledged;

  bool get isActive => resolvedAt == null;

  String get title => describeThreshold(metric, direction, threshold);

  AlertEvent copyWith({DateTime? resolvedAt, bool? acknowledged}) => AlertEvent(
        id: id,
        ruleId: ruleId,
        metric: metric,
        direction: direction,
        threshold: threshold,
        value: value,
        startedAt: startedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        acknowledged: acknowledged ?? this.acknowledged,
      );
}
