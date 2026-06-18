import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/pages/escalacao_page.dart';
import 'package:joga_10/theme/app_theme.dart';

void main() {
  testWidgets('escalação de vôlei exibe quadra visual e formatos próprios',
      (tester) async {
    final partida = Partida(
      id: -1,
      organizadorId: 0,
      dataHora: DateTime(2026, 7, 1),
      status: PartidaStatus.agendada,
      preco: 0,
      modalidade: ModalidadePartida.volei,
      formato: '6x6',
      membros: [
        PartidaMembro(
          id: -10,
          equipe: Equipe.time1,
          nome: 'Jogadora A',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EscalacaoPage(partida: partida),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Quadra de vôlei'), findsOneWidget);
    expect(find.text('2x2'), findsOneWidget);
    expect(find.text('6x6'), findsOneWidget);
    expect(find.text('3-3'), findsOneWidget);
  });
}
