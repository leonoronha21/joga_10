import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/domain/services/recorrencia_partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/services/local_demo_data.dart';

void main() {
  test('cria todas as ocorrências com os participantes pré-cadastrados',
      () async {
    final demo = LocalDemoData.instance;
    final repo = PartidaRepository();
    final inicio = DateTime(2026, 7, 1, 19);
    final membros = <PartidaMembro>[
      PartidaMembro(
        idUser: LocalDemoData.adminId,
        equipe: Equipe.time1,
        nome: 'Organizador',
      ),
      PartidaMembro(
        equipe: Equipe.time2,
        nome: 'Convidado',
        telefone: '51999999999',
      ),
    ];

    final primeiraId = await repo.criar(
      idEstabelecimento: demo.estabelecimentos.first.id,
      idQuadra: demo.quadras.first.id,
      organizadorId: LocalDemoData.adminId,
      dataHora: inicio,
      preco: 120,
      membros: membros,
      recorrencia: TipoRecorrenciaPartida.semanal,
      recorrenciaAte: inicio.add(const Duration(days: 14)),
    );

    final primeira = demo.buscarPartida(primeiraId)!;
    final serie = demo.partidas
        .where(
            (partida) => partida.grupoRecorrencia == primeira.grupoRecorrencia)
        .toList();

    expect(serie, hasLength(3));
    expect(serie.every((partida) => partida.membros.length == 2), isTrue);
    expect(
      serie.every(
        (partida) => partida.membros.any(
          (membro) =>
              membro.nome == 'Convidado' && membro.telefone == '51999999999',
        ),
      ),
      isTrue,
    );

    demo.partidas.removeWhere(
      (partida) => partida.grupoRecorrencia == primeira.grupoRecorrencia,
    );
  });
}
