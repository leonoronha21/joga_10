import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joga_10/pages/sobre_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Joga 10',
      packageName: 'br.com.joga10.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('exibe descricao do app e versao instalada', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SobrePage()));
    await tester.pump();

    expect(find.text('Sobre o Joga 10'), findsOneWidget);
    expect(
      find.textContaining('conectar jogadores, organizadores e locais'),
      findsOneWidget,
    );
    expect(find.text('1.0.0+1'), findsOneWidget);
    expect(find.text('br.com.joga10.app'), findsOneWidget);
  });
}
