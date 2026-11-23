import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/history.dart';
import '../../../data/models/metric.dart';
import 'history_chart.dart';

/// Minimum, moyenne, maximum — ou indicateurs de présence pour la pluie.
class HistoryStatsRow extends StatelessWidget {
  const HistoryStatsRow({
    super.key,
    required this.metric,
    required this.range,
    required this.points,
  });

  final MetricKind metric;
  final HistoryRange range;
  final List<HistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles;
    if (metric.isBinary) {
      final s = PresenceStats.of(points);
      if (s == null) return const SizedBox.shrink();
      tiles = [
        _StatTile(
          label: 'Temps avec pluie',
          value: '${(s.share * 100).round()}',
          unit: '%',
          caption: 'sur ${range.longLabel}',
        ),
        _StatTile(
          label: 'Épisodes',
          value: '${s.episodes}',
          unit: '',
          caption: s.episodes <= 1 ? 'détection' : 'détections',
        ),
        _StatTile(
          label: 'Dernière',
          value: s.lastDetection == null ? '—' : Fr.time(s.lastDetection!),
          unit: '',
          caption: s.lastDetection == null
              ? 'aucune détection'
              : Fr.relativeDay(s.lastDetection!, DateTime.now()),
        ),
      ];
    } else {
      final s = HistoryStats.of(points);
      if (s == null) return const SizedBox.shrink();
      tiles = [
        _StatTile(
          label: 'Minimum',
          value: metric.formatValue(s.min),
          unit: metric.unit,
          caption: pointTimeLabel(s.minAt, range),
          icon: Icons.south,
        ),
        _StatTile(
          label: 'Moyenne',
          value: metric.formatValue(s.mean),
          unit: metric.unit,
          caption: range.longLabel,
          icon: Icons.drag_handle,
        ),
        _StatTile(
          label: 'Maximum',
          value: metric.formatValue(s.max),
          unit: metric.unit,
          caption: pointTimeLabel(s.maxAt, range),
          icon: Icons.north,
        ),
      ];
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
    this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final String caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label : $value $unit, $caption',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: Palette.inkMuted),
                  const SizedBox(width: 4),
                ],
                Flexible(
                    child: Text(label,
                        style: AtmosText.caption
                            .copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: value, style: AtmosText.number(22)),
                  if (unit.isNotEmpty)
                    TextSpan(
                        text: ' $unit',
                        style: AtmosText.caption.copyWith(fontSize: 12.5)),
                ]),
              ),
            ),
            const SizedBox(height: 4),
            Text(caption, style: AtmosText.caption.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
