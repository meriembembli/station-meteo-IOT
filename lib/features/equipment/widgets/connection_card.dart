import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/atmos_text.dart';
import '../../../core/theme/palette.dart';
import '../../../data/models/hardware.dart';
import '../../../data/models/snapshot.dart';
import '../../../shared/widgets/atmos_button.dart';
import '../../../shared/widgets/link_pill.dart';

/// État de la liaison station → base de données → application.
class ConnectionCard extends StatelessWidget {
  const ConnectionCard({
    super.key,
    required this.snapshot,
    required this.device,
    required this.isDemo,
    required this.syncing,
    required this.onSync,
  });

  final StationSnapshot snapshot;
  final DeviceInfo? device;
  final bool isDemo;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final link = snapshot.link;
    final rssi = device?.wifiRssi;
    final every = device?.transmitEvery;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('CONNEXION', style: AtmosText.overline),
                  const SizedBox(height: 8),
                  LinkPill(link: link),
                ],
              ),
              AtmosButton(
                label: syncing ? 'Synchronisation…' : 'Synchroniser',
                icon: Icons.sync,
                busy: syncing,
                compact: true,
                style: AtmosButtonStyle.quiet,
                onPressed: onSync,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Row(
            label: 'Dernière synchronisation',
            value:
                '${Fr.dateTime(snapshot.measuredAt)}\n${Fr.ago(snapshot.measuredAt, DateTime.now())}',
          ),
          _Row(
            label: 'Réseau',
            value: link == LinkStatus.offline || rssi == null
                ? 'Wi-Fi · signal indisponible'
                : 'Wi-Fi · $rssi dBm',
          ),
          _Row(
            label: 'Envoi des mesures',
            value: every == null
                ? '—'
                : 'Toutes les ${every.inSeconds} s${isDemo ? ' (simulé)' : ''}',
          ),
          _Row(
            label: 'Base de données',
            value: isDemo
                ? 'Firebase · non connectée (mode démo)'
                : 'Firebase Realtime Database',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border:
            last ? null : const Border(bottom: BorderSide(color: Palette.line)),
      ),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Text(label,
                    style: AtmosText.caption.copyWith(fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style:
                    AtmosText.label.copyWith(color: Palette.ink, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
