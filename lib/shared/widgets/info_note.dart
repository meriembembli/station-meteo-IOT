import 'package:flutter/material.dart';

import '../../core/theme/atmos_text.dart';
import '../../core/theme/palette.dart';

/// Note discrète avec icône (information, limite de la démo…).
class InfoNote extends StatelessWidget {
  const InfoNote(
      {super.key, required this.icon, required this.text, this.tint});

  final IconData icon;
  final String text;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Palette.inkMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.fade(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AtmosText.caption
                  .copyWith(color: Palette.inkSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
