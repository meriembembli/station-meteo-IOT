import 'package:flutter/material.dart';

import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/alerts.dart';
import '../../data/models/metric.dart';
import '../../shared/widgets/floating_nav_bar.dart';
import '../../shared/widgets/info_note.dart';
import '../../shared/widgets/page_header.dart';
import '../../state/atmos_scope.dart';
import 'widgets/alert_event_tile.dart';
import 'widgets/threshold_card.dart';

/// Destination « Alertes ».
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static AlertRule? _ruleFor(
    List<AlertRule> rules,
    MetricKind metric,
    ThresholdDirection direction,
  ) {
    for (final r in rules) {
      if (r.metric == metric && r.direction == direction) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final events = controller.events;
    final active = events.where((e) => e.isActive).toList();
    final resolved = events.where((e) => !e.isActive).toList();
    final snapshot = controller.snapshot;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: navClearance(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              overline: 'Alertes',
              title: 'Surveillance des seuils',
              subtitle:
                  'Les règles sont évaluées localement sur chaque relevé reçu.',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Overview(
                  active: active.length,
                  rules: controller.enabledRuleCount,
                  total: controller.rules.length),
            ),
            if (snapshot != null && !snapshot.isLive)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: InfoNote(
                  icon: Icons.pause_circle_outline,
                  tint: Palette.apricotDeep,
                  text:
                      'Évaluation suspendue : la station n’envoie plus de mesures récentes.',
                ),
              ),
            SectionTitle('En cours',
                trailing: active.isEmpty
                    ? null
                    : '${active.length} active${active.length > 1 ? 's' : ''}'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: active.isEmpty
                  ? const _CalmCard()
                  : Column(
                      children: [
                        for (final e in active) ...[
                          AlertEventTile(event: e),
                          if (!e.acknowledged)
                            Align(
                              alignment: Alignment.centerRight,
                              child: AcknowledgeButton(
                                  onPressed: () =>
                                      controller.acknowledge(e.id)),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
            const SectionTitle('Seuils des capteurs',
                trailing: 'Appliqués immédiatement'),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Réglez pour chaque capteur la plage acceptable : une alerte '
                'se déclenche dès qu’une mesure passe sous le seuil bas ou '
                'au-dessus du seuil haut.',
                style: AtmosText.body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final m in activeMetrics)
                    if (!m.isBinary) ...[
                      ThresholdCard(
                        metric: m,
                        low: _ruleFor(
                            controller.rules, m, ThresholdDirection.below),
                        high: _ruleFor(
                            controller.rules, m, ThresholdDirection.above),
                        current: snapshot?.valueOf(m),
                        onChanged: controller.updateRule,
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (_ruleFor(controller.rules, MetricKind.rain,
                          ThresholdDirection.above)
                      case final rain?)
                    RainRuleCard(
                      rule: rain,
                      detected: snapshot?.rainDetected,
                      onChanged: controller.updateRule,
                    ),
                ],
              ),
            ),
            SectionTitle('Journal',
                trailing: resolved.isEmpty ? null : 'Alertes résolues'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: resolved.isEmpty
                  ? const Text('Aucune alerte résolue pour le moment.',
                      style: AtmosText.body)
                  : Column(
                      children: [
                        for (final e in resolved) ...[
                          AlertEventTile(event: e),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: InfoNote(
                icon: Icons.notifications_off_outlined,
                text: 'Mode démo : aucune notification réelle n’est envoyée. '
                    'Les modifications sont conservées localement pendant la session.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview(
      {required this.active, required this.rules, required this.total});

  final int active;
  final int rules;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: active > 0 ? Palette.apricotSoft : Palette.mintSoft,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Figure(
              value: '$active',
              label: active > 1 ? 'alertes en cours' : 'alerte en cours',
              color: active > 0 ? Palette.apricotDeep : Palette.mintDeep,
            ),
          ),
          Container(width: 1, height: 44, color: Palette.ink.fade(0.1)),
          const SizedBox(width: 18),
          Expanded(
            child: _Figure(
              value: '$rules/$total',
              label: 'règles actives',
              color: Palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(
      {required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AtmosText.display(38, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: AtmosText.caption.copyWith(color: Palette.inkSoft)),
        ],
      ),
    );
  }
}

class _CalmCard extends StatelessWidget {
  const _CalmCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.spa_outlined, color: Palette.mintDeep),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucune alerte en cours', style: AtmosText.heading),
                SizedBox(height: 2),
                Text('Toutes les mesures respectent les seuils activés.',
                    style: AtmosText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
