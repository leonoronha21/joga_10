import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/pages/feed_page.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_theme.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('feed exibe atividades, aplausos e filtro social',
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
        home: const FeedPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atividades'), findsOneWidget);
    expect(find.textContaining('aplausos'), findsWidgets);
    await tester.tap(find.text('Atividades'));
    await tester.pumpAndSettle();
    final volei = find.textContaining('Vôlei concluído');
    await tester.scrollUntilVisible(
      volei.first,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(volei, findsWidgets);
    expect(find.byIcon(Icons.sports_volleyball), findsWidgets);
  });
}
