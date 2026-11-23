import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';

/// Sélecteur segmenté avec indicateur glissant.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected);
    final n = values.length;
    final x = n <= 1 ? 0.0 : -1 + 2 * index / (n - 1);
    final duration = Motion.of(context, 240);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Palette.paperDeep,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(x, 0),
              duration: duration,
              curve: Motion.curve,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.mint,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.line),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.shadow.fade(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final v in values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: v == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (v == selected) return;
                        HapticFeedback.selectionClick();
                        onChanged(v);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: v == selected
                                    ? Palette.paper
                                    : Palette.inkSoft,
                              ),
                              child:
                                  Text(labelOf(v), textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
