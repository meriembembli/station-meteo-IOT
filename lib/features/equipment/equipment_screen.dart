import 'package:flutter/material.dart';

import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/hardware.dart';
import '../../shared/sheets/component_sheet.dart';
import '../../shared/widgets/atmos_button.dart';
import '../../shared/widgets/floating_nav_bar.dart';
import '../../shared/widgets/info_note.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/toast.dart';
import '../../state/atmos_scope.dart';
import '../station/scene/island_stage.dart';
import 'widgets/component_tile.dart';
import 'widgets/connection_card.dart';
import 'widgets/rename_sheet.dart';

/// Destination « Équipement ».
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    final controller = AtmosScope.read(context);
    setState(() => _syncing = true);
    final ok = await controller.refresh();
    if (!mounted) return;
    setState(() => _syncing = false);
    showToast(
      context,
      ok
          ? 'Nouveau relevé reçu.'
          : 'La station ne répond pas. Les dernières mesures restent affichées.',
      icon: ok ? Icons.check_circle_outline : Icons.wifi_off_rounded,
    );
  }

  Future<void> _rename() async {
    final controller = AtmosScope.read(context);
    final name = await showRenameSheet(context, controller.stationName);
    if (name == null || !mounted) return;
    await controller.rename(name);
    if (mounted) showToast(context, 'Station renommée « $name ».');
  }

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final snapshot = controller.snapshot;
    final installed =
        controller.device?.installedExtensions ?? const <String>{};

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: navClearance(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              overline: 'Équipement',
              title: controller.stationName,
              subtitle: 'Prototype ESP32 · capteurs environnementaux',
              trailing: Semantics(
                button: true,
                label: 'Renommer la station',
                child: IconButton.filledTonal(
                  onPressed: _rename,
                  tooltip: 'Renommer',
                  style: IconButton.styleFrom(
                    backgroundColor: Palette.surfaceHigh,
                    foregroundColor: Palette.ink,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 210,
                child: snapshot == null
                    ? const Skeleton(radius: 32)
                    : IslandStage(
                        snapshot: snapshot,
                        interactive: false,
                        borderRadius: 32),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Illustration en profondeur réalisée en formes vectorielles (pas un modèle 3D) : '
                'boîtier et écran, abri du capteur, LDR (les éléments non installés restent illustrés).',
                style: AtmosText.caption,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: snapshot == null
                  ? const Skeleton(height: 220, radius: 28)
                  : ConnectionCard(
                      snapshot: snapshot,
                      device: controller.device,
                      isDemo: controller.isDemo,
                      syncing: _syncing,
                      onSync: _sync,
                    ),
            ),
            SectionTitle('Composants installés',
                trailing: '${HardwareCatalog.installed.length} modules'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final c in HardwareCatalog.installed) ...[
                    ComponentTile(
                      component: c,
                      state: componentState(c, snapshot, installed),
                      onTap: () => showComponentSheet(context, c.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SectionTitle('Extensions optionnelles',
                trailing: 'Non installées par défaut'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final c in HardwareCatalog.extensions) ...[
                    ComponentTile(
                      component: c,
                      state: componentState(c, snapshot, installed),
                      onTap: () => showComponentSheet(context, c.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: InfoNote(
                icon: Icons.battery_charging_full,
                text: 'Batterie et panneau solaire : améliorations futures, '
                    'non installées sur ce prototype.',
              ),
            ),
            if (controller.signOut != null) ...[
              const SectionTitle('Compte'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: Palette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Palette.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined,
                          color: Palette.inkSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.accountEmail ?? 'Compte connecté',
                          style: AtmosText.label.copyWith(color: Palette.ink),
                        ),
                      ),
                      AtmosButton(
                        label: 'Se déconnecter',
                        icon: Icons.logout,
                        compact: true,
                        style: AtmosButtonStyle.secondary,
                        onPressed: () => controller.signOut!(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Center(
                child: Text(
                    controller.isDemo
                        ? 'ATMOS · version 0.2 · données simulées'
                        : 'ATMOS · version 0.2 · Firebase Realtime Database',
                    style: AtmosText.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
