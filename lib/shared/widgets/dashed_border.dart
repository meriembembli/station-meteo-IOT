import 'package:flutter/material.dart';

/// Contour pointillé arrondi, utilisé pour les modules non installés.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 22,
    this.dash = 5,
    this.gap = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(color, radius, dash, gap),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius, this.dash, this.gap);

  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.6),
      Radius.circular(radius),
    );
    final source = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}
