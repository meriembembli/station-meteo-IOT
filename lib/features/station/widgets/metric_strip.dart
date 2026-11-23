import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/motion.dart';
import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/metric.dart';
import '../../../data/models/snapshot.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/clay_icon.dart';

/// Sélection horizontale des mesures : toutes les valeurs restent lisibles
/// sans passer par la scène.
class MetricStrip extends StatelessWidget {
  const MetricStrip({
    super.key,
    required this.snapshot,
    required this.selected,
    required this.onSelect,
  });

  final StationSnapshot snapshot;
  final MetricKind selected;
  final ValueChanged<MetricKind> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final m in activeMetrics)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _MetricChip(
                  metric: m,
                  value: snapshot.valueOf(m),
                  selected: m == selected,
                  muted: !snapshot.isLive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(m);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.metric,
    required this.value,
    required this.selected,
    required this.muted,
    required this.onTap,
  });

  final MetricKind metric;
  final double value;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, 220);
    final radius = BorderRadius.circular(24);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '${metric.label} : ${metric.formatWithUnit(value)}',
      borderRadius: radius,
      child: AnimatedContainer(
        duration: duration,
        curve: Motion.curve,
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.fromLTRB(14, 13, 16, 14),
        decoration: BoxDecoration(
          color: selected ? metric.soft : Palette.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? metric.deep.fade(0.45) : Palette.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClayIcon(metric.glyph, size: 22),
                  const SizedBox(width: 6),
                  Text(metric.label, style: AtmosText.label),
                ],
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: metric.shortValue(value),
                    style: AtmosText.number(
                      metric.isBinary ? 17 : 21,
                      color: muted ? Palette.inkSoft : Palette.ink,
                    ),
                  ),
                  if (!metric.isBinary)
                    TextSpan(
                      text: ' ${metric.unit}',
                      style: AtmosText.caption.copyWith(fontSize: 13),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
