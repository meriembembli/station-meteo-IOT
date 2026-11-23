import 'package:flutter/material.dart';

import '../../../core/motion.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/metric.dart';
import '../../../data/models/snapshot.dart';
import 'backdrop_painter.dart';
import 'island_painter.dart';
import 'scene_geometry.dart';
import 'sensor_hotspot.dart';

/// Scène de la station : fond, îlot isométrique animé et points interactifs.
///
/// Glisser horizontalement incline légèrement la scène (parallaxe).
/// Toutes les animations s'arrêtent si l'utilisateur réduit les animations.
class IslandStage extends StatefulWidget {
  const IslandStage({
    super.key,
    required this.snapshot,
    this.focus,
    this.onSelect,
    this.onInspect,
    this.interactive = true,
    this.borderRadius = 36,
  });

  final StationSnapshot snapshot;
  final MetricKind? focus;
  final ValueChanged<MetricKind>? onSelect;

  /// Appui long sur un point : ouvrir la fiche du capteur.
  final ValueChanged<MetricKind>? onInspect;
  final bool interactive;
  final double borderRadius;

  @override
  State<IslandStage> createState() => _IslandStageState();
}

class _IslandStageState extends State<IslandStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  Offset _tilt = Offset.zero;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = Motion.reduced(context);
    if (_reduced) {
      _clock.stop();
      _clock.value = 0.35;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    setState(() {
      _tilt =
          Offset((_tilt.dx + d.delta.dx / 110).clamp(-1.0, 1.0).toDouble(), 0);
    });
  }

  void _release() {
    if (_tilt != Offset.zero) setState(() => _tilt = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final conditions = SceneConditions.from(widget.snapshot);
    final canTilt = widget.interactive && !_reduced;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Palette.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: GestureDetector(
          onHorizontalDragUpdate: canTilt ? _onDrag : null,
          onHorizontalDragEnd: canTilt ? (_) => _release() : null,
          onHorizontalDragCancel: canTilt ? _release : null,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(end: _tilt),
            duration:
                _reduced ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, tilt, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final geometry = SceneGeometry(constraints.biggest);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BackdropPainter(
                              conditions: conditions, parallax: tilt),
                        ),
                      ),
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: IslandPainter(
                              clock: _clock,
                              conditions: conditions,
                              focus: widget.focus,
                              parallax: tilt,
                              showGuides: widget.interactive,
                            ),
                          ),
                        ),
                      ),
                      if (widget.interactive)
                        for (final m in activeMetrics)
                          AnimatedBuilder(
                            animation: _clock,
                            builder: (context, child) {
                              final design = SensorAnchors.bubble(m) +
                                  Offset(tilt.dx * 6,
                                      tilt.dy * 3 + floatOffset(_clock.value));
                              final p = geometry.toScreen(design);
                              const half = SensorHotspot.hitSize / 2;
                              return Positioned(
                                left: p.dx - half,
                                top: p.dy - half,
                                child: child!,
                              );
                            },
                            child: SensorHotspot(
                              metric: m,
                              selected: m == widget.focus,
                              valueLabel:
                                  m.formatWithUnit(widget.snapshot.valueOf(m)),
                              onTap: () => widget.onSelect?.call(m),
                              onLongPress: widget.onInspect == null
                                  ? null
                                  : () => widget.onInspect!(m),
                            ),
                          ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
