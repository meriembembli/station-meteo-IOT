import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';

/// Surface tactile mate : léger enfoncement au toucher, focus clavier,
/// sémantique de bouton. Base de toutes les cartes interactives.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.semanticLabel,
    this.selected,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final bool? selected;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: Motion.of(context, 120),
        curve: Curves.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: widget.borderRadius,
            splashColor: Palette.ink.fade(0.06),
            highlightColor: Palette.ink.fade(0.03),
            onHighlightChanged: (v) => setState(() => _down = v),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
