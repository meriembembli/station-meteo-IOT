import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/snapshot.dart';

/// Bandeau affiché lorsque les données ne sont plus en direct.
/// Les dernières mesures restent visibles, avec leur horodatage.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.snapshot});

  final StationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.isLive) return const SizedBox.shrink();
    final offline = snapshot.link == LinkStatus.offline;
    final when = Fr.dateTime(snapshot.measuredAt);
    final ago = Fr.ago(snapshot.measuredAt, DateTime.now());
    final tint = offline ? Palette.inkMuted : Palette.apricotDeep;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: offline ? Palette.paperDeep : Palette.apricotSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tint.fade(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.schedule_rounded,
              color: tint,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offline ? 'Station hors ligne' : 'Données anciennes',
                    style: AtmosText.heading.copyWith(fontSize: 15.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offline
                        ? 'Dernières mesures conservées, reçues le $when ($ago).'
                        : 'Aucune nouvelle mesure depuis le $when ($ago). '
                            'Les valeurs peuvent ne plus refléter la situation.',
                    style: AtmosText.body.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
