import 'metric.dart';

/// État de la liaison avec la station.
enum LinkStatus { online, stale, offline }

extension LinkStatusInfo on LinkStatus {
  String get label => switch (this) {
        LinkStatus.online => 'En ligne',
        LinkStatus.stale => 'Données anciennes',
        LinkStatus.offline => 'Hors ligne',
      };
}

/// Dernier relevé complet envoyé par la station.
///
/// Correspond à un nœud « dernières mesures » dans Firebase : il suffira
/// de construire cet objet depuis le document reçu.
class StationSnapshot {
  const StationSnapshot({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.light,
    required this.rainDetected,
    required this.measuredAt,
    this.link = LinkStatus.online,
  });

  /// °C — BME280.
  final double temperature;

  /// % d'humidité relative — BME280.
  final double humidity;

  /// hPa — BME280 (pression locale).
  final double pressure;

  /// % relatif — LDR, non calibré en lux.
  final double light;

  /// Présence de pluie détectée.
  final bool rainDetected;

  /// Horodatage de la mesure.
  final DateTime measuredAt;

  final LinkStatus link;

  bool get isLive => link == LinkStatus.online;

  double valueOf(MetricKind kind) => switch (kind) {
        MetricKind.temperature => temperature,
        MetricKind.humidity => humidity,
        MetricKind.pressure => pressure,
        MetricKind.light => light,
        MetricKind.rain => rainDetected ? 1 : 0,
      };

  StationSnapshot copyWith({
    double? temperature,
    double? humidity,
    double? pressure,
    double? light,
    bool? rainDetected,
    DateTime? measuredAt,
    LinkStatus? link,
  }) =>
      StationSnapshot(
        temperature: temperature ?? this.temperature,
        humidity: humidity ?? this.humidity,
        pressure: pressure ?? this.pressure,
        light: light ?? this.light,
        rainDetected: rainDetected ?? this.rainDetected,
        measuredAt: measuredAt ?? this.measuredAt,
        link: link ?? this.link,
      );
}
