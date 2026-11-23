import 'package:flutter/material.dart';

import 'scene_geometry.dart';

/// Ciel de la scène : clair et lumineux de jour, gris-bleu sous la pluie,
/// rosé au crépuscule quand la lumière baisse. Halo solaire, nuages diffus
/// et horizon brumeux donnent de la profondeur à l'îlot.
class BackdropPainter extends CustomPainter {
  BackdropPainter({required this.conditions, required this.parallax});

  final SceneConditions conditions;
  final Offset parallax;

  // Ciels de référence (haut, bas).
  static const _dayTop = Color(0xFF6FA7EC);
  static const _dayBottom = Color(0xFFD9EAFB);
  static const _rainTop = Color(0xFF7F95AE);
  static const _rainBottom = Color(0xFFC9D4DF);
  static const _duskTop = Color(0xFF46558C);
  static const _duskBottom = Color(0xFFF0B79A);
  static const _offTop = Color(0xFF8592A1);
  static const _offBottom = Color(0xFFCDD3DA);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final dim = conditions.dimness;
    final wet = conditions.rain ? 1.0 : 0.0;

    var top = Color.lerp(_dayTop, _rainTop, wet)!;
    var bottom = Color.lerp(_dayBottom, _rainBottom, wet)!;
    top = Color.lerp(top, _duskTop, dim)!;
    bottom = Color.lerp(bottom, _duskBottom, dim * 0.85)!;
    if (conditions.offline) {
      top = Color.lerp(top, _offTop, 0.7)!;
      bottom = Color.lerp(bottom, _offBottom, 0.7)!;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );

    final g = SceneGeometry(size);
    canvas.save();
    canvas.translate(g.origin.dx, g.origin.dy);
    canvas.scale(g.scale);

    // Halo solaire (chaud au crépuscule, voilé sous la pluie).
    final sunColor = Color.lerp(Colors.white, const Color(0xFFFFD7B0), dim)!;
    final sunStrength = (0.75 - 0.45 * wet) * (1 - 0.2 * dim);
    final halo = Offset(286 - parallax.dx * 10, 52);
    canvas.drawCircle(
      halo,
      120,
      Paint()
        ..shader = RadialGradient(
          colors: [
            sunColor.withAlpha((255 * sunStrength).round()),
            sunColor.withAlpha(0),
          ],
        ).createShader(Rect.fromCircle(center: halo, radius: 120)),
    );

    // Nuages diffus, plus présents sous la pluie.
    final cloud = Paint()
      ..color = Colors.white.withAlpha((255 * (0.22 + 0.2 * wet)).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    for (final (c, w, h) in const [
      (Offset(70, 46), 120.0, 26.0),
      (Offset(118, 30), 90.0, 20.0),
      (Offset(250, 96), 130.0, 22.0),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(-parallax.dx * 5, 0),
          width: w,
          height: h,
        ),
        cloud,
      );
    }

    // Horizon brumeux derrière l'îlot.
    final horizon = Rect.fromCenter(
      center: Offset(180 - parallax.dx * 3, 236),
      width: 520,
      height: 150,
    );
    canvas.drawOval(
      horizon,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withAlpha(90), Colors.white.withAlpha(0)],
        ).createShader(horizon),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BackdropPainter old) =>
      old.conditions != conditions || old.parallax != parallax;
}
