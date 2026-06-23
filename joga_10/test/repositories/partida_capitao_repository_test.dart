import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

void main() {
  test('criador define capitão e capitão altera somente o próprio time',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Sessao.instance.salvar(_usuario(0, 'Criador'));
    final repo = PartidaRepository();
    final partidaId = await repo.criar(
      organizadorId: 0,
      dataHora: DateTime(2026, 8, 10, 20),
      preco: 0,
      membros: [
        PartidaMembro(
          idUser: -11,
          equipe: Equipe.time1,
          nome: 'Capitão A',
        ),
        PartidaMembro(
          idUser: -12,
          equipe: Equipe.time1,
          nome: 'Jogador A',
        ),
        PartidaMembro(
          idUser: -13,
          equipe: Equipe.time2,
          nome: 'Jogador B',
        ),
      ],
    );

    var partida = (await repo.buscarPorId(partidaId))!;
    final capitao =
        partida.membros.firstWhere((membro) => membro.idUser == -11);
    await repo.definirCapitao(
      partidaId: partidaId,
      equipe: Equipe.time1,
      membroId: capitao.id!,
    );

    partida = (await repo.buscarPorId(partidaId))!;
    expect(partida.capitaoDoTime(Equipe.time1)?.idUser, -11);

    await Sessao.instance.salvar(_usuario(-11, 'Capitão A'));
    final time1 = partida.time1
        .map((membro) => membro.copyWith(posX: 0.4, posY: 0.5))
        .toList();
    await repo.salvarEscalacao(
      partidaId: partidaId,
      formato: partida.formato,
      formacaoTime1: '2-2',
      formacaoTime2: partida.formacaoTime2,
      membros: time1,
      equipeEditada: Equipe.time1,
    );

    partida = (await repo.buscarPorId(partidaId))!;
    expect(partida.time1.every((membro) => membro.posicionado), isTrue);
    expect(partida.time2.every((membro) => !membro.posicionado), isTrue);

    await expectLater(
      repo.salvarEscalacao(
        partidaId: partidaId,
        formato: partida.formato,
        formacaoTime1: partida.formacaoTime1,
        formacaoTime2: '2-2',
        membros: partida.time2,
        equipeEditada: Equipe.time2,
      ),
      throwsA(isA<StateError>()),
    );

    LocalDemoData.instance.partidas.removeWhere((item) => item.id == partidaId);
  });
}

Usuario _usuario(int id, String nome) {
  return Usuario(
    id: id,
    primeiroNome: nome,
    email: '$id@teste.com',
    role: id == 0 ? 'ADMIN' : 'USER',
  );
}
