/// Mise en forme française sans dépendance externe (virgule décimale,
/// jours et mois abrégés, durées relatives).
abstract final class Fr {
  static const _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  static const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

  static String number(double value, int decimals) => value.isFinite
      ? value.toStringAsFixed(decimals).replaceAll('.', ',')
      : '—';

  static String two(int n) => n.toString().padLeft(2, '0');

  static String time(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String weekday(DateTime d) => _days[d.weekday - 1];

  static String shortDate(DateTime d) => '${two(d.day)}/${two(d.month)}';

  static String dateTime(DateTime d) => '${dayMonth(d)} à ${time(d)}';

  static String relativeDay(DateTime d, DateTime now) {
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Aujourd’hui';
    if (diff == 1) return 'Hier';
    return '${weekday(d)} ${dayMonth(d)}';
  }

  static String ago(DateTime from, DateTime now) {
    final seconds = now.difference(from).inSeconds;
    if (seconds < 5) return 'à l’instant';
    if (seconds < 60) return 'il y a $seconds s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return 'il y a $minutes min';
    final hours = minutes ~/ 60;
    if (hours < 24) {
      final rest = minutes % 60;
      return rest == 0 ? 'il y a $hours h' : 'il y a $hours h ${two(rest)}';
    }
    return 'le ${dateTime(from)}';
  }
}
