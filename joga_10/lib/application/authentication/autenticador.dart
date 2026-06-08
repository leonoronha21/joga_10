import 'package:joga_10/model/Usuario.dart';

abstract interface class Autenticador {
  bool aceita(String login);

  Future<Usuario?> autenticar(String login, String senha);
}
