import 'package:joga_10/model/Usuario.dart';

abstract interface class SessaoContract {
  Usuario? get atual;

  Future<int?> get usuarioId;

  Future<void> salvar(Usuario usuario);

  Future<bool> estaLogado();

  Future<Usuario?> restaurarLocal();

  Future<void> sair();
}
