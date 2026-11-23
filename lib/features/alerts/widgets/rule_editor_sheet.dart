import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/alerts.dart';
import '../../../data/models/metric.dart';
import '../../../data/models/snapshot.dart';
import '../../../shared/widgets/atmos_button.dart';
import '../../../shared/widgets/atmos_sheet.dart';
import '../../../shared/widgets/atmos_toggle.dart';
import '../../../shared/widgets/segmented_pills.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Ouvre l'éditeur et renvoie la règle modifiée (ou `null` si annulé).
Future<AlertRule?> showRuleEditor(
  BuildContext context, {
  required AlertRule rule,
  required StationSnapshot? snapshot,
}) {
  return showAtmosSheet<AlertRule>(
    context,
    builder: (_) => RuleEditorSheet(rule: rule, snapshot: snapshot),
  );
}

class RuleEditorSheet extends StatefulWidget {
  const RuleEditorSheet(
      {super.key, required this.rule, required this.snapshot});

  final AlertRule rule;
  final StationSnapshot? snapshot;

  @override
  State<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<RuleEditorSheet> {
  late AlertRule _draft = widget.rule;

  MetricKind get _m => _draft.metric;

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final snapshot = widget.snapshot;
    final current = snapshot?.valueOf(m);
    final wouldTrigger = snapshot != null &&
        _draft.copyWith(enabled: true).isViolatedBy(snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ClayIcon(m.glyph, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RÈGLE D’ALERTE', style: AtmosText.overline),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(m.longLabel,
                        style: AtmosText.title.copyWith(fontSize: 22)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (m.isBinary)
          const Text(
            'Le capteur de pluie indique uniquement une présence. '
            'La règle se déclenche dès que des gouttes sont détectées.',
            style: AtmosText.body,
          )
        else ...[
          const Text('Déclencher quand la mesure passe',
              style: AtmosText.label),
          const SizedBox(height: 10),
          SegmentedPills<ThresholdDirection>(
            values: ThresholdDirection.values,
            selected: _draft.direction,
            labelOf: (d) => d.label,
            onChanged: (d) =>
                setState(() => _draft = _draft.copyWith(direction: d)),
          ),
          const SizedBox(height: 22),
          Center(
            child: Semantics(
              liveRegion: true,
              label: 'Seuil ${m.formatWithUnit(_draft.threshold)}',
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${_draft.direction.symbol} ',
                        style: AtmosText.display(34, color: Palette.inkMuted)),
                    TextSpan(
                        text: m.formatValue(_draft.threshold),
                        style: AtmosText.display(56)),
                    TextSpan(
                      text: ' ${m.unit}',
                      style:
                          const TextStyle(fontSize: 20, color: Palette.inkSoft),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Slider(
            value: _draft.threshold.clamp(m.minValue, m.maxValue).toDouble(),
            min: m.minValue,
            max: m.maxValue,
            divisions: ((m.maxValue - m.minValue) / m.step).round(),
            label: m.formatWithUnit(_draft.threshold),
            semanticFormatterCallback: (v) => m.formatWithUnit(v),
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(threshold: v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(m.formatWithUnit(m.minValue), style: AtmosText.caption),
                const Spacer(),
                Text(m.formatWithUnit(m.maxValue), style: AtmosText.caption),
              ],
            ),
          ),
        ],
        if (current != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: wouldTrigger ? Palette.apricotSoft : Palette.mintSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  wouldTrigger
                      ? Icons.notifications_active_outlined
                      : Icons.check_circle_outline,
                  size: 19,
                  color: wouldTrigger ? Palette.apricotDeep : Palette.mintDeep,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Valeur actuelle : ${m.formatWithUnit(current)}. '
                    '${wouldTrigger ? 'Cette règle serait déclenchée maintenant.' : 'Cette règle ne serait pas déclenchée.'}',
                    style: AtmosText.body
                        .copyWith(fontSize: 13.5, color: Palette.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
                child: Text('Règle active', style: AtmosText.heading)),
            AtmosToggle(
              value: _draft.enabled,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(enabled: v)),
              semanticLabel: 'Règle active',
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Évaluée localement à chaque relevé. Aucune notification n’est envoyée à cette étape.',
          style: AtmosText.caption,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AtmosButton(
                label: 'Annuler',
                style: AtmosButtonStyle.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtmosButton(
                label: 'Enregistrer',
                icon: Icons.check,
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
