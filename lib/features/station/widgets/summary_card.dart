import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/metric.dart';
import '../../../data/models/snapshot.dart';

/// Phrase de synthèse construite uniquement à partir des mesures réelles.
String buildSummary(StationSnapshot s) {
  final temp = s.temperature < 3
      ? 'Air très froid'
      : s.temperature < 12
          ? 'Air frais'
          : s.temperature < 26
              ? 'Air doux'
              : 'Air chaud';
  final hum = s.humidity < 40
      ? 'sec'
      : s.humidity < 70
          ? 'modérément humide'
          : 'très humide';
  final press = s.pressure < 1000
      ? 'pression basse'
      : s.pressure <= 1022
          ? 'pression proche de la normale'
          : 'pression élevée';
  final light = s.light < 15
      ? 'faible luminosité'
      : s.light < 50
          ? 'lumière tamisée'
          : 'bonne luminosité';
  final rain =
      s.rainDetected ? 'Pluie détectée sur le capteur.' : 'Pas de pluie.';
  final parts = <String>[
    '$temp et $hum',
    if (MetricKind.pressure.isActive) press,
    if (MetricKind.light.isActive) light,
  ];
  final sentence = '${parts.join(', ')}.';
  return MetricKind.rain.isActive ? '$sentence $rain' : sentence;
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.snapshot});

  final StationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('SYNTHÈSE', style: AtmosText.overline)),
              Text(
                'Relevé de ${Fr.time(snapshot.measuredAt)}',
                style: AtmosText.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            buildSummary(snapshot),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Palette.ink,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
