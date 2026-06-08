import 'package:joga_10/application/authentication/autenticador.dart';
import 'package:joga_10/domain/contracts/usuario_repository_contract.dart';
import 'package:joga_10/model/Usuario.dart';

class AutenticadorRepositorio implements Autenticador {
  final UsuarioRepositoryContract usuarios;

  const AutenticadorRepositorio(this.usuarios);

  @override
  bool aceita(String login) => true;

  @override
  Future<Usuario?> autenticar(String login, String senha) {
    return usuarios.login(login, senha);
  }
}
