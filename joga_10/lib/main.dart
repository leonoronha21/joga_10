import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:joga_10/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const JogaApp());
}
