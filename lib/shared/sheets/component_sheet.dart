import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/hardware.dart';
import '../../data/models/metric.dart';
import '../../data/models/snapshot.dart';
import '../../state/atmos_scope.dart';
import '../widgets/atmos_button.dart';
import '../widgets/atmos_sheet.dart';
import '../widgets/clay_icon.dart';

/// Ouvre la fiche détaillée d'un composant (capteur, ESP32, OLED, extension).
Future<void> showComponentSheet(BuildContext context, String componentId) {
  return showAtmosSheet<void>(
    context,
    builder: (_) =>
        ComponentSheet(component: HardwareCatalog.byId(componentId)),
  );
}

enum ComponentState { active, silent, offline, notInstalled }

ComponentState componentState(
    HardwareComponent c, StationSnapshot? s, Set<String> installedExtensions) {
  if (c.optional && !installedExtensions.contains(c.id)) {
    return ComponentState.notInstalled;
  }
  if (s == null) return ComponentState.silent;
  return switch (s.link) {
    LinkStatus.online => ComponentState.active,
    LinkStatus.stale => ComponentState.silent,
    LinkStatus.offline => ComponentState.offline,
  };
}

extension ComponentStateInfo on ComponentState {
  String get label => switch (this) {
        ComponentState.active => 'Actif',
        ComponentState.silent => 'Sans nouvelle donnée',
        ComponentState.offline => 'Injoignable',
        ComponentState.notInstalled => 'Non installé',
      };

  Color get color => switch (this) {
        ComponentState.active => Palette.mintDeep,
        ComponentState.silent => Palette.apricotDeep,
        ComponentState.offline => Palette.inkMuted,
        ComponentState.notInstalled => Palette.inkMuted,
      };
}

class StateTag extends StatelessWidget {
  const StateTag({super.key, required this.state});

  final ComponentState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: state.color.fade(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        state.label,
        style: AtmosText.label.copyWith(color: state.color, fontSize: 12),
      ),
    );
  }
}

class ComponentSheet extends StatelessWidget {
  const ComponentSheet({super.key, required this.component});

  final HardwareComponent component;

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final snapshot = controller.snapshot;
    final installed =
        controller.device?.installedExtensions ?? const <String>{};
    final state = componentState(component, snapshot, installed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClayIcon(
              glyphForComponent(component.id),
              size: 56,
              muted: state == ComponentState.notInstalled,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                      header: true,
                      child: Text(component.name,
                          style: AtmosText.title.copyWith(fontSize: 23))),
                  const SizedBox(height: 4),
                  Text(component.role, style: AtmosText.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StateTag(state: state),
        const SizedBox(height: 14),
        Text(component.summary, style: AtmosText.body),
        if (component.measures.isNotEmpty && snapshot != null) ...[
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Palette.paperDeep,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (var i = 0; i < component.measures.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Palette.line),
                  _MeasureRow(
                      metric: component.measures[i], snapshot: snapshot),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.isLive
                ? 'Relevé reçu à ${Fr.time(snapshot.measuredAt)}'
                : 'Dernier relevé connu : ${Fr.dateTime(snapshot.measuredAt)}',
            style: AtmosText.caption,
          ),
        ],
        const SizedBox(height: 20),
        const Text('À SAVOIR', style: AtmosText.overline),
        const SizedBox(height: 10),
        for (final note in component.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 10),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                      color: Palette.mintDeep, shape: BoxShape.circle),
                ),
                Expanded(
                    child: Text(note,
                        style: AtmosText.body.copyWith(fontSize: 14))),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AtmosButton(
                label: 'Fermer',
                style: AtmosButtonStyle.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (component.measures.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AtmosButton(
                  label: 'Historique',
                  icon: Icons.show_chart,
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller.openHistory(component.measures.first);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MeasureRow extends StatelessWidget {
  const _MeasureRow({required this.metric, required this.snapshot});

  final MetricKind metric;
  final StationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ClayIcon(metric.glyph, size: 24),
          const SizedBox(width: 10),
          Expanded(
              child: Text(metric.longLabel,
                  style: AtmosText.body.copyWith(color: Palette.ink))),
          Text(
            metric.formatWithUnit(snapshot.valueOf(metric)),
            style: AtmosText.number(16),
          ),
        ],
      ),
    );
  }
}
