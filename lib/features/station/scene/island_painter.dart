import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../../../data/models/metric.dart';
import 'scene_geometry.dart';

/// Illustration isométrique en couches de la station sur son îlot.
///
/// Il s'agit d'une illustration vectorielle en profondeur (formes, dégradés
/// mats, ombres floues, parallaxe), pas d'un modèle 3D.
class IslandPainter extends CustomPainter {
  IslandPainter({
    required this.clock,
    required this.conditions,
    required this.focus,
    required this.parallax,
    required this.showGuides,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final SceneConditions conditions;
  final MetricKind? focus;
  final Offset parallax;
  final bool showGuides;

  static const _rx = 138.0;
  static const _ry = 80.0;
  static const _thick = 38.0;

  static final Rect _top = Rect.fromCenter(
    center: islandCenter,
    width: _rx * 2,
    height: _ry * 2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final g = SceneGeometry(size);
    final lift = floatOffset(t);
    final shift = Offset(parallax.dx * 6, parallax.dy * 3 + lift);

    canvas.save();
    canvas.translate(g.origin.dx, g.origin.dy);
    canvas.scale(g.scale);

    _groundShadow(canvas, lift);

    canvas.save();
    canvas.translate(shift.dx, shift.dy);
    _islandBody(canvas);
    _groundDetails(canvas);
    if (conditions.rain) _wetGround(canvas, t);
    if (focus != null) _focusHalo(canvas, t);
    _bush(canvas, const Offset(88, 152), 19);
    _bush(canvas, const Offset(298, 168), 15);
    _cable(canvas);
    _shelter(canvas);
    _enclosure(canvas, t);
    _rainSensor(canvas);
    _rock(canvas, const Offset(286, 204), 16);
    _rock(canvas, const Offset(96, 224), 12);
    _rock(canvas, const Offset(222, 242), 9);
    _bush(canvas, const Offset(112, 202), 14);
    _bush(canvas, const Offset(248, 228), 10);
    _bush(canvas, const Offset(146, 230), 11);
    _tufts(canvas);
    _flowers(canvas);
    if (showGuides) _guides(canvas);
    canvas.restore();

    if (conditions.mist > 0) _mist(canvas, t);
    if (conditions.rain) _rainDrops(canvas, t);
    canvas.restore();

    // Ambiance générale, sur toute la surface de la scène.
    final dim = conditions.dimness;
    if (dim > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Palette.shadow.fade(0.42 * dim),
      );
    }
    if (conditions.offline) {
      canvas.drawRect(
          Offset.zero & size, Paint()..color = Palette.paper.fade(0.34));
    }

    // Lueur de l'écran OLED, plus perceptible quand la lumière baisse.
    if (!conditions.offline) {
      canvas.save();
      canvas.translate(g.origin.dx, g.origin.dy);
      canvas.scale(g.scale);
      canvas.translate(shift.dx, shift.dy);
      final c = iso(-11, 10, 31);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 46, height: 34),
        Paint()
          ..color = const Color(0xFF86D3AE).fade(0.12 + 0.30 * dim)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.restore();
    }
  }

  // --- Îlot -----------------------------------------------------------------

