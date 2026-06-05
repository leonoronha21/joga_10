// Smoke test básico do app Joga 10.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/theme/app_theme.dart';

void main() {
  testWidgets('Tema do app é aplicado', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: Text('Joga 10'))),
      ),
    );

    expect(find.text('Joga 10'), findsOneWidget);
  });
}
