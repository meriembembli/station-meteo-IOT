import 'package:flutter/material.dart';

import 'palette.dart';

ThemeData buildAtmosTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.mint,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Palette.mint,
    onPrimary: Palette.paper,
    secondary: Palette.glacier,
    tertiary: Palette.apricot,
    surface: Palette.surface,
    onSurface: Palette.ink,
    onSurfaceVariant: Palette.inkSoft,
    outline: Palette.line,
    error: Palette.apricot,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    canvasColor: Palette.paper,
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: Palette.mint,
      inactiveTrackColor: Palette.surfaceHigh,
      thumbColor: Palette.ink,
      overlayColor: Palette.mint.fade(0.12),
      valueIndicatorColor: Palette.sheet,
      valueIndicatorTextStyle:
          const TextStyle(color: Palette.ink, fontWeight: FontWeight.w600),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.mint,
      selectionColor: Palette.mint.fade(0.3),
      selectionHandleColor: Palette.mint,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Palette.sheet,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.line),
      ),
      textStyle: const TextStyle(color: Palette.ink, fontSize: 12.5),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.sheet,
      contentTextStyle: const TextStyle(color: Palette.ink, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Palette.line),
      ),
    ),
  );
}
