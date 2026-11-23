import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'pressable.dart';

enum AtmosButtonStyle { primary, secondary, quiet }

/// Bouton maison : 48 px minimum, encre pleine ou contour discret.
class AtmosButton extends StatelessWidget {
  const AtmosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AtmosButtonStyle.primary,
    this.busy = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AtmosButtonStyle style;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final (Color bg, Color fg, Color border) = switch (style) {
      AtmosButtonStyle.primary => (Palette.mint, Palette.paper, Palette.mint),
      AtmosButtonStyle.secondary => (
          Palette.surface,
          Palette.ink,
          Palette.line
        ),
      AtmosButtonStyle.quiet => (
          Palette.surfaceHigh,
          Palette.ink,
          Palette.line
        ),
    };
    final radius = BorderRadius.circular(compact ? 18 : 22);

    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 40 : 50),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  else if (icon != null)
                    Icon(icon, size: 18, color: fg),
                  if (busy || icon != null) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg,
                        fontSize: compact ? 13.5 : 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
