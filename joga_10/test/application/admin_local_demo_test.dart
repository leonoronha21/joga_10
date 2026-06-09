import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/repositories/monetizacao_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/repositories/postagem_repository.dart';
import 'package:joga_10/services/sessao.dart';

void main() {
  test('admin local carrega dados ficticios sem depender do banco', () async {
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

    final partidas = await PartidaRepository().listarPorUsuario(0);
    final locais = await EstabelecimentoRepository().listarTodos();
    final feed = await PostagemRepository().listarFeed(0);
    final ligas = await CampeonatoRepository().listarLigas();
    final rateio =
        await MonetizacaoRepository().buscarRateioPorPartida(partidas.first.id);

    expect(partidas, isNotEmpty);
    expect(locais, isNotEmpty);
    expect(feed, isNotEmpty);
    expect(ligas, isNotEmpty);
    expect(rateio, isNotNull);
  });

  test('convidados locais podem ser escalados e registrar gols', () async {
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

    final repo = PartidaRepository();
    final partidaId = await repo.criar(
      organizadorId: 0,
      dataHora: DateTime.now().add(const Duration(days: 1)),
      preco: 0,
      membros: [
        PartidaMembro(
          equipe: Equipe.time1,
          nome: 'Contato Time 1',
          telefone: '11999990001',
        ),
        PartidaMembro(
          equipe: Equipe.time2,
          nome: 'Contato Time 2',
          telefone: '11999990002',
        ),
      ],
    );

    var partida = await repo.buscarPorId(partidaId);
    expect(partida, isNotNull);
    expect(partida!.membros, hasLength(2));
    expect(partida.membros.every((membro) => membro.id != null), isTrue);
    expect(
      partida.membros.every((membro) => membro.partidaId == partidaId),
      isTrue,
    );

    final escalados = [
      partida.membros[0].copyWith(posX: 0.3, posY: 0.4),
      partida.membros[1].copyWith(posX: 0.7, posY: 0.6),
    ];
    await repo.salvarEscalacao(
      partidaId: partidaId,
      formato: '5x5',
      formacaoTime1: '2-2',
      formacaoTime2: '2-2',
      membros: escalados,
    );

    partida = await repo.buscarPorId(partidaId);
    expect(partida!.membros.every((membro) => membro.posicionado), isTrue);

    final primeiroMembroId = partida.membros.first.id!;
    await repo.finalizarComPlacar(
      partidaId: partidaId,
      placarTime1: 1,
      placarTime2: 0,
      golsPorMembro: {primeiroMembroId: 1},
    );

    partida = await repo.buscarPorId(partidaId);
    expect(partida!.status, PartidaStatus.finalizada);
    expect(partida.placarTime1, 1);
    expect(partida.placarTime2, 0);
    expect(
      partida.membros
          .firstWhere((membro) => membro.id == primeiroMembroId)
          .gols,
      1,
    );
  });
}
