import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// Feuille de détails ATMOS : coins généreux, poignée, défilement interne,
/// respect du clavier et des zones de sécurité.
Future<T?> showAtmosSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Palette.shadow.fade(0.6),
    elevation: 0,
    builder: (sheetContext) => _SheetFrame(child: builder(sheetContext)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: Palette.sheet,
          border: Border.all(color: Palette.line),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Palette.shadow.fade(0.5),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
