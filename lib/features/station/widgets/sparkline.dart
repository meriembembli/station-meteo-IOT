import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/history.dart';
import '../../../data/models/metric.dart';
import '../../../shared/painting/smooth_path.dart';

/// Petite courbe des dernières 24 h, affichée à côté de la valeur.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.metric,
    required this.points,
    this.width = 116,
    this.height = 54,
  });

  final MetricKind metric;
  final List<HistoryPoint>? points;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pts = points;
    return Semantics(
      label: 'Tendance de ${metric.withArticle} sur 24 heures',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: pts == null
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.6, color: Palette.inkMuted),
                    ),
                  )
                : pts.length < 2
                    ? const Center(child: Text('—', style: AtmosText.caption))
                    : CustomPaint(painter: _SparkPainter(metric, pts)),
          ),
          const SizedBox(height: 4),
          Text('24 h', style: AtmosText.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.metric, this.points);

  final MetricKind metric;
  final List<HistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Sous-échantillonnage léger pour une courbe calme.
    final int step = points.length > 40 ? (points.length / 40).ceil() : 1;
    final sampled = <double>[
      for (var i = 0; i < points.length; i += step) points[i].value,
    ];
    if (sampled.length < 2) return;
    sampled[sampled.length - 1] = points.last.value;

    var lo = sampled.reduce((a, b) => a < b ? a : b);
    var hi = sampled.reduce((a, b) => a > b ? a : b);
    if (metric.isBinary) {
      lo = 0;
      hi = 1;
    }
    if ((hi - lo).abs() < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    const pad = 4.0;
    final h = size.height - pad * 2;
    final offsets = <Offset>[
      for (var i = 0; i < sampled.length; i++)
        Offset(
          size.width * i / (sampled.length - 1),
          pad + h - (sampled[i] - lo) / (hi - lo) * h,
        ),
    ];

    final Path line;
    if (metric.isBinary) {
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
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [metric.color.fade(0.45), metric.color.fade(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = metric.deep,
    );
    final last = offsets.last;
    canvas.drawCircle(last, 4.2, Paint()..color = Palette.sheet);
    canvas.drawCircle(last, 2.8, Paint()..color = metric.deep);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.metric != metric || !identical(old.points, points);
}
