import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/pages/amigos_page.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_theme.dart';

void main() {
  testWidgets('lista amigos e permite encontrar perfis do app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Sessao.instance.salvar(
      Usuario(
        id: 0,
        primeiroNome: 'Admin',
        email: 'admin',
        role: 'ADMIN',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AmigosPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Amigos ('), findsOneWidget);
    expect(find.text('Bruno Silva'), findsOneWidget);

    await tester.tap(find.text('Encontrar pessoas'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar perfis existentes no Joga10'), findsOneWidget);
    expect(find.text('Adicionar'), findsWidgets);
  });
}
