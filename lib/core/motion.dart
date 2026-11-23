import 'package:flutter/widgets.dart';

/// Durées d'animation qui respectent le réglage système
/// « Réduire les animations ».
abstract final class Motion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, int milliseconds) =>
      reduced(context) ? Duration.zero : Duration(milliseconds: milliseconds);

  static const Curve curve = Curves.easeOutCubic;
}
