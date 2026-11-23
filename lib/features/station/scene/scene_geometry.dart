import 'dart:math';
import 'dart:ui';

import '../../../core/format.dart';
import '../../../data/models/metric.dart';
import '../../../data/models/snapshot.dart';

/// Espace de dessin de la scène (unités « design »), mis à l'échelle
/// pour tenir dans la place disponible.
class SceneGeometry {
  SceneGeometry(Size size)
      : scale =
            min(size.width / designSize.width, size.height / designSize.height),
        origin = Offset(
          (size.width -
                  designSize.width *
                      min(size.width / designSize.width,
                          size.height / designSize.height)) /
              2,
          (size.height -
                  designSize.height *
                      min(size.width / designSize.width,
                          size.height / designSize.height)) /
              2,
        );

  static const designSize = Size(360, 300);

  final double scale;
  final Offset origin;

  Offset toScreen(Offset design) => origin + design * scale;
}

/// Centre de l'îlot dans l'espace design.
const islandCenter = Offset(180, 172);

/// Projection isométrique : x vers la droite-bas, y vers la gauche-bas,
/// z vers le haut. Une unité ≈ un pixel design.
Offset iso(double x, double y, double z) => Offset(
      islandCenter.dx + (x - y) * 0.866,
      islandCenter.dy + (x + y) * 0.5 - z,
    );

/// Flottement très léger de l'îlot (en unités design).
double floatOffset(double t) => sin(t * 2 * pi) * 2.0;

/// Points d'ancrage des capteurs et position des pastilles interactives.
abstract final class SensorAnchors {
  static Offset anchor(MetricKind m) => switch (m) {
        // BME280 sous l'abri ventilé : trois faces pour trois mesures.
        MetricKind.temperature => iso(36, -28, 88),
        MetricKind.humidity => iso(52, -42, 88),
        MetricKind.pressure => iso(52, -34, 76),
        // LDR sous son dôme, sur le boîtier.
        MetricKind.light => iso(-14, -12, 55),
        // Plaque du capteur de pluie.
        MetricKind.rain => iso(49, 28, 16),
      };

  static Offset bubble(MetricKind m) => switch (m) {
        MetricKind.temperature => const Offset(206, 38),
        MetricKind.humidity => const Offset(314, 62),
        MetricKind.pressure => const Offset(318, 124),
        MetricKind.light => const Offset(124, 66),
        MetricKind.rain => const Offset(276, 232),
      };

  /// Point au sol sous le capteur, pour le halo de sélection.
  static Offset ground(MetricKind m) => switch (m) {
        MetricKind.temperature ||
        MetricKind.humidity ||
        MetricKind.pressure =>
          iso(40, -40, 0),
        MetricKind.light => iso(-10, -8, 0),
        MetricKind.rain => iso(49, 28, 0),
      };
}

/// Ce que la scène doit refléter du dernier relevé.
class SceneConditions {
  const SceneConditions({
    required this.rain,
    required this.light,
    required this.humidity,
    required this.offline,
    required this.oledMain,
    required this.oledSub,
  });

  factory SceneConditions.from(StationSnapshot s) => SceneConditions(
        rain: s.rainDetected,
        light: s.light,
        humidity: s.humidity,
        offline: s.link == LinkStatus.offline,
        oledMain: '${Fr.number(s.temperature, 1)}°',
        oledSub: '${s.humidity.round()}% ${s.pressure.round()}',
      );

  final bool rain;
  final double light;
  final double humidity;
  final bool offline;
  final String oledMain;
  final String oledSub;

  /// 0 = lumière normale, 1 = très sombre.
  double get dimness => ((35 - light) / 30).clamp(0.0, 1.0).toDouble();

  /// 0 = air sec, 1 = brume marquée.
  double get mist => ((humidity - 78) / 16).clamp(0.0, 1.0).toDouble();

  @override
  bool operator ==(Object other) =>
      other is SceneConditions &&
      other.rain == rain &&
      other.light == light &&
      other.humidity == humidity &&
      other.offline == offline &&
      other.oledMain == oledMain &&
      other.oledSub == oledSub;

  @override
  int get hashCode =>
      Object.hash(rain, light, humidity, offline, oledMain, oledSub);
}
