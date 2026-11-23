import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/motion.dart';
import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/history.dart';
import '../../../data/models/metric.dart';
import '../../../data/models/snapshot.dart';
import '../../../shared/widgets/pressable.dart';
import 'sparkline.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Indicateur principal : une seule mesure à la fois, en grand.
class FocusPanel extends StatelessWidget {
  const FocusPanel({
    super.key,
    required this.metric,
    required this.snapshot,
    required this.trend,
    required this.onDetails,
    required this.onHistory,
  });

  final MetricKind metric;
  final StationSnapshot snapshot;
  final List<HistoryPoint>? trend;
  final VoidCallback onDetails;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, 320);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(
        key: ValueKey(metric),
        child: _FocusContent(
          metric: metric,
          snapshot: snapshot,
          trend: trend,
          onDetails: onDetails,
          onHistory: onHistory,
        ),
      ),
    );
  }
}

class _FocusContent extends StatelessWidget {
  const _FocusContent({
    required this.metric,
    required this.snapshot,
    required this.trend,
    required this.onDetails,
    required this.onHistory,
  });

  final MetricKind metric;
  final StationSnapshot snapshot;
  final List<HistoryPoint>? trend;
  final VoidCallback onDetails;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final value = snapshot.valueOf(metric);
    final live = snapshot.isLive;
    final valueColor = live ? Palette.ink : Palette.inkSoft;

    final Widget big = metric.isBinary
        ? Text(
            value >= 0.5 ? 'Pluie détectée' : 'Pas de pluie',
            style: AtmosText.display(44, color: valueColor),
          )
        : Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: metric.formatValue(value),
                  style: AtmosText.display(78, color: valueColor)),
              TextSpan(
                text: ' ${metric.unit}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Palette.inkSoft,
                  letterSpacing: -0.3,
                ),
              ),
            ]),
          );

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${metric.longLabel} : ${metric.formatWithUnit(value)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClayIcon(metric.glyph, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${metric.longLabel.toUpperCase()} · ${metric.sensor}',
                  style: AtmosText.overline.copyWith(color: Palette.inkSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: big,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Sparkline(metric: metric, points: trend),
            ],
          ),
          const SizedBox(height: 10),
          Text(metric.describe(value), style: AtmosText.body),
          if (!live) ...[
            const SizedBox(height: 4),
            Text(
              'Mesure du ${Fr.dateTime(snapshot.measuredAt)}',
              style: AtmosText.caption.copyWith(color: Palette.apricotDeep),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LinkChip(
                  icon: Icons.info_outline,
                  label: 'Fiche du capteur',
                  onTap: onDetails),
              _LinkChip(
                  icon: Icons.show_chart,
                  label: 'Voir l’historique',
                  onTap: onHistory),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.line),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Palette.ink),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Palette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
