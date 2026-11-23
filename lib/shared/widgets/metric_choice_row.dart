import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import '../../data/models/metric.dart';
import 'pressable.dart';
import 'clay_icon.dart';

/// Rangée horizontale de choix de mesure (historique).
class MetricChoiceRow extends StatelessWidget {
  const MetricChoiceRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final MetricKind selected;
  final ValueChanged<MetricKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, 200);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final m in activeMetrics)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Pressable(
                selected: m == selected,
                semanticLabel: m.label,
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(m);
                },
                child: AnimatedContainer(
                  duration: duration,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: m == selected ? m.soft : Palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: m == selected ? m.deep.fade(0.5) : Palette.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClayIcon(m.glyph, size: 22),
                      const SizedBox(width: 7),
                      Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              m == selected ? FontWeight.w700 : FontWeight.w500,
                          color: Palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
