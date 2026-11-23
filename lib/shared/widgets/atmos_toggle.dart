import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';

/// Interrupteur mat, zone tactile de 56 × 48.
class AtmosToggle extends StatelessWidget {
  const AtmosToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, 200);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              },
        child: SizedBox(
          width: 58,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: Motion.curve,
              width: 50,
              height: 30,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? Palette.mint : Palette.surfaceHigh,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? Palette.paper : Palette.inkMuted,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Palette.shadow.fade(0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
