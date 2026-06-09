import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/application/use_cases/participar_da_partida.dart';
import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/model/Usuario.dart';

void main() {
  group('ParticiparDaPartida', () {
    test('adiciona o usuario no time com menos jogadores', () async {
      final partidas = _PartidaRepositoryFake();
      final casoDeUso = ParticiparDaPartida(
        partidas: partidas,
        sessao: _SessaoFake(_usuario),
      );
      final partida = _partidaCom([
        PartidaMembro(partidaId: 1, equipe: Equipe.time1, nome: 'Um'),
      ]);

      final resultado = await casoDeUso.execute(partida);

      expect(resultado.resultado, ResultadoParticipacao.sucesso);
      expect(partidas.equipeAdicionada, Equipe.time2);
      expect(partidas.usuarioAdicionado, _usuario.id);
    });

    test('nao adiciona quem ja participa', () async {
      final partidas = _PartidaRepositoryFake();
      final casoDeUso = ParticiparDaPartida(
        partidas: partidas,
        sessao: _SessaoFake(_usuario),
      );
      final partida = _partidaCom([
        PartidaMembro(
          partidaId: 1,
          idUser: _usuario.id,
          equipe: Equipe.time1,
          nome: _usuario.nomeCompleto,
        ),
      ]);

      final resultado = await casoDeUso.execute(partida);

      expect(resultado.resultado, ResultadoParticipacao.jaParticipa);
      expect(partidas.equipeAdicionada, isNull);
    });
  });
}

final _usuario = Usuario(
  id: 7,
  primeiroNome: 'Usuario',
  segundoNome: 'Teste',
  email: 'usuario@teste.com',
);

Partida _partidaCom(List<PartidaMembro> membros) {
  return Partida(
    id: 1,
    organizadorId: 99,
    dataHora: DateTime(2026, 6, 8),
    status: PartidaStatus.agendada,
    preco: 100,
    membros: membros,
  );
}

class _PartidaRepositoryFake implements PartidaRepositoryContract {
  String? equipeAdicionada;
  int? usuarioAdicionado;

  @override
  Future<void> adicionarMembro({
    required int partidaId,
    int? idUser,
    required String equipe,
    required String nome,
    String? telefone,
  }) async {
    equipeAdicionada = equipe;
    usuarioAdicionado = idUser;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessaoFake implements SessaoContract {
  _SessaoFake(this.atual);

  @override
  Usuario? atual;

  @override
  Future<bool> estaLogado() async => atual != null;

  @override
  Future<Usuario?> restaurarLocal() async => atual;

  @override
  Future<void> sair() async => atual = null;

  @override
  Future<void> salvar(Usuario usuario) async => atual = usuario;

  @override
  Future<int?> get usuarioId async => atual?.id;
}
