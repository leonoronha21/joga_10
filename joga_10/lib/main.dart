import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:joga_10/app.dart';
import 'package:joga_10/core/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final dependencies = AppDependencies.local();
  runApp(
    AppDependenciesScope(
      dependencies: dependencies,
      child: JogaApp(dependencies: dependencies),
    ),
  );
}
