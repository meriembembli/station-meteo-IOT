import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'features/auth/firebase_root.dart';
import 'firebase_options.dart';

/// Source des données, choisie au lancement :
///
///   flutter run                                      → mode démo (simulé)
///   flutter run --dart-define=ATMOS_BACKEND=firebase → station réelle
const _backend = String.fromEnvironment('ATMOS_BACKEND', defaultValue: 'demo');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  if (_backend == 'firebase') {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    runApp(const FirebaseRoot());
  } else {
    runApp(const AtmosApp());
  }
}
