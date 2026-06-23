import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/repositories/postagem_repository.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

void main() {
  test('publica partida de vôlei como atividade social', () async {
    SharedPreferences.setMockInitialValues({});
    await Sessao.instance.salvar(
      Usuario(
        id: LocalDemoData.adminId,
        primeiroNome: 'Admin',
        email: 'admin',
        role: 'ADMIN',
      ),
    );
    final demo = LocalDemoData.instance;
    final partidaRepo = PartidaRepository();
    final postagemRepo = PostagemRepository();
    final partidaId = await partidaRepo.criar(
      idEstabelecimento: -103,
      idQuadra: -205,
      organizadorId: LocalDemoData.adminId,
      dataHora: DateTime(2026, 7, 10, 19),
      preco: 130,
      modalidade: ModalidadePartida.volei,
      formato: '2x2',
      membros: [
        PartidaMembro(equipe: Equipe.time1, nome: 'A'),
        PartidaMembro(equipe: Equipe.time2, nome: 'B'),
      ],
    );
    await partidaRepo.finalizarComPlacar(
      partidaId: partidaId,
      placarTime1: 2,
      placarTime2: 1,
      golsPorMembro: const {},
    );

    final postagemId = await postagemRepo.criar(
      autorId: LocalDemoData.adminId,
      partidaId: partidaId,
      visibilidade: VisibilidadePostagem.amigos,
    );
    final postagem = demo.postagens.firstWhere((item) => item.id == postagemId);

    expect(postagem.isAtividade, isTrue);
    expect(postagem.atividadeModalidade, ModalidadePartida.volei);
    expect(postagem.atividadePlacarEquipeA, 2);
    expect(postagem.atividadePlacarEquipeB, 1);
    expect(postagem.visibilidade, VisibilidadePostagem.amigos);

    demo.postagens.removeWhere((item) => item.id == postagemId);
    demo.partidas.removeWhere((item) => item.id == partidaId);
  });
}
