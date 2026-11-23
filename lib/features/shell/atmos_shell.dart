import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/atmos_background.dart';
import '../../shared/widgets/floating_nav_bar.dart';
import '../../state/atmos_scope.dart';
import '../alerts/alerts_screen.dart';
import '../equipment/equipment_screen.dart';
import '../history/history_screen.dart';
import '../station/station_screen.dart';

/// Coque de l'application : quatre destinations conservées en mémoire
/// (position de défilement, sélections) et navigation basse flottante.
class AtmosShell extends StatelessWidget {
  const AtmosShell({super.key});

  static const _pages = <Widget>[
    StationScreen(),
    HistoryScreen(),
    AlertsScreen(),
    EquipmentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final index = controller.tab;

    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: AtmosBackground(mood: SkyMoodOf.from(controller.snapshot)),
          ),
          for (var i = 0; i < _pages.length; i++)
            _ShellPage(active: i == index, child: _pages[i]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              index: index,
              alertBadge: controller.unseenAlertCount,
              onSelect: controller.setTab,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, 220);
    // La page inactive est retirée de l'affichage (Offstage) mais conserve
    // son état. Les animations de transition sont placées HORS du
    // TickerMode, sinon elles seraient figées sur la page désactivée.
    return Positioned.fill(
      child: Offstage(
        offstage: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: Motion.curve,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.012),
            duration: duration,
            curve: Motion.curve,
            child: TickerMode(
              enabled: active,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
