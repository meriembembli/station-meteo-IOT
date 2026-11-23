import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/repositories/firebase_station_repository.dart';
import 'login_screen.dart';

/// Racine en mode Firebase : écran de connexion tant que l'utilisateur
/// n'est pas authentifié, puis l'application branchée sur la vraie station.
class FirebaseRoot extends StatelessWidget {
  const FirebaseRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return buildAtmosMaterialApp(home: const LoginScreen(checking: true));
        }
        if (user == null) {
          return buildAtmosMaterialApp(home: const LoginScreen());
        }
        return AtmosApp(
          key: ValueKey(user.uid),
          repository: FirebaseStationRepository(),
          accountEmail: user.email,
          signOut: () => FirebaseAuth.instance.signOut(),
        );
      },
    );
  }
}
