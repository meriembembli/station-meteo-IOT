import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/history.dart';
import '../../data/models/metric.dart';
import '../../data/models/snapshot.dart';
import '../../shared/sheets/component_sheet.dart';
import '../../shared/sheets/demo_sheet.dart';
import '../../shared/widgets/floating_nav_bar.dart';
import '../../shared/widgets/link_pill.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/status_banner.dart';
import '../../state/atmos_scope.dart';
import 'scene/island_stage.dart';
import 'widgets/focus_panel.dart';
import 'widgets/metric_strip.dart';
import 'widgets/quick_links.dart';
import 'widgets/station_loading_view.dart';
import 'widgets/summary_card.dart';

/// Destination « Station » : la station vivante.
class StationScreen extends StatelessWidget {
  const StationScreen({super.key});

  /// ≈ 40 % de la hauteur disponible, bornée pour les petits et grands écrans.
  static double sceneHeightFor(BuildContext context) {
    final mq = MediaQuery.of(context);
    final available = mq.size.height - mq.padding.vertical;
    return (available * 0.40).clamp(250.0, 470.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final snapshot = controller.snapshot;
    final sceneHeight = sceneHeightFor(context);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: navClearance(context)),
        child: snapshot == null
            ? StationLoadingView(
                sceneHeight: sceneHeight,
                stationName: controller.stationName,
              )
            : _StationContent(snapshot: snapshot, sceneHeight: sceneHeight),
      ),
    );
  }
}

class _StationContent extends StatelessWidget {
  const _StationContent({required this.snapshot, required this.sceneHeight});

  final StationSnapshot snapshot;
  final double sceneHeight;

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final focus = controller.focus;
    final List<HistoryPoint>? trend =
        controller.historyFor(focus, HistoryRange.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          name: controller.stationName,
          snapshot: snapshot,
          showDemo: controller.isDemo,
        ),
        if (!snapshot.isLive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: StatusBanner(snapshot: snapshot),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: sceneHeight,
            child: IslandStage(
              snapshot: snapshot,
              focus: focus,
              onSelect: controller.selectFocus,
              onInspect: (m) => showComponentSheet(context, m.sensorId),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Touchez un capteur · glissez pour incliner la scène',
            style: AtmosText.caption.copyWith(fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 20, 0),
          child: FocusPanel(
            metric: focus,
            snapshot: snapshot,
            trend: trend,
            onDetails: () => showComponentSheet(context, focus.sensorId),
            onHistory: () => controller.openHistory(focus),
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(child: Text('MESURES', style: AtmosText.overline)),
              Text('Capteurs : DHT11 · LDR',
                  style: AtmosText.caption.copyWith(fontSize: 11.5)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        MetricStrip(
          snapshot: snapshot,
          selected: focus,
          onSelect: controller.selectFocus,
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SummaryCard(snapshot: snapshot),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: QuickLinks(
            activeAlerts: controller.activeAlertCount,
            enabledRules: controller.enabledRuleCount,
            onHistory: () => controller.openHistory(focus),
            onAlerts: controller.openAlerts,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.name, required this.snapshot, required this.showDemo});

  final String name;
  final StationSnapshot snapshot;
  final bool showDemo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ma station', style: AtmosText.label),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  child: Text(name,
                      style: AtmosText.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LinkPill(link: snapshot.link),
                    if (snapshot.isLive)
                      ReceivedAgo(at: snapshot.measuredAt)
                    else
                      Text(
                        'Dernière réception : ${Fr.dateTime(snapshot.measuredAt)}',
                        style: AtmosText.caption,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showDemo) const _DemoChip(),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Pressable(
      onTap: () => showDemoSheet(context),
      borderRadius: radius,
      semanticLabel: 'Mode démo : choisir une situation simulée',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Palette.paperDeep,
              borderRadius: radius,
            ),
            child: const ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science_outlined,
                      size: 14, color: Palette.inkSoft),
                  SizedBox(width: 5),
                  Text(
                    'Mode démo',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Palette.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
