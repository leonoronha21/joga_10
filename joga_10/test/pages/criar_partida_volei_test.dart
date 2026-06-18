import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/pages/criar_partida_page.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_theme.dart';

void main() {
  testWidgets('criação de partida permite selecionar vôlei 6x6 ou 2x2',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Sessao.instance.salvar(
      Usuario(
        id: 0,
        primeiroNome: 'Admin',
        segundoNome: 'Local',
        email: 'admin',
        role: 'ADMIN',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const CriarPartidaPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quadra'), findsNothing);
    expect(find.text('Pública'), findsOneWidget);
    expect(find.text('Privada'), findsOneWidget);
    expect(find.byIcon(Icons.sports_volleyball), findsWidgets);
    final estabelecimento = find.byKey(const Key('estabelecimentoDropdown'));
    await tester.scrollUntilVisible(
      estabelecimento,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(estabelecimento);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arena Joga10 Moinhos').last);
    await tester.pumpAndSettle();
    expect(find.text('Validar local no Google Maps'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('11x11'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('11x11'), findsOneWidget);
    final volei = find.byKey(const Key('modalidadeVolei'));
    await tester.scrollUntilVisible(
      volei,
      -260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(volei);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('6x6'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('6x6'), findsOneWidget);
    expect(find.text('2x2'), findsOneWidget);
  });
}
