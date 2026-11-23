import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/motion.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/metric.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Point interactif ancré sur un capteur de la scène.
/// Zone tactile de 48 × 48, retour haptique, état sélectionné animé.
class SensorHotspot extends StatefulWidget {
  const SensorHotspot({
    super.key,
    required this.metric,
    required this.selected,
    required this.valueLabel,
    required this.onTap,
    this.onLongPress,
  });

  static const double hitSize = 48;

  final MetricKind metric;
  final bool selected;
  final String valueLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<SensorHotspot> createState() => _SensorHotspotState();
}

class _SensorHotspotState extends State<SensorHotspot> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;
    final selected = widget.selected;
    final duration = Motion.of(context, 240);
    final scale = _pressed ? 0.86 : (selected ? 1.1 : 1.0);

    return Semantics(
      button: true,
      selected: selected,
      label: '${m.label} : ${widget.valueLabel}. Capteur ${m.sensor}.',
      hint: 'Afficher cette mesure',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _setPressed(false);
                widget.onLongPress!();
              },
        child: SizedBox(
          width: SensorHotspot.hitSize,
          height: SensorHotspot.hitSize,
          child: Center(
            child: AnimatedScale(
              scale: scale,
              duration: duration,
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: duration,
                curve: Motion.curve,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? m.soft : Palette.surfaceHigh,
                  border: Border.all(
                    color: selected ? m.deep : Palette.line,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? m.color.fade(0.45)
                          : Palette.shadow.fade(0.5),
                      blurRadius: selected ? 18 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: ClayIcon(m.glyph, size: 26)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
