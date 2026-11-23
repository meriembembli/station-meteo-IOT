import 'package:flutter/widgets.dart';

import 'atmos_controller.dart';

/// Expose [AtmosController] à l'arbre de widgets, sans dépendance externe.
class AtmosScope extends InheritedNotifier<AtmosController> {
  const AtmosScope({
    super.key,
    required AtmosController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Lecture avec abonnement aux changements.
  static AtmosController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AtmosScope>();
    assert(scope != null, 'AtmosScope introuvable dans l’arbre.');
    return scope!.notifier!;
  }

  /// Lecture ponctuelle (callbacks), sans abonnement.
  static AtmosController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AtmosScope>();
    assert(scope != null, 'AtmosScope introuvable dans l’arbre.');
    return scope!.notifier!;
  }
}
