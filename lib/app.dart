import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/atmos_theme.dart';
import 'data/repositories/demo_station_repository.dart';
import 'data/repositories/station_repository.dart';
import 'features/shell/atmos_shell.dart';
import 'state/atmos_controller.dart';
import 'state/atmos_scope.dart';

/// Thème, langue et réglages communs à toutes les applications ATMOS
/// (application principale et écran de connexion).
MaterialApp buildAtmosMaterialApp({required Widget home}) => MaterialApp(
      title: 'ATMOS',
      debugShowCheckedModeBanner: false,
      theme: buildAtmosTheme(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );

class AtmosApp extends StatefulWidget {
  const AtmosApp({
    super.key,
    this.repository,
    this.signOut,
    this.accountEmail,
  });

  /// Source de données : [DemoStationRepository] par défaut,
  /// `FirebaseStationRepository` pour la station réelle.
  final StationRepository? repository;

  /// Déconnexion (mode Firebase uniquement).
  final Future<void> Function()? signOut;
  final String? accountEmail;

  @override
  State<AtmosApp> createState() => _AtmosAppState();
}

class _AtmosAppState extends State<AtmosApp> {
  late final AtmosController _controller = AtmosController(
    widget.repository ?? DemoStationRepository(),
    signOut: widget.signOut,
    accountEmail: widget.accountEmail,
  )..start();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AtmosScope(
      controller: _controller,
      child: buildAtmosMaterialApp(home: const AtmosShell()),
    );
  }
}
