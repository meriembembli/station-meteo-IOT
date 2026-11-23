import 'package:flutter/material.dart';

import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/repositories/demo_station_repository.dart';
import '../../state/atmos_scope.dart';
import '../widgets/atmos_button.dart';
import '../widgets/atmos_sheet.dart';
import '../widgets/pressable.dart';

Future<void> showDemoSheet(BuildContext context) =>
    showAtmosSheet<void>(context, builder: (_) => const DemoSheet());

/// Choix de la situation simulée, pour prévisualiser tous les états.
class DemoSheet extends StatelessWidget {
  const DemoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final current = controller.scenario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Palette.paperDeep, shape: BoxShape.circle),
              child: const Icon(Icons.science_outlined,
                  size: 20, color: Palette.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Mode démo',
                    style: AtmosText.title.copyWith(fontSize: 23)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Les mesures sont simulées localement : aucune station, aucun service '
          'distant. Choisissez une situation pour prévisualiser la scène et les '
          'états de l’interface.',
          style: AtmosText.body,
        ),
        const SizedBox(height: 18),
        for (final s in DemoScenario.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScenarioRow(
              scenario: s,
              selected: s == current,
              onTap: () {
                controller.setScenario(s);
                Navigator.of(context).pop();
              },
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: AtmosButton(
            label: 'Rejouer le chargement',
            icon: Icons.refresh,
            style: AtmosButtonStyle.secondary,
            onPressed: () {
              Navigator.of(context).pop();
              controller.replayLoading();
            },
          ),
        ),
      ],
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow(
      {required this.scenario, required this.selected, required this.onTap});

  final DemoScenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Pressable(
      onTap: onTap,
      selected: selected,
      borderRadius: radius,
      semanticLabel: '${scenario.label}. ${scenario.description}',
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Palette.mintSoft : Palette.paperDeep,
          borderRadius: radius,
          border: Border.all(
              color:
                  selected ? Palette.mintDeep.fade(0.4) : Colors.transparent),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.label,
                        style: AtmosText.heading.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(scenario.description, style: AtmosText.caption),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? Palette.mintDeep : Palette.inkMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
