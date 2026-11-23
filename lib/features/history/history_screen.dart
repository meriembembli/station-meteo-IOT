import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/history.dart';
import '../../data/models/metric.dart';
import '../../data/models/snapshot.dart';
import '../../shared/widgets/floating_nav_bar.dart';
import '../../shared/widgets/info_note.dart';
import '../../shared/widgets/metric_choice_row.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/segmented_pills.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/atmos_scope.dart';
import 'widgets/history_chart.dart';
import 'widgets/history_stats.dart';

/// Destination « Historique ».
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AtmosScope.of(context);
    final metric = controller.historyMetric;
    final range = controller.historyRange;
    final snapshot = controller.snapshot;
    final points = controller.historyFor(metric, range);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: navClearance(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              overline: 'Historique',
              title: 'Mesures enregistrées',
              subtitle: controller.stationName,
            ),
            const SizedBox(height: 10),
            MetricChoiceRow(
                selected: metric, onSelect: controller.setHistoryMetric),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedPills<HistoryRange>(
                values: HistoryRange.values,
                selected: range,
                labelOf: (r) => r.label,
                onChanged: controller.setHistoryRange,
              ),
            ),
            if (snapshot != null && !snapshot.isLive)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: InfoNote(
                  icon: Icons.history_toggle_off,
                  text: 'Historique arrêté à la dernière réception : '
                      '${Fr.dateTime(snapshot.measuredAt)}.',
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: Motion.of(context, 260),
                child: KeyedSubtree(
                  key: ValueKey(
                      '$metric-$range-${points == null ? 'l' : points.isEmpty ? 'e' : 'd'}'),
                  child: _HistoryBody(
                    metric: metric,
                    range: range,
                    points: points,
                    snapshot: snapshot,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.metric,
    required this.range,
    required this.points,
    required this.snapshot,
  });

  final MetricKind metric;
  final HistoryRange range;
  final List<HistoryPoint>? points;
  final StationSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final pts = points;
    if (pts == null) return const _ChartLoading();
    if (pts.isEmpty) return _EmptyHistory(metric: metric, range: range);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartCard(metric: metric, range: range, points: pts),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: HistoryStatsRow(metric: metric, range: range, points: pts),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            metric == MetricKind.light
                ? 'Lumière : valeur relative de la LDR (0–100 %), non convertie en lux.'
                : metric == MetricKind.rain
                    ? 'Pluie : présence détectée ou non. Aucune quantité n’est mesurée.'
                    : 'Source : ${metric.sensor}. ${range.stepLabel}.',
            style: AtmosText.caption,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatefulWidget {
  const _ChartCard(
      {required this.metric, required this.range, required this.points});

  final MetricKind metric;
  final HistoryRange range;
  final List<HistoryPoint> points;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int? _selected;

  @override
  void didUpdateWidget(_ChartCard old) {
    super.didUpdateWidget(old);
    if (old.metric != widget.metric ||
        old.range != widget.range ||
        !identical(old.points, widget.points)) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;
    final pts = widget.points;
    final inspected =
        _selected != null && _selected! < pts.length ? pts[_selected!] : null;
    final shown = inspected ?? pts.last;
    final unitLabel = m.isBinary ? 'présence' : m.unit;
    final mq = MediaQuery.of(context);
    final chartHeight = (mq.size.height * 0.30).clamp(200.0, 300.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 14, 14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Palette.line),
        boxShadow: [
          BoxShadow(
              color: Palette.shadow.fade(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m.longLabel} ($unitLabel)',
                          style: AtmosText.heading),
                      const SizedBox(height: 2),
                      Text(widget.range.longLabel, style: AtmosText.caption),
                    ],
                  ),
                ),
                if (inspected != null)
                  Semantics(
                    button: true,
                    label: 'Revenir au dernier relevé',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = null),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close,
                            size: 18, color: Palette.inkMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: m.formatValue(shown.value),
                            style: AtmosText.display(m.isBinary ? 30 : 40),
                          ),
                          if (!m.isBinary)
                            TextSpan(
                              text: ' ${m.unit}',
                              style: const TextStyle(
                                  fontSize: 17, color: Palette.inkSoft),
                            ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      inspected == null
                          ? 'Dernier relevé · ${Fr.time(shown.time)}'
                          : pointTimeLabel(shown.time, widget.range),
                      style: AtmosText.caption.copyWith(
                        color: inspected == null ? Palette.inkMuted : m.deep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Courbe de ${m.withArticle} sur ${widget.range.longLabel}. '
                'Touchez ou glissez pour lire une valeur.',
            child: SizedBox(
              height: chartHeight,
              child: HistoryChart(
                points: pts,
                metric: m,
                range: widget.range,
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 14, color: Palette.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Touchez ou faites glisser pour inspecter la courbe.',
                  style: AtmosText.caption.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement de l’historique',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Palette.line),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 190, height: 16),
            SizedBox(height: 16),
            Skeleton(width: 120, height: 36, radius: 14),
            SizedBox(height: 18),
            Skeleton(height: 210, radius: 18),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.metric, required this.range});

  final MetricKind metric;
  final HistoryRange range;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 70,
            child: CustomPaint(painter: _EmptyCurvePainter(metric.deep)),
          ),
          const SizedBox(height: 18),
          const Text('Aucun historique pour l’instant',
              style: AtmosText.heading, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'La station n’a pas encore enregistré de ${metric.label.toLowerCase()} '
            'sur les ${range.longLabel}. Les relevés apparaîtront ici dès la première synchronisation.',
            style: AtmosText.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyCurvePainter extends CustomPainter {
  _EmptyCurvePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color.fade(0.35);
    for (var x = 0.0; x <= size.width; x += 9) {
      final y = size.height * 0.55 +
          12 * (x / size.width - 0.5) * (x / size.width - 0.5) * -4 +
          6;
      canvas.drawCircle(Offset(x, y), 1.8, dot);
    }
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      Paint()
        ..color = Palette.line
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_EmptyCurvePainter old) => old.color != color;
}
