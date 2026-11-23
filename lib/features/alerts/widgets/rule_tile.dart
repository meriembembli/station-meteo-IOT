import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/alerts.dart';
import '../../../data/models/metric.dart';
import '../../../shared/widgets/atmos_toggle.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Règle d'alerte : toucher pour modifier le seuil, interrupteur pour activer.
class RuleTile extends StatelessWidget {
  const RuleTile({
    super.key,
    required this.rule,
    required this.onToggle,
    required this.onEdit,
  });

  final AlertRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final m = rule.metric;
    final radius = BorderRadius.circular(22);
    return Pressable(
      onTap: onEdit,
      borderRadius: radius,
      semanticLabel: 'Modifier la règle : ${rule.title}',
      child: Ink(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: radius,
          border: Border.all(color: Palette.line),
        ),
        child: Row(
          children: [
            AnimatedOpacity(
              opacity: rule.enabled ? 1 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: ClayIcon(m.glyph, size: 40),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.label,
                        style: AtmosText.caption
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      rule.condition,
                      style: AtmosText.number(
                        19,
                        color: rule.enabled ? Palette.ink : Palette.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(rule.sentence, style: AtmosText.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            AtmosToggle(
              value: rule.enabled,
              onChanged: onToggle,
              semanticLabel: 'Activer la règle ${rule.title}',
            ),
          ],
        ),
      ),
    );
  }
}
