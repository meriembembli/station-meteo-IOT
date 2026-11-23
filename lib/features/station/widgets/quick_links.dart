import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Accès directs à l'historique et aux alertes depuis la station.
class QuickLinks extends StatelessWidget {
  const QuickLinks({
    super.key,
    required this.activeAlerts,
    required this.enabledRules,
    required this.onHistory,
    required this.onAlerts,
  });

  final int activeAlerts;
  final int enabledRules;
  final VoidCallback onHistory;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final alertText = activeAlerts == 0
        ? 'Aucune alerte en cours · $enabledRules règles actives'
        : '$activeAlerts alerte${activeAlerts > 1 ? 's' : ''} en cours';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              glyph: ClayGlyph.history,
              tint: Palette.glacierSoft,
              iconColor: Palette.glacierDeep,
              title: 'Historique',
              subtitle: 'Courbes 24 h, 7 j et 30 j',
              onTap: onHistory,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tile(
              glyph: ClayGlyph.alerts,
              tint: activeAlerts > 0 ? Palette.apricotSoft : Palette.mintSoft,
              iconColor:
                  activeAlerts > 0 ? Palette.apricotDeep : Palette.mintDeep,
              title: 'Alertes',
              subtitle: alertText,
              highlight: activeAlerts > 0,
              onTap: onAlerts,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.glyph,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final ClayGlyph glyph;
  final Color tint;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Pressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: '$title. $subtitle',
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? Palette.apricotSoft : Palette.surface,
          borderRadius: radius,
          border: Border.all(
            color: highlight ? Palette.apricotDeep.fade(0.3) : Palette.line,
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClayIcon(glyph, size: 40),
                  const Spacer(),
                  const Icon(Icons.north_east,
                      size: 18, color: Palette.inkMuted),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: AtmosText.heading),
              const SizedBox(height: 4),
              Text(subtitle, style: AtmosText.caption),
            ],
          ),
        ),
      ),
    );
  }
}
