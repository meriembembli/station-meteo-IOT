import 'package:flutter/material.dart';

import 'metric.dart';

/// Description statique d'un composant matériel du prototype.
class HardwareComponent {
  const HardwareComponent({
    required this.id,
    required this.name,
    required this.role,
    required this.summary,
    required this.icon,
    required this.notes,
    this.measures = const [],
    this.optional = false,
  });

  final String id;
  final String name;
  final String role;
  final String summary;
  final IconData icon;
  final List<String> notes;
  final List<MetricKind> measures;

  /// Extension proposée, non installée par défaut.
  final bool optional;
}

/// Informations dynamiques sur l'appareil (fournies par le repository).
class DeviceInfo {
  const DeviceInfo({
    required this.stationName,
    required this.transmitEvery,
    this.wifiRssi,
    this.installedExtensions = const {},
  });

  final String stationName;

  /// Intensité du signal Wi-Fi en dBm, si connue.
  final int? wifiRssi;
  final Duration transmitEvery;
  final Set<String> installedExtensions;

  DeviceInfo copyWith({String? stationName}) => DeviceInfo(
        stationName: stationName ?? this.stationName,
        transmitEvery: transmitEvery,
        wifiRssi: wifiRssi,
        installedExtensions: installedExtensions,
      );
}

/// Composants du prototype, d'après le dossier du projet.
abstract final class HardwareCatalog {
  static const esp32 = HardwareComponent(
    id: 'esp32',
    name: 'ESP32',
    role: 'Microcontrôleur et Wi-Fi',
    summary:
        'Lit les capteurs, traite les valeurs, les affiche sur l’écran LCD '
        'et les transmet par Wi-Fi.',
    icon: Icons.developer_board,
    notes: [
      'Cœur de la station : lecture des capteurs et traitement des données.',
      'Transmet les mesures horodatées vers Firebase Realtime Database toutes les 5 s.',
      'En mode démo, l’état affiché ici est simulé.',
    ],
  );

  static const dht11 = HardwareComponent(
    id: 'dht11',
    name: 'DHT11',
    role: 'Température · humidité',
    summary: 'Capteur numérique de température et d’humidité relative, '
        'relié à la broche GPIO4 de l’ESP32.',
    icon: Icons.thermostat,
    measures: [MetricKind.temperature, MetricKind.humidity],
    notes: [
      'Température en °C (précision d’environ ±2 °C), humidité relative en % (environ ±5 %).',
      'Une lecture au maximum toutes les 2 secondes ; la station lit toutes les 5 s.',
      'Ne mesure pas la pression : elle reviendra avec le BME280.',
    ],
  );

  static const lcd = HardwareComponent(
    id: 'lcd',
    name: 'Écran LCD 16×2 I2C',
    role: 'Affichage local',
    summary:
        'Affiche la température, l’humidité, la lumière et l’état de connexion '
        'directement sur la station.',
    icon: Icons.desktop_windows_outlined,
    notes: [
      'Module I2C (PCF8574), adresse 0x27 ou 0x3F détectée automatiquement.',
      'Si l’écran s’allume sans texte lisible : régler le potentiomètre de contraste au dos.',
    ],
  );

  static const bme280 = HardwareComponent(
    id: 'bme280',
    name: 'BME280',
    role: 'Extension · pression atmosphérique',
    summary:
        'Capteur environnemental prévu pour mesurer la pression (non installé).',
    icon: Icons.speed,
    optional: true,
    notes: [
      'Module optionnel, pas encore installé : la pression n’est pas affichée.',
      'Une fois branché sur le bus I2C (avec le LCD), il ajoutera la pression en hPa.',
    ],
  );

  static const ldr = HardwareComponent(
    id: 'ldr',
    name: 'LDR',
    role: 'Lumière relative',
    summary: 'Photorésistance montée en pont diviseur, lue par une entrée '
        'analogique (ADC) de l’ESP32.',
    icon: Icons.light_mode_outlined,
    measures: [MetricKind.light],
    notes: [
      'Valeur relative de 0 à 100 %, ce n’est pas une mesure en lux.',
      'Une conversion en lux nécessiterait une calibration avec un luxmètre de référence.',
    ],
  );

  static const rain = HardwareComponent(
    id: 'rain',
    name: 'Capteur de pluie',
    role: 'Détection de présence',
    summary: 'Plaque de détection exposée aux gouttes (non installée).',
    icon: Icons.grain,
    optional: true,
    notes: [
      'Module optionnel, pas encore installé.',
      'Indiquera si de la pluie est détectée ou non.',
      'Ne mesure pas une quantité de pluie : aucune valeur en mm/h n’est affichée.',
    ],
  );

  static const oled = HardwareComponent(
    id: 'oled',
    name: 'Écran OLED SSD1306',
    role: 'Affichage local',
    summary: 'Affiche les dernières mesures directement sur la station.',
    icon: Icons.desktop_windows_outlined,
    notes: [
      'Permet un suivi local, même sans téléphone.',
      'Relié au bus I2C partagé avec le BME280.',
    ],
  );

  static const soil = HardwareComponent(
    id: 'soil',
    name: 'Humidité du sol',
    role: 'Extension · sonde capacitive',
    summary: 'Sonde capacitive externe plantée dans le sol.',
    icon: Icons.grass,
    optional: true,
    notes: [
      'Module optionnel, non installé sur ce prototype.',
      'Nécessite une calibration (sol sec puis sol saturé) avant d’afficher une valeur fiable.',
    ],
  );

  static const water = HardwareComponent(
    id: 'water',
    name: 'Niveau d’eau',
    role: 'Extension · HC-SR04',
    summary: 'Capteur à ultrasons placé au-dessus d’un réservoir.',
    icon: Icons.waves,
    optional: true,
    notes: [
      'Module optionnel, non installé sur ce prototype.',
      'Le niveau est calculé à partir de la distance mesurée et de la hauteur connue du réservoir.',
    ],
  );

  static const installed = [esp32, dht11, ldr, lcd];
  static const extensions = [bme280, rain, soil, water];

  static HardwareComponent byId(String id) =>
      [...installed, ...extensions].firstWhere((c) => c.id == id);
}
