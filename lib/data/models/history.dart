enum HistoryRange { day, week, month }

extension HistoryRangeInfo on HistoryRange {
  String get label => switch (this) {
        HistoryRange.day => '24 h',
        HistoryRange.week => '7 j',
        HistoryRange.month => '30 j',
      };

  String get longLabel => switch (this) {
        HistoryRange.day => 'dernières 24 heures',
        HistoryRange.week => '7 derniers jours',
        HistoryRange.month => '30 derniers jours',
      };

  Duration get span => switch (this) {
        HistoryRange.day => const Duration(hours: 24),
        HistoryRange.week => const Duration(days: 7),
        HistoryRange.month => const Duration(days: 30),
      };

  Duration get step => switch (this) {
        HistoryRange.day => const Duration(minutes: 15),
        HistoryRange.week => const Duration(hours: 1),
        HistoryRange.month => const Duration(hours: 6),
      };

  String get stepLabel => switch (this) {
        HistoryRange.day => 'Un relevé toutes les 15 min',
        HistoryRange.week => 'Moyennes horaires',
        HistoryRange.month => 'Moyennes sur 6 h',
      };
}

class HistoryPoint {
  const HistoryPoint(this.time, this.value);

  final DateTime time;
  final double value;
}

/// Minimum, moyenne et maximum d'une série continue.
class HistoryStats {
  const HistoryStats({
    required this.min,
    required this.mean,
    required this.max,
    required this.minAt,
    required this.maxAt,
  });

  final double min;
  final double mean;
  final double max;
  final DateTime minAt;
  final DateTime maxAt;

  static HistoryStats? of(List<HistoryPoint> points) {
    if (points.isEmpty) return null;
    var min = points.first;
    var max = points.first;
    var sum = 0.0;
    for (final p in points) {
      if (p.value < min.value) min = p;
      if (p.value > max.value) max = p;
      sum += p.value;
    }
    return HistoryStats(
      min: min.value,
      mean: sum / points.length,
      max: max.value,
      minAt: min.time,
      maxAt: max.time,
    );
  }
}

/// Statistiques adaptées à une mesure de présence (pluie).
class PresenceStats {
  const PresenceStats({
    required this.share,
    required this.episodes,
    required this.lastDetection,
  });

  /// Part du temps avec pluie détectée (0–1).
  final double share;
  final int episodes;
  final DateTime? lastDetection;

  static PresenceStats? of(List<HistoryPoint> points) {
    if (points.isEmpty) return null;
    var on = 0;
    var episodes = 0;
    var previous = false;
    DateTime? last;
    for (final p in points) {
      final detected = p.value >= 0.5;
      if (detected) {
        on++;
        last = p.time;
        if (!previous) episodes++;
      }
      previous = detected;
    }
    return PresenceStats(
      share: on / points.length,
      episodes: episodes,
      lastDetection: last,
    );
  }
}
