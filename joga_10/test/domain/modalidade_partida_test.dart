import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/model/Partida.dart';

void main() {
  test('vôlei usa formatos e capacidades próprias', () {
    final voleiPraia = Partida(
      id: 1,
      organizadorId: 1,
      dataHora: DateTime(2026, 7, 1),
      status: PartidaStatus.agendada,
      preco: 100,
      modalidade: ModalidadePartida.volei,
      formato: '2x2',
    );
    final voleiQuadra = Partida(
      id: 2,
      organizadorId: 1,
      dataHora: DateTime(2026, 7, 1),
      status: PartidaStatus.agendada,
      preco: 100,
      modalidade: ModalidadePartida.volei,
      formato: '6x6',
    );

    expect(voleiPraia.isVolei, isTrue);
    expect(voleiPraia.jogadoresPorTime, 2);
    expect(voleiQuadra.jogadoresPorTime, 6);
    expect(voleiQuadra.unidadePlacar, 'sets');
  });

  test('futebol de campo suporta onze jogadores por equipe', () {
    final partida = Partida(
      id: 3,
      organizadorId: 1,
      dataHora: DateTime(2026, 7, 1),
      status: PartidaStatus.agendada,
      preco: 0,
      formato: '11x11',
    );

    expect(partida.jogadoresPorTime, 11);
  });
}