  void _groundShadow(Canvas canvas, double lift) {
    final spread = 1 - lift * 0.01;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(islandCenter.dx + 8, islandCenter.dy + _ry + _thick - 4),
        width: _rx * 1.9 * spread,
        height: 30,
      ),
      Paint()
        ..color = Palette.shadow.fade(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  Path _band(Rect top, double thick) {
    final bottom = top.shift(Offset(0, thick));
    return Path()
      ..moveTo(top.left, top.center.dy)
      ..lineTo(bottom.left, bottom.center.dy)
      ..arcTo(bottom, pi, -pi, false)
      ..lineTo(top.right, top.center.dy)
      ..arcTo(top, 0, pi, false)
      ..close();
  }

  void _islandBody(Canvas canvas) {
    final whole =
        Rect.fromLTRB(_top.left, _top.top, _top.right, _top.bottom + _thick);
    final side = _band(_top, _thick);

    canvas.drawPath(
      side,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4F3A2E), Color(0xFF7A5B47), Color(0xFF977862)],
          stops: [0, 0.55, 1],
        ).createShader(whole),
    );
    canvas.drawPath(
      side,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Palette.shadow.fade(0.16)],
        ).createShader(Rect.fromLTRB(
            _top.left, islandCenter.dy, _top.right, whole.bottom)),
    );

    // Strates de terre.
    final strata = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.fade(0.26);
    for (final k in const [18.0, 29.0]) {
      canvas.drawArc(_top.shift(Offset(0, k)), 0.18, pi - 0.36, false, strata);
    }
    // Petits cailloux pris dans la terre.
    final pebble = Paint()..color = const Color(0xFFD9C3B3).fade(0.45);
    for (final p in const [
      Offset(92, 258),
      Offset(150, 274),
      Offset(232, 270),
      Offset(282, 248)
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: p, width: 6, height: 3.4), pebble);
    }

    // Bord herbeux puis surface supérieure.
    canvas.drawPath(_band(_top, 9), Paint()..color = const Color(0xFF4A7A62));
    canvas.drawOval(
      _top,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.55),
          radius: 1.05,
          colors: [Color(0xFFA3CFB8), Color(0xFF7AAE94), Color(0xFF5A8E77)],
          stops: [0, 0.55, 1],
        ).createShader(_top),
    );
    canvas.drawArc(
      _top.deflate(1),
      pi * 1.05,
      pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.fade(0.55),
    );
  }

  void _groundDetails(Canvas canvas) {
    final patch = Paint()..color = const Color(0xFF4A7A62).fade(0.35);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(118, 178), width: 64, height: 22),
        patch);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(238, 212), width: 76, height: 24),
        patch);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(210, 124), width: 54, height: 16),
      Paint()..color = Colors.white.fade(0.18),
    );

    // Chemin de pierres plates.
    final shade = Paint()..color = Palette.shadow.fade(0.12);
    final stone = Paint()..color = const Color(0xFFD3D8D2);
    for (final p in const [
      Offset(136, 246),
      Offset(147, 232),
      Offset(156, 218),
      Offset(165, 205),
    ]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: p + const Offset(0, 1.6), width: 17, height: 8.5),
          shade);
      canvas.drawOval(
          Rect.fromCenter(center: p, width: 17, height: 8.5), stone);
    }
  }

  void _wetGround(Canvas canvas, double t) {
    canvas.drawOval(_top, Paint()..color = Palette.rainDeep.fade(0.12));
    for (final (c, w) in const [
      (Offset(108, 216), 40.0),
      (Offset(232, 240), 30.0),
      (Offset(264, 196), 26.0),
    ]) {
      final r = Rect.fromCenter(center: c, width: w, height: w * 0.36);
      canvas.drawOval(r, Paint()..color = Palette.rain.fade(0.55));
      canvas.drawOval(
        r.deflate(3).shift(const Offset(-2, -1)),
        Paint()..color = Colors.white.fade(0.35),
      );
      final ripple = (t * 4 + c.dx / 100) % 1.0;
      final rw = w * (0.3 + 0.6 * ripple);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rw, height: rw * 0.36),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.fade(0.6 * (1 - ripple)),
      );
    }
  }

  void _focusHalo(Canvas canvas, double t) {
    final m = focus!;
    final c = SensorAnchors.ground(m);
    final pulse = 0.5 + 0.5 * sin(t * 2 * pi * 2);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 86 + 8 * pulse, height: 42 + 4 * pulse),
      Paint()
        ..color = m.color.fade(0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 70, height: 34),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = m.deep.fade(0.45),
    );
  }

  // --- Végétation et décor ---------------------------------------------------

  void _bush(Canvas canvas, Offset base, double r) {
    canvas.drawOval(
      Rect.fromCenter(
          center: base + Offset(r * 0.3, 1), width: r * 2.5, height: r * 0.9),
      Paint()
        ..color = Palette.shadow.fade(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    for (final (dx, dy, s) in const [
      (0.0, -1.05, 0.82),
      (-0.58, -0.55, 0.72),
      (0.56, -0.6, 0.7),
    ]) {
      final c = base + Offset(dx * r, dy * r);
      final rad = r * s;
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.45, -0.55),
            radius: 1.0,
            colors: [Color(0xFF9CCDB6), Color(0xFF5E9A7E), Color(0xFF3B705B)],
            stops: [0, 0.6, 1],
          ).createShader(Rect.fromCircle(center: c, radius: rad)),
      );
    }
  }

  void _rock(Canvas canvas, Offset c, double w) {
    canvas.drawOval(
      Rect.fromCenter(
          center: c + const Offset(2, 2), width: w * 1.1, height: w * 0.5),
      Paint()
        ..color = Palette.shadow.fade(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final r = Rect.fromCenter(center: c, width: w, height: w * 0.62);
    canvas.drawOval(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB4B9B2), Color(0xFF6E756E)],
        ).createShader(r),
    );
  }

  void _tufts(Canvas canvas) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3B705B).fade(0.9);
    for (final b in const [
      Offset(70, 188),
      Offset(238, 140),
      Offset(108, 172),
      Offset(272, 216),
      Offset(196, 248),
      Offset(304, 192),
      Offset(60, 168),
    ]) {
      canvas.drawLine(b, b + const Offset(-3, -7), p);
      canvas.drawLine(b, b + const Offset(0, -9), p);
      canvas.drawLine(b, b + const Offset(3, -6.5), p);
    }
  }

  void _flowers(Canvas canvas) {
    final center = Paint()..color = const Color(0xFF0B2A20);
    for (final (c, col) in const [
      (Offset(98, 198), Color(0xFFE29A68)),
      (Offset(128, 210), Color(0xFFDCC072)),
      (Offset(262, 238), Color(0xFF7FA9D9)),
      (Offset(234, 224), Color(0xFFE9EFEB)),
      (Offset(314, 180), Color(0xFFE29A68)),
    ]) {
      canvas.drawCircle(c, 2.4, Paint()..color = col);
      canvas.drawCircle(c, 0.9, center);
    }
  }

  // --- Station ---------------------------------------------------------------

  void _box(
    Canvas canvas,
    double x,
    double y,
    double z,
    double w,
    double d,
    double h, {
    required Color top,
    required Color left,
    required Color right,
  }) {
    final t1 = iso(x, y, z + h);
    final t2 = iso(x + w, y, z + h);
    final t3 = iso(x + w, y + d, z + h);
    final t4 = iso(x, y + d, z + h);
    final b2 = iso(x + w, y, z);
    final b3 = iso(x + w, y + d, z);
    final b4 = iso(x, y + d, z);

    final leftFace = Path()..addPolygon([t4, t3, b3, b4], true);
    final rightFace = Path()..addPolygon([t3, t2, b2, b3], true);
    final topFace = Path()..addPolygon([t1, t2, t3, t4], true);

    canvas.drawPath(
      leftFace,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [left, Color.lerp(left, Palette.shadow, 0.06)!],
        ).createShader(leftFace.getBounds()),
    );
    canvas.drawPath(
      rightFace,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [right, Color.lerp(right, Palette.shadow, 0.08)!],
        ).createShader(rightFace.getBounds()),
    );
    canvas.drawPath(topFace, Paint()..color = top);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.fade(0.7);
    canvas.drawLine(t4, t3, edge);
    canvas.drawLine(t3, t2, edge);
    canvas.drawLine(
        t3,
        b3,
        Paint()
          ..strokeWidth = 0.6
          ..color = Palette.shadow.fade(0.08));
  }

  void _cable(Canvas canvas) {
    final a = iso(40, -40, 0);
    final b = iso(10, -14, 0);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(
          (a.dx + b.dx) / 2 + 4, max(a.dy, b.dy) + 10, b.dx, b.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Palette.shadow.fade(0.35),
    );
  }

  void _shelter(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: iso(44, -36, 0), width: 40, height: 16),
      Paint()
        ..color = Palette.shadow.fade(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Mât.
    final base = iso(40, -40, 0);
    final top = iso(40, -40, 72);
    canvas.drawLine(
        base,
        top,
        Paint()
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFB9C3BC));
    canvas.drawLine(
        base + const Offset(-1, 0),
        top + const Offset(-1, 0),
        Paint()
          ..strokeWidth = 1.2
          ..color = Colors.white.fade(0.6));
    canvas.drawOval(
      Rect.fromCenter(center: base, width: 12, height: 5),
      Paint()..color = const Color(0xFFA9B2AB),
    );

    // Abri ventilé (BME280) à persiennes.
    _box(canvas, 28, -52, 70, 24, 24, 26,
        top: const Color(0xFFE8ECE8),
        left: const Color(0xFFD0D5D0),
        right: const Color(0xFFAAB1AB));
    final louver = Paint()
      ..strokeWidth = 1
      ..color = Palette.shadow.fade(0.13);
    for (var z = 73.0; z <= 93; z += 4) {
      canvas.drawLine(iso(29.5, -28, z), iso(51, -28, z - 1.5), louver);
      canvas.drawLine(iso(52, -29.5, z), iso(52, -51, z - 1.5), louver);
    }

    // Toit abricot.
    _box(canvas, 25, -55, 96, 30, 30, 4,
        top: const Color(0xFFE6AE86),
        left: const Color(0xFFC98A60),
        right: const Color(0xFFA66E4A));
  }

  void _enclosure(Canvas canvas, double t) {
    final shadow = Path()
      ..addPolygon(
          [iso(-40, -36, 0), iso(26, -36, 0), iso(26, 26, 0), iso(-40, 26, 0)],
          true);
    canvas.drawPath(
      shadow.shift(const Offset(5, 5)),
      Paint()
        ..color = Palette.shadow.fade(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Socle puis boîtier étanche.
    _box(canvas, -40, -36, 0, 62, 58, 6,
        top: const Color(0xFF8D958F),
        left: const Color(0xFF6E7671),
        right: const Color(0xFF575E5A));
    _box(canvas, -30, -26, 6, 40, 36, 44,
        top: const Color(0xFFE8ECE8),
        left: const Color(0xFFD0D5D0),
        right: const Color(0xFFAAB1AB));

    // Joint du couvercle.
    final a = iso(-30, 10, 44);
    final b = iso(10, 10, 44);
    final c = iso(10, -26, 44);
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Palette.shadow.fade(0.1),
    );

    // Aérations.
    final vent = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Palette.shadow.fade(0.12);
    for (var i = 0; i < 3; i++) {
      final z = 30.0 - i * 5;
      canvas.drawLine(iso(10, -20, z), iso(10, -6, z), vent);
    }

    // LED d'état.
    final on = !conditions.offline;
    final led = iso(10, 3, 14);
    if (on) {
      final blink = 0.55 + 0.45 * sin(t * 2 * pi * 3).abs();
      canvas.drawCircle(
        led,
        4.5,
        Paint()
          ..color = Palette.mint.fade(0.6 * blink)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawCircle(led, 1.8,
        Paint()..color = on ? Palette.mintDeep : const Color(0xFFB7BDB7));

    _oled(canvas);
    _ldr(canvas);

    // Antenne Wi-Fi.
    final a0 = iso(4, -22, 50);
    final a1 = iso(4, -22, 66);
    canvas.drawLine(
        a0,
        a1,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Palette.shadow.fade(0.55));
    canvas.drawCircle(a1, 2.3, Paint()..color = Palette.shadow.fade(0.75));
  }

  void _oled(Canvas canvas) {
    Path face(double x0, double x1, double z0, double z1) => Path()
      ..addPolygon(
          [iso(x0, 10, z1), iso(x1, 10, z1), iso(x1, 10, z0), iso(x0, 10, z0)],
          true);

    canvas.drawPath(
        face(-25, 3, 20, 42), Paint()..color = const Color(0xFF24362F));
    canvas.drawPath(
      face(-23.5, 1.5, 21.5, 40.5),
      Paint()
        ..color = conditions.offline
            ? const Color(0xFF1A2420)
            : const Color(0xFF0C1813),
    );
    if (conditions.offline) return;

    // Texte projeté sur la face gauche du boîtier.
    final origin = iso(-22, 10, 39);
    canvas.save();
    canvas.transform(Float64List.fromList([
      0.866, 0.5, 0, 0, //
      0, 1, 0, 0, //
      0, 0, 1, 0, //
      origin.dx, origin.dy, 0, 1,
    ]));
    _oledText(canvas, conditions.oledMain, const Offset(0.5, 0.5), 8,
        FontWeight.w700);
    _oledText(canvas, conditions.oledSub, const Offset(0.5, 10.5), 4.6,
        FontWeight.w600);
    canvas.drawRect(
      Rect.fromLTWH(0.5, 16.6,
          21 * (conditions.light / 100).clamp(0.0, 1.0).toDouble(), 1.2),
      Paint()..color = const Color(0xFF86D3AE),
    );
    canvas.restore();
  }

  void _oledText(
      Canvas canvas, String text, Offset at, double size, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFA8F0CF),
          fontSize: size,
          fontWeight: weight,
          height: 1,
          letterSpacing: 0.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  void _ldr(Canvas canvas) {
    final p = iso(-14, -12, 50);
    canvas.drawOval(
      Rect.fromCenter(center: p, width: 16, height: 8),
      Paint()..color = const Color(0xFFC9CDC7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: p - const Offset(0, 1), width: 7, height: 3.6),
      Paint()..color = const Color(0xFFC98A60),
    );
    final zig = Path()
      ..moveTo(p.dx - 2.6, p.dy - 1)
      ..lineTo(p.dx - 1.3, p.dy - 2)
      ..lineTo(p.dx, p.dy - 0.8)
      ..lineTo(p.dx + 1.3, p.dy - 2)
      ..lineTo(p.dx + 2.6, p.dy - 1);
    canvas.drawPath(
      zig,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFF6B3A1E),
    );
    final dome = Rect.fromCircle(center: p + const Offset(0, -0.5), radius: 7);
    canvas.drawArc(
        dome, pi, pi, true, Paint()..color = Colors.white.fade(0.38));
    canvas.drawArc(
      dome.deflate(1.6),
      pi * 1.15,
      pi * 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.fade(0.9),
    );
  }

  void _rainSensor(Canvas canvas) {
    final shadow = Path()
      ..addPolygon(
          [iso(34, 16, 0), iso(64, 16, 0), iso(64, 40, 0), iso(34, 40, 0)],
          true);
    canvas.drawPath(
      shadow.shift(const Offset(3, 3)),
      Paint()
        ..color = Palette.shadow.fade(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final leg = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9AA59E);
    canvas.drawLine(iso(62, 18, 0), iso(62, 18, 19), leg);
    canvas.drawLine(iso(36, 18, 0), iso(36, 18, 19), leg);
    canvas.drawLine(iso(62, 38, 0), iso(62, 38, 11), leg);
    canvas.drawLine(iso(36, 38, 0), iso(36, 38, 11), leg);

    // Plaque inclinée : u le long de x, v le long de y.
    Offset plate(double u, double v) =>
        iso(34 + 30 * u, 16 + 24 * v, 20 - 8 * v);

    final board = Path()
      ..addPolygon([plate(0, 0), plate(1, 0), plate(1, 1), plate(0, 1)], true);
    canvas.drawPath(board.shift(const Offset(0, 2.2)),
        Paint()..color = const Color(0xFF1E2F45));
    canvas.drawPath(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF52729A), Color(0xFF34527A)],
        ).createShader(board.getBounds()),
    );

    // Pistes en peigne.
    final trace = Paint()
      ..strokeWidth = 0.9
      ..color = const Color(0xFFDCEBF1).fade(0.8);
    canvas.drawLine(plate(0.08, 0.1), plate(0.08, 0.9), trace);
    canvas.drawLine(plate(0.92, 0.1), plate(0.92, 0.9), trace);
    for (var i = 0; i < 6; i++) {
      final v = 0.14 + i * 0.14;
      if (i.isEven) {
        canvas.drawLine(plate(0.08, v), plate(0.8, v), trace);
      } else {
        canvas.drawLine(plate(0.2, v), plate(0.92, v), trace);
      }
    }

    if (conditions.rain) {
      for (final (u, v, r) in const [
        (0.3, 0.3, 2.2),
        (0.62, 0.5, 2.8),
        (0.45, 0.78, 1.8),
        (0.8, 0.22, 1.6),
      ]) {
        final p = plate(u, v);
        canvas.drawOval(
          Rect.fromCenter(center: p, width: r * 2, height: r * 1.3),
          Paint()..color = Colors.white.fade(0.75),
        );
        canvas.drawCircle(p + Offset(-r * 0.3, -r * 0.2), r * 0.35,
            Paint()..color = Colors.white);
      }
    }
  }

  // --- Repères et effets -----------------------------------------------------

  void _guides(Canvas canvas) {
    for (final m in activeMetrics) {
      final a = SensorAnchors.anchor(m);
      final b = SensorAnchors.bubble(m);
      final selected = m == focus;
      final dir = b - a;
      final len = dir.distance;
      if (len < 24) continue;
      final end = a + dir * ((len - 22) / len);
      _dashed(
        canvas,
        a,
        end,
        Paint()
          ..strokeWidth = selected ? 1.4 : 1
          ..strokeCap = StrokeCap.round
          ..color =
              (selected ? m.deep : Palette.ink).fade(selected ? 0.7 : 0.26),
      );
      canvas.drawCircle(a, selected ? 4.5 : 3.2, Paint()..color = Colors.white);
      canvas.drawCircle(
        a,
        selected ? 3 : 2,
        Paint()..color = selected ? m.deep : Palette.ink.fade(0.5),
      );
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final n = (d.distance / 4).floor();
    if (n < 2) return;
    for (var i = 0; i < n; i += 2) {
      canvas.drawLine(a + d * (i / n), a + d * ((i + 1) / n), paint);
    }
  }

  void _mist(Canvas canvas, double t) {
    final k = conditions.mist;
    for (final (c, w, h, phase) in const [
      (Offset(112, 196), 150.0, 36.0, 0.0),
      (Offset(256, 176), 170.0, 32.0, 0.35),
      (Offset(186, 238), 220.0, 34.0, 0.7),
    ]) {
      final dx = sin((t + phase) * 2 * pi) * 14;
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(dx, 0), width: w, height: h),
        Paint()
          ..color = const Color(0xFFDDE6E2).fade(0.32 * k)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
  }

  void _rainDrops(Canvas canvas, double t) {
    final drop = Paint()
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = Palette.rainDeep.fade(0.5);
    final splash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 0; i < 30; i++) {
      final x = 56.0 + (i * 97) % 248;
      final rel = (x - islandCenter.dx) / _rx;
      final half = _ry * sqrt(max(0.0, 1 - rel * rel));
      final land =
          islandCenter.dy - half * 0.7 + ((i * 53) % 100) / 100 * half * 1.4;
      final speed = 1 + (i % 3) * 0.3;
      final phase = (t * 5 * speed + i * 0.137) % 1.0;
      const top = -10.0;
      final y = top + phase * (land - top + 14);
      if (y < land) {
        canvas.drawLine(Offset(x, y), Offset(x - 1.6, y + 8), drop);
      } else {
        final k = (y - land) / 14;
        splash.color = Palette.rainDeep.fade(0.35 * (1 - k));
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, land + 8), width: 4 + 8 * k, height: 2 + 3 * k),
          splash,
        );
      }
    }
  }

  @override
  bool shouldRepaint(IslandPainter old) =>
      old.conditions != conditions ||
      old.focus != focus ||
      old.parallax != parallax ||
      old.showGuides != showGuides;
}
