import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import '../../data/models/snapshot.dart';

/// Ambiance du ciel, déduite des mesures de la station.
enum SkyMood { day, rain, dusk, mist, offline }

extension SkyMoodOf on SkyMood {
  /// Choisit l'ambiance à partir du dernier relevé (jour clair par défaut).
  static SkyMood from(StationSnapshot? s) {
    if (s == null) return SkyMood.day;
    if (s.link == LinkStatus.offline) return SkyMood.offline;
    if (s.rainDetected) return SkyMood.rain;
    if (s.light < 20) return SkyMood.dusk;
    if (s.humidity >= 85) return SkyMood.mist;
    return SkyMood.day;
  }

  /// Dégradé haut → milieu → bas. Tons assez profonds pour garder un bon
  /// contraste avec le texte blanc.
  List<Color> get colors => switch (this) {
        SkyMood.day => const [
            Color(0xFF1B57B2),
            Color(0xFF3274CC),
            Color(0xFF5893DA)
          ],
        SkyMood.rain => const [
            Color(0xFF34506F),
            Color(0xFF4F6A88),
            Color(0xFF7189A4)
          ],
        SkyMood.dusk => const [
            Color(0xFF232F5E),
            Color(0xFF4A4D88),
            Color(0xFF9A6E8A)
          ],
        SkyMood.mist => const [
            Color(0xFF4A6E99),
            Color(0xFF6A8BB2),
            Color(0xFF8FA9C6)
          ],
        SkyMood.offline => const [
            Color(0xFF3B4757),
            Color(0xFF526073),
            Color(0xFF6F7D8E)
          ],
      };

  /// Intensité de la lueur solaire en haut à droite.
  double get glow => switch (this) {
        SkyMood.day => 0.30,
        SkyMood.dusk => 0.22,
        SkyMood.mist => 0.20,
        SkyMood.rain => 0.10,
        SkyMood.offline => 0.06,
      };

  /// Teinte de la lueur (chaude au crépuscule).
  Color get glowColor =>
      this == SkyMood.dusk ? const Color(0xFFFFC29A) : Colors.white;
}

/// Fond « ciel » commun aux écrans : dégradé bleu qui suit les conditions
/// mesurées (jour, pluie, crépuscule, brume, hors ligne), lueur solaire douce
/// et voile de brume en bas. Transition fluide entre ambiances.
class AtmosBackground extends StatefulWidget {
  const AtmosBackground({super.key, required this.mood});

  final SkyMood mood;

  @override
  State<AtmosBackground> createState() => _AtmosBackgroundState();
}

class _AtmosBackgroundState extends State<AtmosBackground>
    with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  late final AnimationController _blend = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1,
  );
  late _Sky _from = _Sky.of(widget.mood);
  late _Sky _to = _Sky.of(widget.mood);
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = Motion.reduced(context);
    if (_reduced) {
      _breath.stop();
      _breath.value = 0.5;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AtmosBackground old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _from = _current();
      _to = _Sky.of(widget.mood);
      if (_reduced) {
        _blend.value = 1;
      } else {
        _blend.forward(from: 0);
      }
    }
  }

  _Sky _current() =>
      _Sky.lerp(_from, _to, Curves.easeInOut.transform(_blend.value));

  @override
  void dispose() {
    _breath.dispose();
    _blend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SkyPainter(
            repaint: Listenable.merge([_breath, _blend]),
            breath: () => Curves.easeInOut.transform(_breath.value),
            sky: _current,
          ),
        ),
      ),
    );
  }
}

class _Sky {
  const _Sky(this.colors, this.glow, this.glowColor);

  factory _Sky.of(SkyMood m) => _Sky(m.colors, m.glow, m.glowColor);

  final List<Color> colors;
  final double glow;
  final Color glowColor;

  static _Sky lerp(_Sky a, _Sky b, double t) => _Sky(
        [for (var i = 0; i < 3; i++) Color.lerp(a.colors[i], b.colors[i], t)!],
        a.glow + (b.glow - a.glow) * t,
        Color.lerp(a.glowColor, b.glowColor, t)!,
      );
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(
      {required Listenable repaint, required this.breath, required this.sky})
      : super(repaint: repaint);

  final double Function() breath;
  final _Sky Function() sky;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final s = sky();
    final b = breath();

    // Dégradé principal du ciel.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: s.colors,
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    // Lueur solaire douce en haut à droite.
    final w = size.width;
    final c = Offset(w * 0.85, -w * 0.05);
    final r = max(w * 1.1, size.height * 0.55) * (0.96 + 0.04 * b);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            s.glowColor.fade(s.glow * (0.9 + 0.1 * b)),
            s.glowColor.fade(s.glow * 0.25),
            s.glowColor.fade(0),
          ],
          stops: const [0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Voile de brume en bas, pour la profondeur.
    final haze = Rect.fromLTWH(0, size.height * 0.62, w, size.height * 0.38);
    canvas.drawRect(
      haze,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.fade(0), Colors.white.fade(0.07)],
        ).createShader(haze),
    );

    // Assombrissement léger en haut, sous la barre d'état.
    final top = Rect.fromLTWH(0, 0, w, size.height * 0.18);
    canvas.drawRect(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.shadow.fade(0.18), Palette.shadow.fade(0)],
        ).createShader(top),
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}
