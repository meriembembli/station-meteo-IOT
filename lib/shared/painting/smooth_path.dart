import 'dart:ui';

/// Courbe lissée (Catmull-Rom convertie en Bézier cubiques) passant par
/// tous les points. Les tangentes sont bornées verticalement pour limiter
/// les dépassements.
Path smoothPath(List<Offset> points, {double tension = 1 / 6}) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) return path;
  if (points.length == 2) {
    path.lineTo(points[1].dx, points[1].dy);
    return path;
  }
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = i == 0 ? points[i] : points[i - 1];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : p2;
    var c1 = p1 + (p2 - p0) * tension;
    var c2 = p2 - (p3 - p1) * tension;
    final lo = p1.dy < p2.dy ? p1.dy : p2.dy;
    final hi = p1.dy < p2.dy ? p2.dy : p1.dy;
    c1 = Offset(c1.dx, c1.dy.clamp(lo, hi).toDouble());
    c2 = Offset(c2.dx, c2.dy.clamp(lo, hi).toDouble());
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}
