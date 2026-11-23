import 'package:flutter/material.dart';

import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../shared/widgets/skeleton.dart';

/// État de chargement de la station, avant la première mesure.
class StationLoadingView extends StatelessWidget {
  const StationLoadingView(
      {super.key, required this.sceneHeight, required this.stationName});

  final double sceneHeight;
  final String stationName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Connexion à la station en cours',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ma station', style: AtmosText.label),
                const SizedBox(height: 6),
                Text(stationName, style: AtmosText.title),
                const SizedBox(height: 12),
                const Skeleton(width: 150, height: 22, radius: 11),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: sceneHeight,
              child: Stack(
                children: [
                  const Positioned.fill(child: Skeleton(radius: 36)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Palette.mintDeep),
                        ),
                        const SizedBox(height: 14),
                        Text('Connexion à la station…',
                            style: AtmosText.body.copyWith(color: Palette.ink)),
                        const SizedBox(height: 4),
                        const Text('Réception du dernier relevé',
                            style: AtmosText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 180, height: 14),
                SizedBox(height: 14),
                Skeleton(width: 220, height: 64, radius: 18),
                SizedBox(height: 14),
                Skeleton(height: 14),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Skeleton(height: 76, radius: 22)),
                    SizedBox(width: 10),
                    Expanded(child: Skeleton(height: 76, radius: 22)),
                    SizedBox(width: 10),
                    Expanded(child: Skeleton(height: 76, radius: 22)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
