import 'package:joga_10/application/authentication/autenticador.dart';
import 'package:joga_10/model/Usuario.dart';

class AutenticadorAdminLocal implements Autenticador {
  final String login;
  final String senha;

  const AutenticadorAdminLocal({
    this.login = 'admin',
    this.senha = '123',
  });

  @override
  bool aceita(String login) => login.trim().toLowerCase() == this.login;

  @override
  Future<Usuario?> autenticar(String login, String senha) async {
    if (senha != this.senha) return null;
    return Usuario(
      id: 0,
      primeiroNome: 'Admin',
      segundoNome: 'Local',
      email: this.login,
      role: 'ADMIN',
    );
  }
}
