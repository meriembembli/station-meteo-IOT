import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/history.dart';
import '../../../data/models/metric.dart';
import '../../../shared/painting/smooth_path.dart';

/// Libellé temporel d'un point selon la période.
String pointTimeLabel(DateTime t, HistoryRange range) => switch (range) {
      HistoryRange.day => Fr.time(t),
      HistoryRange.week => '${Fr.weekday(t)} ${Fr.two(t.hour)} h',
      HistoryRange.month => '${Fr.shortDate(t)} · ${Fr.two(t.hour)} h',
    };

/// Courbe d'historique avec axes lisibles et inspection tactile.
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.points,
    required this.metric,
    required this.range,
    required this.selected,
    required this.onSelect,
  });

  final List<HistoryPoint> points;
  final MetricKind metric;
  final HistoryRange range;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = ChartLayout(
            points: points, metric: metric, range: range, size: size);

        void pick(Offset local) {
          final i = layout.indexAt(local.dx);
          if (i != selected) {
            HapticFeedback.selectionClick();
            onSelect(i);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pick(d.localPosition),
          onHorizontalDragStart: (d) => pick(d.localPosition),
          onHorizontalDragUpdate: (d) => pick(d.localPosition),
          child: CustomPaint(
            size: size,
            painter: _ChartPainter(layout: layout, selected: selected),
          ),
        );
      },
    );
  }
}

