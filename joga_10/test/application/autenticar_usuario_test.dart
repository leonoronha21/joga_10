import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/application/authentication/autenticador.dart';
import 'package:joga_10/application/authentication/autenticador_admin_local.dart';
import 'package:joga_10/application/use_cases/autenticar_usuario.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Usuario.dart';

void main() {
  group('AutenticarUsuario', () {
    test('usa o provedor local e salva a sessao', () async {
      final sessao = _SessaoFake();
      final casoDeUso = AutenticarUsuario(
        autenticadores: [const AutenticadorAdminLocal()],
        sessao: sessao,
      );

      final usuario = await casoDeUso.execute(' ADMIN ', '123');

      expect(usuario?.email, 'admin');
      expect(sessao.atual, same(usuario));
    });

    test('nao cria sessao quando as credenciais sao invalidas', () async {
      final sessao = _SessaoFake();
      final casoDeUso = AutenticarUsuario(
        autenticadores: [const AutenticadorAdminLocal()],
        sessao: sessao,
      );

      final usuario = await casoDeUso.execute('admin', 'senha-errada');

      expect(usuario, isNull);
      expect(sessao.atual, isNull);
    });

    test('permite adicionar outro provedor sem alterar o caso de uso',
        () async {
      final sessao = _SessaoFake();
      final casoDeUso = AutenticarUsuario(
        autenticadores: [
          const AutenticadorAdminLocal(),
          _AutenticadorSempreValido(),
        ],
        sessao: sessao,
      );

      final usuario = await casoDeUso.execute('jogador@teste.com', '123');

      expect(usuario?.email, 'jogador@teste.com');
      expect(sessao.atual, same(usuario));
    });
  });
}

class _AutenticadorSempreValido implements Autenticador {
  @override
  bool aceita(String login) => true;

  @override
  Future<Usuario?> autenticar(String login, String senha) async {
    return Usuario(id: 10, primeiroNome: 'Jogador', email: login);
  }
}

class _SessaoFake implements SessaoContract {
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
