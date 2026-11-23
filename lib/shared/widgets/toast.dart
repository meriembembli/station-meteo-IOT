import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'floating_nav_bar.dart';

/// Message bref affiché au-dessus de la barre de navigation flottante.
void showToast(BuildContext context, String message, {IconData? icon}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        margin: EdgeInsets.fromLTRB(20, 0, 20, navClearance(context) - 8),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon ?? Icons.check_circle_outline,
                color: Palette.mint, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
