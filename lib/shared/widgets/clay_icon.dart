import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/metric.dart';

/// Icônes 3D « pâte mate » dessinées en code : volumes arrondis, dégradés
/// doux, reflets et ombre portée. Aucune image externe n'est nécessaire.
enum ClayGlyph {
  temperature,
  humidity,
  pressure,
  light,
  rain,
  station,
  history,
  alerts,
  chip,
  screen,
  soil,
  water,
}

extension MetricClayGlyph on MetricKind {
  ClayGlyph get glyph => switch (this) {
        MetricKind.temperature => ClayGlyph.temperature,
        MetricKind.humidity => ClayGlyph.humidity,
        MetricKind.pressure => ClayGlyph.pressure,
        MetricKind.light => ClayGlyph.light,
        MetricKind.rain => ClayGlyph.rain,
      };
}

/// Icône 3D associée à un composant du catalogue matériel.
ClayGlyph glyphForComponent(String id) => switch (id) {
      'esp32' => ClayGlyph.chip,
      'dht11' => ClayGlyph.temperature,
      'bme280' => ClayGlyph.pressure,
      'lcd' => ClayGlyph.screen,
      'ldr' => ClayGlyph.light,
      'rain' => ClayGlyph.rain,
      'oled' => ClayGlyph.screen,
      'soil' => ClayGlyph.soil,
      'water' => ClayGlyph.water,
      _ => ClayGlyph.chip,
    };

class ClayIcon extends StatelessWidget {
  const ClayIcon(this.glyph, {super.key, this.size = 28, this.muted = false});

  final ClayGlyph glyph;
  final double size;

  /// Version atténuée (module non installé, règle désactivée…).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    Widget icon = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ClayPainter(glyph)),
    );
    if (muted) {
      icon = Opacity(
        opacity: 0.5,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.33, 0.33, 0.33, 0, 20, //
            0.33, 0.33, 0.33, 0, 24, //
            0.33, 0.33, 0.33, 0, 22, //
            0, 0, 0, 1, 0,
          ]),
          child: icon,
        ),
      );
    }
    return ExcludeSemantics(child: RepaintBoundary(child: icon));
  }
}

// ---------------------------------------------------------------------------

const _inkShade = Color(0xFF0E241C);

Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _d(Color c, double t) => Color.lerp(c, _inkShade, t)!;
Color _a(Color c, int alpha) => c.withAlpha(alpha);

class _ClayPainter extends CustomPainter {
  _ClayPainter(this.glyph);

