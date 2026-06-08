import 'package:joga_10/application/authentication/autenticador.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Usuario.dart';

class AutenticarUsuario {
  final List<Autenticador> autenticadores;
  final SessaoContract sessao;

  const AutenticarUsuario({
    required this.autenticadores,
    required this.sessao,
  });

  Future<Usuario?> execute(String login, String senha) async {
    final loginNormalizado = login.trim().toLowerCase();
    final autenticador = autenticadores.firstWhere(
      (item) => item.aceita(loginNormalizado),
    );
    final usuario = await autenticador.autenticar(loginNormalizado, senha);
    if (usuario != null) await sessao.salvar(usuario);
    return usuario;
  }
}
