import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';
import '../../data/models/snapshot.dart';

Color linkColor(LinkStatus link) => switch (link) {
      LinkStatus.online => Palette.online,
      LinkStatus.stale => Palette.apricotDeep,
      LinkStatus.offline => Palette.inkMuted,
    };

/// Pastille d'état de connexion.
class LinkPill extends StatelessWidget {
  const LinkPill({super.key, required this.link});

  final LinkStatus link;

  @override
  Widget build(BuildContext context) {
    final color = linkColor(link);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: color.fade(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: link == LinkStatus.online
                  ? [BoxShadow(color: color.fade(0.5), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              link.label,
              style: AtmosText.label.copyWith(color: color, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Reçu il y a 8 s », mis à jour chaque seconde sans reconstruire l'écran.
class ReceivedAgo extends StatefulWidget {
  const ReceivedAgo(
      {super.key, required this.at, this.prefix = 'Reçu', this.style});

  final DateTime at;
  final String prefix;
  final TextStyle? style;

  @override
  State<ReceivedAgo> createState() => _ReceivedAgoState();
}

class _ReceivedAgoState extends State<ReceivedAgo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix} ${Fr.ago(widget.at, DateTime.now())}',
      style: widget.style ?? AtmosText.caption,
    );
  }
}
