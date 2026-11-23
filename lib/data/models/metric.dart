import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';

/// Mesures que la station peut fournir.
///
/// - Température et humidité relative : DHT11 (matériel actuel).
/// - Pression : BME280 (pas encore installé).
/// - Lumière : valeur relative (%) issue d'une LDR, non calibrée en lux.
/// - Pluie : présence détectée ou non (capteur pas encore installé).
enum MetricKind { temperature, humidity, pressure, light, rain }

/// Mesures réellement disponibles avec le matériel actuel.
/// Pour réactiver un capteur une fois installé, l'ajouter ici
/// (MetricKind.pressure pour le BME280, MetricKind.rain pour la pluie).
const activeMetrics = <MetricKind>[
  MetricKind.temperature,
  MetricKind.humidity,
  MetricKind.light,
  // MetricKind.pressure, // BME280 non installé
  // MetricKind.rain,     // capteur de pluie non installé
];

extension MetricInfo on MetricKind {
  String get label => switch (this) {
        MetricKind.temperature => 'Température',
        MetricKind.humidity => 'Humidité',
        MetricKind.pressure => 'Pression',
        MetricKind.light => 'Lumière',
        MetricKind.rain => 'Pluie',
      };

  String get longLabel => switch (this) {
        MetricKind.temperature => 'Température de l’air',
        MetricKind.humidity => 'Humidité relative',
        MetricKind.pressure => 'Pression atmosphérique',
        MetricKind.light => 'Lumière relative',
        MetricKind.rain => 'Détection de pluie',
      };

  /// Nom précédé de l'article, pour les phrases (« l’humidité », « la pression »).
  String get withArticle => switch (this) {
        MetricKind.temperature => 'la température',
        MetricKind.humidity => 'l’humidité',
        MetricKind.pressure => 'la pression',
        MetricKind.light => 'la lumière',
        MetricKind.rain => 'la pluie',
      };

  String get unit => switch (this) {
        MetricKind.temperature => '°C',
        MetricKind.humidity => '%',
        MetricKind.pressure => 'hPa',
        MetricKind.light => '%',
        MetricKind.rain => '',
      };

  bool get isActive => activeMetrics.contains(this);

  String get sensor => switch (this) {
        MetricKind.temperature || MetricKind.humidity => 'DHT11',
        MetricKind.pressure => 'BME280',
        MetricKind.light => 'LDR',
        MetricKind.rain => 'Capteur de pluie',
      };

  /// Identifiant du composant dans [HardwareCatalog].
  String get sensorId => switch (this) {
        MetricKind.temperature || MetricKind.humidity => 'dht11',
        MetricKind.pressure => 'bme280',
        MetricKind.light => 'ldr',
        MetricKind.rain => 'rain',
      };

  IconData get icon => switch (this) {
        MetricKind.temperature => Icons.thermostat,
        MetricKind.humidity => Icons.water_drop_outlined,
        MetricKind.pressure => Icons.speed,
        MetricKind.light => Icons.light_mode_outlined,
        MetricKind.rain => Icons.grain,
      };

  Color get color => switch (this) {
        MetricKind.temperature => Palette.apricot,
        MetricKind.humidity => Palette.sage,
        MetricKind.pressure => Palette.lavender,
        MetricKind.light => Palette.sun,
        MetricKind.rain => Palette.rain,
      };

  Color get deep => switch (this) {
        MetricKind.temperature => Palette.apricotDeep,
        MetricKind.humidity => Palette.sageDeep,
        MetricKind.pressure => Palette.lavenderDeep,
        MetricKind.light => Palette.sunDeep,
        MetricKind.rain => Palette.rainDeep,
      };

  Color get soft => switch (this) {
        MetricKind.temperature => Palette.apricotSoft,
        MetricKind.humidity => Palette.sageSoft,
        MetricKind.pressure => Palette.lavenderSoft,
        MetricKind.light => Palette.sunSoft,
        MetricKind.rain => Palette.rainSoft,
      };

  bool get isBinary => this == MetricKind.rain;

  int get decimals => this == MetricKind.temperature ? 1 : 0;

  /// Bornes utilisées pour le réglage des seuils.
  double get minValue => switch (this) {
        MetricKind.temperature => -10,
        MetricKind.humidity => 0,
        MetricKind.pressure => 950,
        MetricKind.light => 0,
        MetricKind.rain => 0,
      };

  double get maxValue => switch (this) {
        MetricKind.temperature => 45,
        MetricKind.humidity => 100,
        MetricKind.pressure => 1050,
        MetricKind.light => 100,
        MetricKind.rain => 1,
      };

  double get step => this == MetricKind.temperature ? 0.5 : 1;

  String formatValue(double v) {
    if (isBinary) return v >= 0.5 ? 'Détectée' : 'Non détectée';
    return Fr.number(v, decimals);
  }

  /// Valeur courte pour les puces (« Aucune » plutôt que « Non détectée »).
  String shortValue(double v) {
    if (isBinary) return v >= 0.5 ? 'Détectée' : 'Aucune';
    return Fr.number(v, decimals);
  }

  String formatWithUnit(double v) {
    if (isBinary) return formatValue(v);
    return '${formatValue(v)} $unit';
  }

  /// Courte description qualitative, sans prétendre à une prévision.
  String describe(double v) {
    switch (this) {
      case MetricKind.temperature:
        if (v < 3) {
          return 'Air très froid, risque de gel au niveau de la station.';
        }
        if (v < 12) return 'Air frais autour de la station.';
        if (v < 26) return 'Air doux autour de la station.';
        if (v < 32) return 'Air chaud autour de la station.';
        return 'Forte chaleur relevée sous l’abri.';
      case MetricKind.humidity:
        if (v < 35) return 'Air sec.';
        if (v < 65) return 'Humidité modérée, air confortable.';
        if (v < 85) return 'Air humide.';
        return 'Air proche de la saturation, brume possible.';
      case MetricKind.pressure:
        if (v < 1000) return 'Pression basse, mesurée localement.';
        if (v <= 1022) {
          return 'Pression proche de la normale, mesurée localement.';
        }
        return 'Pression élevée, mesurée localement.';
      case MetricKind.light:
        if (v < 15) return 'Faible luminosité sur la LDR (valeur relative).';
        if (v < 45) return 'Lumière tamisée (valeur relative).';
        if (v < 75) return 'Bonne luminosité (valeur relative).';
        return 'Forte luminosité (valeur relative).';
      case MetricKind.rain:
        return v >= 0.5
            ? 'Des gouttes sont présentes sur le capteur.'
            : 'Aucune goutte sur le capteur.';
    }
  }
}
