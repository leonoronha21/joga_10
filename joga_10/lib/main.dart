import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:joga_10/app.dart';
import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _inicializarFirebase();
  await initializeDateFormatting('pt_BR', null);
  final dependencies = AppDependencies.local();
  runApp(
    AppDependenciesScope(
      dependencies: dependencies,
      child: JogaApp(dependencies: dependencies),
    ),
  );
}

Future<void> _inicializarFirebase() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) return;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