  final ClayGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (glyph) {
      case ClayGlyph.temperature:
        _temperature(canvas);
      case ClayGlyph.humidity:
        _humidity(canvas);
      case ClayGlyph.pressure:
        _pressure(canvas);
      case ClayGlyph.light:
        _light(canvas);
      case ClayGlyph.rain:
        _rain(canvas);
      case ClayGlyph.station:
        _station(canvas);
      case ClayGlyph.history:
        _history(canvas);
      case ClayGlyph.alerts:
        _alerts(canvas);
      case ClayGlyph.chip:
        _chip(canvas);
      case ClayGlyph.screen:
        _screen(canvas);
      case ClayGlyph.soil:
        _soil(canvas);
      case ClayGlyph.water:
        _water(canvas);
    }
    canvas.restore();
  }

  // --- Primitives ------------------------------------------------------------

  void _shadow(Canvas c, Offset center, double w, double h) {
    c.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..color = _a(const Color(0xFF000000), 90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  Paint _sphere(Rect r, Color base) => Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      radius: 0.95,
      colors: [_l(base, 0.32), base, _d(base, 0.32)],
      stops: const [0, 0.55, 1],
    ).createShader(r);

  void _gloss(Canvas c, Offset center, double w, double h, {int alpha = 80}) {
    c.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..color = _a(Colors.white, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(0.6, w * 0.12)),
    );
  }

  void _ball(Canvas c, Offset o, double r, Color base, {bool gloss = true}) {
    c.drawCircle(o, r, _sphere(Rect.fromCircle(center: o, radius: r), base));
    if (gloss) _gloss(c, o + Offset(-r * 0.35, -r * 0.45), r * 0.6, r * 0.38);
  }

  void _capsule(Canvas c, Rect r, Color base, {bool vertical = true}) {
    final radius = vertical ? r.width / 2 : r.height / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: vertical ? Alignment.centerLeft : Alignment.topCenter,
          end: vertical ? Alignment.centerRight : Alignment.bottomCenter,
          colors: [_l(base, 0.45), base, _d(base, 0.25)],
          stops: const [0, 0.45, 1],
        ).createShader(r),
    );
    final hl = vertical
        ? Rect.fromLTWH(r.left + r.width * 0.2, r.top + r.width * 0.35,
            r.width * 0.16, r.height - r.width * 0.7)
        : Rect.fromLTWH(r.left + r.height * 0.35, r.top + r.height * 0.18,
            r.width - r.height * 0.7, r.height * 0.16);
    if (hl.width > 0 && hl.height > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(hl, const Radius.circular(50)),
        Paint()..color = _a(Colors.white, 60),
      );
    }
  }

  void _slab(Canvas c, Rect r, double depth, double radius, Color base) {
    c.drawRRect(
      RRect.fromRectAndRadius(
          r.shift(Offset(0, depth)), Radius.circular(radius)),
      Paint()..color = _d(base, 0.3),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_l(base, 0.4), base, _d(base, 0.12)],
        ).createShader(r),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(1.2), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _a(Colors.white, 40),
    );
  }

  Path _dropPath(double x, double y, double s) => Path()
    ..moveTo(x, y - 1.6 * s)
    ..cubicTo(x + 0.3 * s, y - 0.9 * s, x + s, y - 0.4 * s, x + s, y + 0.1 * s)
    ..arcToPoint(Offset(x - s, y + 0.1 * s), radius: Radius.circular(s))
    ..cubicTo(x - s, y - 0.4 * s, x - 0.3 * s, y - 0.9 * s, x, y - 1.6 * s)
    ..close();

  void _fillDrop(Canvas c, Path p, Color base) {
    c.drawPath(
      p,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.1),
          radius: 0.9,
          colors: [_l(base, 0.6), base, _d(base, 0.25)],
          stops: const [0, 0.55, 1],
        ).createShader(p.getBounds()),
    );
  }

  // --- Glyphes ----------------------------------------------------------------

  void _temperature(Canvas c) {
    _shadow(c, const Offset(52, 94), 44, 9);
    _capsule(c, const Rect.fromLTWH(38, 6, 24, 70), const Color(0xFFD5DAD6));
    const mercury = Color(0xFFE29A68);
    _capsule(c, const Rect.fromLTWH(45.5, 28, 9, 50), mercury);
    _ball(c, const Offset(50, 76), 17, mercury);
    final tick = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _a(_inkShade, 70);
    for (final y in const [18.0, 28.0, 38.0, 48.0]) {
      c.drawLine(Offset(56.5, y), Offset(59.5, y), tick);
    }
  }

  void _humidity(Canvas c) {
    _shadow(c, const Offset(50, 95), 46, 8);
    final p = Path()
      ..moveTo(50, 6)
      ..cubicTo(56, 22, 80, 42, 80, 60)
      ..arcToPoint(const Offset(20, 60), radius: const Radius.circular(30))
      ..cubicTo(20, 42, 44, 22, 50, 6)
      ..close();
    _fillDrop(c, p, const Color(0xFF6CBFBA));
    _gloss(c, const Offset(36, 58), 9, 20, alpha: 170);
    _gloss(c, const Offset(42, 40), 5, 5, alpha: 190);
  }

  void _pressure(Canvas c) {
    _shadow(c, const Offset(50, 94), 64, 9);
    const center = Offset(50, 50);
    const base = Color(0xFFDCE5EF);
    c.drawCircle(
        center + const Offset(0, 5), 38, Paint()..color = _d(base, 0.35));
    c.drawCircle(
        center, 38, _sphere(Rect.fromCircle(center: center, radius: 38), base));
    final face = Rect.fromCircle(center: center, radius: 28);
    c.drawCircle(
      center,
      28,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Colors.white, Color(0xFFE9EEE8)],
        ).createShader(face),
    );
    c.drawCircle(
      center,
      28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _a(_inkShade, 35),
    );
    const start = 135 * pi / 180;
    c.drawArc(
      Rect.fromCircle(center: center, radius: 22),
      start + 200 * pi / 180,
      70 * pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFA9A2E6),
    );
    final tick = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = _a(_inkShade, 110);
    for (var i = 0; i < 7; i++) {
      final a = start + i * 45 * pi / 180;
      final dir = Offset(cos(a), sin(a));
      c.drawLine(center + dir * 15, center + dir * 18.5, tick);
    }
    const needleAngle = start + 270 * 0.62 * pi / 180;
    final dir = Offset(cos(needleAngle), sin(needleAngle));
    final normal = Offset(-dir.dy, dir.dx);
    final needle = Path()
      ..moveTo(center.dx + dir.dx * 21, center.dy + dir.dy * 21)
      ..lineTo(center.dx + normal.dx * 3.2, center.dy + normal.dy * 3.2)
      ..lineTo(center.dx - normal.dx * 3.2, center.dy - normal.dy * 3.2)
      ..close();
    c.drawPath(needle, Paint()..color = const Color(0xFFA9A2E6));
    _ball(c, center, 5.5, const Color(0xFF0B2A20));
    _gloss(c, const Offset(36, 26), 20, 8, alpha: 120);
  }

  void _light(Canvas c) {
    _shadow(c, const Offset(50, 94), 46, 8);
    const center = Offset(50, 47);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      _ball(c, center + Offset(cos(a), sin(a)) * 35, 6, const Color(0xFFC9B47A),
          gloss: false);
    }
    _ball(c, center, 24, const Color(0xFFDCC072));
  }

  void _rain(Canvas c) {
    _shadow(c, const Offset(50, 95), 56, 7);
    const dropColor = Color(0xFF8AA5E6);
    for (final o in const [Offset(32, 82), Offset(52, 88), Offset(70, 82)]) {
      _fillDrop(c, _dropPath(o.dx, o.dy, 6), dropColor);
    }
    const cloud = Color(0xFFD6DDE3);
    _capsule(c, const Rect.fromLTWH(16, 44, 70, 26), cloud, vertical: false);
    _ball(c, const Offset(60, 38), 21, cloud);
    _ball(c, const Offset(34, 48), 16, cloud);
    _ball(c, const Offset(74, 54), 13, cloud, gloss: false);
  }

  void _station(Canvas c) {
    _shadow(c, const Offset(50, 92), 76, 12);
    // Îlot.
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 72), width: 82, height: 34),
      Paint()..color = const Color(0xFF7A5B47),
    );
    final top =
        Rect.fromCenter(center: const Offset(50, 65), width: 82, height: 34);
    c.drawOval(
      top,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.5),
          colors: [Color(0xFFA3CFB8), Color(0xFF5A8E77)],
        ).createShader(top),
    );
    // Boîtier isométrique.
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);
    c.drawPath(
        poly(const [
          Offset(26, 38),
          Offset(42, 46),
          Offset(42, 68),
          Offset(26, 60)
        ]),
        Paint()..color = const Color(0xFFEDEAE2));
    c.drawPath(
        poly(const [
          Offset(42, 46),
          Offset(58, 38),
          Offset(58, 60),
          Offset(42, 68)
        ]),
        Paint()..color = const Color(0xFFD3CEC2));
    c.drawPath(
        poly(const [
          Offset(42, 30),
          Offset(58, 38),
          Offset(42, 46),
          Offset(26, 38)
        ]),
        Paint()..color = const Color(0xFFFCFBF7));
    // Écran.
    c.drawPath(
        poly(const [
          Offset(29, 44),
          Offset(39, 49),
          Offset(39, 58),
          Offset(29, 53)
        ]),
        Paint()..color = const Color(0xFF16261F));
    c.drawLine(
        const Offset(31, 48),
        const Offset(37, 51),
        Paint()
          ..strokeWidth = 1.6
          ..color = const Color(0xFF86D3AE));
    // Mât et abri.
    c.drawLine(
        const Offset(72, 62),
        const Offset(72, 30),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFAAB5AE));
    _ball(c, const Offset(72, 26), 8, const Color(0xFFC98A60));
    // Buisson.
    _ball(c, const Offset(20, 66), 8, const Color(0xFF5E9A7E));
  }

  void _history(Canvas c) {
    _shadow(c, const Offset(50, 93), 76, 9);
    _slab(
        c, const Rect.fromLTWH(10, 74, 80, 12), 4, 6, const Color(0xFFDCE5EF));
    _capsule(c, const Rect.fromLTWH(18, 48, 16, 32), const Color(0xFF86D3AE));
    _capsule(c, const Rect.fromLTWH(42, 30, 16, 50), const Color(0xFF7FA9D9));
    _capsule(c, const Rect.fromLTWH(66, 14, 16, 66), const Color(0xFFE29A68));
  }

  void _alerts(Canvas c) {
    _shadow(c, const Offset(50, 95), 56, 8);
    const apricot = Color(0xFFCDAE6C);
    _ball(c, const Offset(50, 80), 8, const Color(0xFF8E7240));
    final body = Path()
      ..moveTo(22, 72)
      ..cubicTo(28, 64, 26, 52, 28, 40)
      ..cubicTo(30, 22, 42, 14, 50, 14)
      ..cubicTo(58, 14, 70, 22, 72, 40)
      ..cubicTo(74, 52, 72, 64, 78, 72)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [_l(apricot, 0.45), apricot, _d(apricot, 0.25)],
          stops: const [0, 0.45, 1],
        ).createShader(body.getBounds()),
    );
    _gloss(c, const Offset(38, 38), 8, 22, alpha: 130);
    _capsule(c, const Rect.fromLTWH(16, 66, 68, 12), _d(apricot, 0.05),
        vertical: false);
    _ball(c, const Offset(50, 12), 6, apricot);
  }

  void _chip(Canvas c) {
    _shadow(c, const Offset(50, 93), 72, 9);
    const pin = Color(0xFFC9CCC6);
    for (var i = 0; i < 4; i++) {
      final x = 28.0 + i * 14;
      _capsule(c, Rect.fromLTWH(x - 3, 10, 6, 16), pin);
      _capsule(c, Rect.fromLTWH(x - 3, 70, 6, 16), pin);
    }
    _slab(
        c, const Rect.fromLTWH(14, 20, 72, 54), 6, 12, const Color(0xFF2B3A34));
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(32, 33, 36, 28), const Radius.circular(6)),
      Paint()..color = const Color(0xFF3B4D45),
    );
    _ball(c, const Offset(74, 31), 4, const Color(0xFF86D3AE));
  }

  void _screen(Canvas c) {
    _shadow(c, const Offset(50, 94), 66, 8);
    _capsule(c, const Rect.fromLTWH(44, 60, 12, 22), const Color(0xFFBFC6C0));
    _slab(c, const Rect.fromLTWH(30, 78, 40, 8), 3, 4, const Color(0xFF7E847D));
    _slab(
        c, const Rect.fromLTWH(10, 14, 80, 50), 6, 12, const Color(0xFF2A3B35));
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(18, 21, 64, 36), const Radius.circular(6)),
      Paint()..color = const Color(0xFF0C1813),
    );
    final mint = Paint()..color = const Color(0xFF86D3AE);
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(25, 28, 26, 9), const Radius.circular(2)),
        mint);
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(25, 42, 40, 4), const Radius.circular(2)),
      Paint()..color = const Color(0x9986D3AE),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(25, 49, 28, 4), const Radius.circular(2)),
      Paint()..color = const Color(0x6686D3AE),
    );
  }

  void _soil(Canvas c) {
    _shadow(c, const Offset(50, 93), 70, 9);
    const earth = Color(0xFF7A5B47);
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 80), width: 70, height: 24),
        Paint()..color = _d(earth, 0.3));
    final mound =
        Rect.fromCenter(center: const Offset(50, 75), width: 70, height: 24);
    c.drawOval(mound, _sphere(mound, earth));
    c.drawLine(
        const Offset(50, 74),
        const Offset(50, 40),
        Paint()
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF5E9A7E));
    void leaf(Offset at, double angle, double w) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle);
      final r =
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.48);
      c.drawOval(r, _sphere(r, const Color(0xFF7AAE94)));
      c.restore();
    }

    leaf(const Offset(36, 42), -0.55, 30);
    leaf(const Offset(64, 34), 0.55, 34);
  }

  void _water(Canvas c) {
    _shadow(c, const Offset(50, 95), 64, 8);
    const glass = Color(0xFFCFE4EE);
    final body = Path()
      ..addRect(const Rect.fromLTWH(22, 30, 56, 54))
      ..addOval(
          Rect.fromCenter(center: const Offset(50, 84), width: 56, height: 16));
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [_l(glass, 0.5), glass, _d(glass, 0.2)],
          stops: const [0, 0.45, 1],
        ).createShader(const Rect.fromLTWH(22, 30, 56, 62)),
    );
    final water = Path()
      ..addRect(const Rect.fromLTWH(22, 54, 56, 30))
      ..addOval(
          Rect.fromCenter(center: const Offset(50, 84), width: 56, height: 16));
    c.drawPath(
      water,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF9DB8DE), Color(0xFF7FA9D9), Color(0xFF4F78A8)],
          stops: [0, 0.5, 1],
        ).createShader(const Rect.fromLTWH(22, 54, 56, 38)),
    );
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 54), width: 56, height: 14),
        Paint()..color = const Color(0xFFB3CBEA));
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 30), width: 56, height: 16),
        Paint()..color = const Color(0xFFEAF3F7));
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 30), width: 56, height: 16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _a(Colors.white, 200),
    );
    // Capteur HC-SR04 au-dessus du réservoir.
    _capsule(c, const Rect.fromLTWH(36, 10, 28, 12), const Color(0xFF6E8FA0),
        vertical: false);
    _ball(c, const Offset(43, 16), 4, const Color(0xFFDCE3E6), gloss: false);
    _ball(c, const Offset(57, 16), 4, const Color(0xFFDCE3E6), gloss: false);
    _gloss(c, const Offset(30, 62), 5, 24, alpha: 110);
  }

  @override
  bool shouldRepaint(_ClayPainter old) => old.glyph != glyph;
}
