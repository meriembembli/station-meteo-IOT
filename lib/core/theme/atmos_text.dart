import 'package:flutter/painting.dart';

import 'palette.dart';

/// Échelle typographique ATMOS : grands chiffres fins, titres serrés,
/// chiffres tabulaires pour éviter les sauts lors des mises à jour.
abstract final class AtmosText {
  static const _tabular = [FontFeature.tabularFigures()];

  static const overline = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: Palette.inkMuted,
    height: 1.2,
  );

  static const title = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
    color: Palette.ink,
    height: 1.12,
  );

  static const heading = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: Palette.ink,
    height: 1.25,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Palette.inkSoft,
    height: 1.42,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Palette.inkSoft,
    height: 1.2,
  );

  static const caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: Palette.inkMuted,
    height: 1.35,
  );

  static TextStyle display(double size, {Color color = Palette.ink}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w300,
        letterSpacing: -size * 0.045,
        height: 1.0,
        color: color,
        fontFeatures: _tabular,
      );

  static TextStyle number(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = Palette.ink,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -size * 0.02,
        height: 1.1,
        color: color,
        fontFeatures: _tabular,
      );
}
