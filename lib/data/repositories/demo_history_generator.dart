import 'dart:math';

import '../models/history.dart';
import '../models/metric.dart';
import '../models/snapshot.dart';

/// Génère des séries simulées cohérentes : cycle jour/nuit, dérive lente,
/// bruit léger, et raccord progressif avec la dernière mesure affichée.
List<HistoryPoint> generateDemoHistory(
  MetricKind metric,
  HistoryRange range,
  StationSnapshot current,
) {
  final end = current.measuredAt;
  final start = end.subtract(range.span);
  final stepMinutes = range.step.inMinutes;
  final count = range.span.inMinutes ~/ stepMinutes + 1;
  final rnd = Random(metric.index * 31 + range.index * 7 + 11);

  double noise(double amplitude) => (rnd.nextDouble() - 0.5) * 2 * amplitude;

  final raw = <double>[];
  final times = <DateTime>[];
  for (var i = 0; i < count; i++) {
    final t = start.add(Duration(minutes: stepMinutes * i));
    times.add(t);
    final hour = t.hour + t.minute / 60;
    final days = t.difference(start).inMinutes / 1440;
    // Maximum vers 15 h, minimum vers 3 h.
    final diurnal = sin((hour - 9) / 24 * 2 * pi);
    final weather = sin(days * 0.9 + 1.3) * 0.7 + sin(days * 2.3) * 0.3;
    final daylight =
        (hour >= 6 && hour <= 20) ? sin((hour - 6) / 14 * pi) : 0.0;

    final double value = switch (metric) {
      MetricKind.temperature =>
        19 + 5.5 * diurnal + 2.4 * weather + noise(0.35),
      MetricKind.humidity => (64 - 14 * diurnal - 6 * weather + noise(1.8))
          .clamp(22.0, 99.0)
          .toDouble(),
      MetricKind.pressure =>
        1013 + 6 * sin(days * 0.55 + 1) + 2 * weather + noise(0.25),
      MetricKind.light => (92 * daylight * (0.78 + 0.22 * weather) +
              (daylight > 0 ? noise(3) : noise(0.6)))
          .clamp(0.0, 100.0)
          .toDouble(),
      MetricKind.rain =>
        (sin(days * 2.7 + 0.6) + 0.5 * sin(days * 7.1 + 2)) > 1.05 ? 1.0 : 0.0,
    };
    raw.add(value);
  }

  // Raccord avec la valeur actuelle sur les derniers points uniquement,
  // pour conserver la forme générale de la série.
  final target = current.valueOf(metric);
  if (metric.isBinary) {
    raw[raw.length - 1] = target;
    if (target >= 0.5 && raw.length > 3) {
      raw[raw.length - 2] = 1;
      raw[raw.length - 3] = 1;
    }
  } else {
    final delta = target - raw.last;
    final blend = max(4, (count * 0.15).round());
    for (var k = 0; k < blend && k < raw.length; k++) {
      final index = raw.length - blend + k;
      if (index < 0) continue;
      final f = (k + 1) / blend;
      final eased = f * f * (3 - 2 * f);
      raw[index] = raw[index] + delta * eased;
    }
    for (var i = 0; i < raw.length; i++) {
      raw[i] = raw[i].clamp(metric.minValue, metric.maxValue).toDouble();
    }
  }

  return [
    for (var i = 0; i < count; i++) HistoryPoint(times[i], raw[i]),
  ];
}