/// Calculs de mise en page partagés entre le dessin et l'interaction.
class ChartLayout {
  ChartLayout({
    required this.points,
    required this.metric,
    required this.range,
    required this.size,
  }) {
    plot = Rect.fromLTRB(46, 20, size.width - 10, size.height - 28);
    start = points.first.time;
    end = points.last.time;

    if (metric.isBinary) {
      yMin = -0.15;
      yMax = 1.25;
      ticks = const [0.0, 1.0];
      return;
    }
    var lo = points.map((p) => p.value).reduce(min);
    var hi = points.map((p) => p.value).reduce(max);
    if ((hi - lo).abs() < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    final step = _niceStep((hi - lo) * 1.2, 4);
    var a = (lo / step).floor() * step;
    var b = (hi / step).ceil() * step;
    if (metric == MetricKind.humidity || metric == MetricKind.light) {
      a = max(0.0, a);
      b = min(100.0, b);
    }
    if (b - a < step) b = a + step;
    yMin = a;
    yMax = b;
    tickStep = step;
    ticks = [for (var v = a; v <= b + step * 0.01; v += step) v];
  }

  final List<HistoryPoint> points;
  final MetricKind metric;
  final HistoryRange range;
  final Size size;

  late final Rect plot;
  late final DateTime start;
  late final DateTime end;
  late final double yMin;
  late final double yMax;
  late final List<double> ticks;
  double tickStep = 1;

  static double _niceStep(double span, int target) {
    final raw = span / target;
    final mag = pow(10, (log(raw) / ln10).floor()).toDouble();
    final norm = raw / mag;
    final double nice;
    if (norm < 1.5) {
      nice = 1;
    } else if (norm < 2.25) {
      nice = 2;
    } else if (norm < 3.5) {
      nice = 2.5;
    } else if (norm < 7.5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * mag;
  }

  double xOf(DateTime t) {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return plot.left;
    return plot.left + plot.width * t.difference(start).inSeconds / total;
  }

  double yOf(double v) =>
      plot.bottom - (v - yMin) / (yMax - yMin) * plot.height;

  Offset offsetAt(int i) => Offset(xOf(points[i].time), yOf(points[i].value));

  int indexAt(double dx) {
    final f = ((dx - plot.left) / plot.width).clamp(0.0, 1.0);
    return (f * (points.length - 1)).round();
  }

  String yLabel(double v) {
    if (metric.isBinary) return v >= 0.5 ? 'Oui' : 'Non';
    final decimals = tickStep < 1 ? 1 : 0;
    return Fr.number(v, decimals);
  }

  /// Graduations temporelles adaptées à la période.
  List<(DateTime, String)> xTicks() {
    final result = <(DateTime, String)>[];
    switch (range) {
      case HistoryRange.day:
        var t = DateTime(start.year, start.month, start.day, start.hour);
        while (t.hour % 6 != 0 || t.isBefore(start)) {
          t = t.add(const Duration(hours: 1));
        }
        while (!t.isAfter(end)) {
          result.add((t, '${Fr.two(t.hour)} h'));
          t = t.add(const Duration(hours: 6));
        }
      case HistoryRange.week:
        var t = DateTime(start.year, start.month, start.day)
            .add(const Duration(days: 1));
        while (!t.isAfter(end)) {
          result.add((t, Fr.weekday(t)));
          t = t.add(const Duration(days: 1));
        }
      case HistoryRange.month:
        var t = DateTime(start.year, start.month, start.day)
            .add(const Duration(days: 1));
        while (!t.isAfter(end)) {
          result.add((t, Fr.shortDate(t)));
          t = t.add(const Duration(days: 7));
        }
    }
    return result;
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.layout, required this.selected});

  final ChartLayout layout;
  final int? selected;

  static const _labelStyle = TextStyle(
    color: Palette.inkMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  void _text(Canvas canvas, String text, Offset at,
      {TextAlign align = TextAlign.left, TextStyle style = _labelStyle}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var dx = at.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final l = layout;
    final m = l.metric;
    final plot = l.plot;

    // Unité de l'axe vertical.
    if (!m.isBinary) {
      _text(canvas, m.unit, Offset(plot.left - 8, plot.top - 12),
          align: TextAlign.right,
          style: _labelStyle.copyWith(
              fontWeight: FontWeight.w700, color: Palette.inkSoft));
    }

    // Grille horizontale.
    final grid = Paint()
      ..color = Palette.ink.fade(0.08)
      ..strokeWidth = 1;
    for (final v in l.ticks) {
      final y = l.yOf(v);
      for (var x = plot.left; x < plot.right; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(min(x + 3, plot.right), y), grid);
      }
      _text(canvas, l.yLabel(v), Offset(plot.left - 8, y),
          align: TextAlign.right);
    }

    // Graduations temporelles.
    final tick = Paint()
      ..color = Palette.ink.fade(0.18)
      ..strokeWidth = 1;
    for (final (t, label) in l.xTicks()) {
      final x = l.xOf(t);
      if (x < plot.left - 1 || x > plot.right + 1) continue;
      canvas.drawLine(Offset(x, plot.bottom), Offset(x, plot.bottom + 4), tick);
      final clampedX = x.clamp(plot.left + 12, plot.right - 12).toDouble();
      _text(canvas, label, Offset(clampedX, plot.bottom + 15),
          align: TextAlign.center);
    }
    canvas.drawLine(
        Offset(plot.left, plot.bottom), Offset(plot.right, plot.bottom), tick);

    // Série.
    final offsets = [for (var i = 0; i < l.points.length; i++) l.offsetAt(i)];
    final Path line;
    if (m.isBinary) {
      line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        line
          ..lineTo(offsets[i].dx, offsets[i - 1].dy)
          ..lineTo(offsets[i].dx, offsets[i].dy);
      }
    } else {
      line = smoothPath(offsets);
    }
    final fill = Path.from(line)
      ..lineTo(offsets.last.dx, plot.bottom)
      ..lineTo(offsets.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [m.color.fade(0.5), m.color.fade(0.02)],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = m.deep,
    );

    // Minimum et maximum.
    if (!m.isBinary) {
      var iMin = 0;
      var iMax = 0;
      for (var i = 1; i < l.points.length; i++) {
        if (l.points[i].value < l.points[iMin].value) iMin = i;
        if (l.points[i].value > l.points[iMax].value) iMax = i;
      }
      for (final i in [iMin, iMax]) {
        final p = offsets[i];
        canvas.drawCircle(p, 4, Paint()..color = Palette.sheet);
        canvas.drawCircle(
          p,
          4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = m.deep,
        );
      }
    }

    // Dernier point.
    final last = offsets.last;
    canvas.drawCircle(last, 5, Paint()..color = Palette.sheet);
    canvas.drawCircle(last, 3.4, Paint()..color = m.deep);

    // Inspection.
    final s = selected;
    if (s != null && s >= 0 && s < offsets.length) {
      final p = offsets[s];
      canvas.drawLine(
        Offset(p.dx, plot.top - 6),
        Offset(p.dx, plot.bottom),
        Paint()
          ..color = Palette.ink.fade(0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 9, Paint()..color = m.color.fade(0.45));
      canvas.drawCircle(p, 5.5, Paint()..color = Palette.sheet);
      canvas.drawCircle(p, 3.6, Paint()..color = Palette.ink);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.selected != selected ||
      !identical(old.layout.points, layout.points) ||
      old.layout.size != layout.size ||
      old.layout.metric != layout.metric;
}
