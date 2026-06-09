import 'package:joga_10/model/Usuario.dart';

abstract interface class AutenticacaoFirebaseContract {
  bool get autenticado;

  Future<Usuario?> entrarComGoogle();

  Future<void> sair();
}
