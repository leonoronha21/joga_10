import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

void main() {
  test('partidas públicas são descobertas e privadas só por convidados',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Sessao.instance.salvar(
      Usuario(
        id: LocalDemoData.adminId,
        primeiroNome: 'Admin',
        email: 'admin',
        role: 'ADMIN',
      ),
    );
    final repo = PartidaRepository();
    final publicaId = await repo.criar(
      organizadorId: LocalDemoData.adminId,
      dataHora: DateTime(2026, 8, 1, 19),
      preco: 0,
      visibilidade: VisibilidadePartida.publica,
    );
    final privadaId = await repo.criar(
      organizadorId: LocalDemoData.adminId,
      dataHora: DateTime(2026, 8, 2, 19),
      preco: 0,
      visibilidade: VisibilidadePartida.privada,
      membros: [
        PartidaMembro(
          idUser: 77,
          equipe: Equipe.time1,
          nome: 'Convidado',
        ),
      ],
    );

    final publicas = await repo.listarPublicas();
    expect(publicas.any((partida) => partida.id == publicaId), isTrue);
    expect(publicas.any((partida) => partida.id == privadaId), isFalse);

    await Sessao.instance.salvar(
      Usuario(
        id: 88,
        primeiroNome: 'Não convidado',
        email: 'nao@convidado.com',
      ),
    );
    expect(await repo.buscarPorId(privadaId), isNull);

    await Sessao.instance.salvar(
      Usuario(
        id: 77,
        primeiroNome: 'Convidado',
        email: 'convidado@teste.com',
      ),
    );
    expect(await repo.buscarPorId(privadaId), isNotNull);

    LocalDemoData.instance.partidas.removeWhere(
      (partida) => partida.id == publicaId || partida.id == privadaId,
    );
  });
}
