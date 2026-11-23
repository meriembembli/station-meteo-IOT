import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import 'clay_icon.dart';

/// Hauteur réservée en bas des pages pour la barre flottante.
double navClearance(BuildContext context) =>
    96 + MediaQuery.paddingOf(context).bottom;

class NavDestination {
  const NavDestination(this.glyph, this.label);

  final ClayGlyph glyph;
  final String label;
}

const atmosDestinations = [
  NavDestination(ClayGlyph.station, 'Station'),
  NavDestination(ClayGlyph.history, 'Historique'),
  NavDestination(ClayGlyph.alerts, 'Alertes'),
  NavDestination(ClayGlyph.chip, 'Équipement'),
];

/// Navigation basse flottante et compacte.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.index,
    required this.onSelect,
    this.alertBadge = 0,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int alertBadge;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.navBar,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Palette.line),
                boxShadow: [
                  BoxShadow(
                    color: Palette.shadow.fade(0.55),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Palette.shadow.fade(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    for (var i = 0; i < atmosDestinations.length; i++)
                      Expanded(
                        child: _NavItem(
                          destination: atmosDestinations[i],
                          selected: i == index,
                          badge: i == 2 ? alertBadge : 0,
                          onTap: () {
                            if (i != index) HapticFeedback.selectionClick();
                            onSelect(i);
                          },
                        ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, 220);
    final fg = selected ? Palette.mintDeep : Palette.inkMuted;
    final semantic = badge > 0
        ? '${destination.label}, $badge alerte${badge > 1 ? 's' : ''} en cours'
        : destination.label;

    return Semantics(
      button: true,
      selected: selected,
      label: semantic,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Motion.curve,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? Palette.mintSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.12 : 1,
                    duration: duration,
                    curve: Curves.easeOutBack,
                    child: ClayIcon(destination.glyph, size: 26),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -7,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Palette.apricotDeep,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selected ? Palette.mintSoft : Palette.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Palette.paper,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
