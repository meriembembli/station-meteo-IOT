import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/alerts.dart';
import '../../../data/models/metric.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Événement d'alerte : actif (abricot, plein) ou résolu (neutre, discret).
class AlertEventTile extends StatelessWidget {
  const AlertEventTile({super.key, required this.event, this.onAcknowledge});

  final AlertEvent event;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = event.isActive;
    final seen = event.acknowledged;
    final m = event.metric;

    final valueText = m.isBinary
        ? 'Gouttes détectées sur le capteur'
        : 'Valeur relevée ${m.formatWithUnit(event.value)} · seuil ${m.formatWithUnit(event.threshold)}';
    final timeText = active
        ? 'Depuis ${Fr.relativeDay(event.startedAt, now).toLowerCase()} à ${Fr.time(event.startedAt)}'
        : '${Fr.relativeDay(event.startedAt, now)} · ${Fr.time(event.startedAt)} → ${Fr.time(event.resolvedAt!)}';

    final bg = active
        ? (seen ? Palette.surface : Palette.apricotSoft)
        : Palette.surface;
    final border =
        active ? Palette.apricotDeep.fade(seen ? 0.35 : 0.25) : Palette.line;

    return Semantics(
      container: true,
      label:
          '${active ? 'Alerte en cours' : 'Alerte résolue'} : ${event.title}. $valueText. $timeText.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClayIcon(m.glyph, size: 40, muted: !active),
            const SizedBox(width: 14),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: AtmosText.heading.copyWith(
                              fontSize: 15.5,
                              color: active ? Palette.ink : Palette.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Tag(
                          text:
                              active ? (seen ? 'Vue' : 'En cours') : 'Résolue',
                          color:
                              active ? Palette.apricotDeep : Palette.inkMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(valueText,
                        style: AtmosText.body.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Text(timeText, style: AtmosText.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton textuel compact pour acquitter une alerte active.
class AcknowledgeButton extends StatelessWidget {
  const AcknowledgeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Palette.apricotDeep,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.visibility_outlined, size: 17),
      label: const Text('Marquer comme vue'),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.fade(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AtmosText.label.copyWith(fontSize: 11.5, color: color),
      ),
    );
  }
}
