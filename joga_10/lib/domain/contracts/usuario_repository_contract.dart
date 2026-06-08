import 'dart:typed_data';

import 'package:joga_10/model/Usuario.dart';

enum ResultadoCadastro { sucesso, emailJaExiste, erro }

abstract interface class UsuarioRepositoryContract {
  Future<Usuario?> login(String email, String senha);

  Future<ResultadoCadastro> cadastrar({
    required String primeiroNome,
    String? segundoNome,
    required String email,
    required String senha,
    String? cidade,
    String? bairro,
    String? rua,
    String? complemento,
    String? contato,
    String role = 'USER',
  });

  Future<bool> redefinirSenha(String email, String novaSenha);

  Future<Usuario?> buscarPorId(int id);

  Future<Usuario?> buscarPorEmail(String email);

  Future<bool> atualizar({
    required int id,
    required String primeiroNome,
    String? segundoNome,
    String? cidade,
    String? bairro,
    String? rua,
    String? complemento,
    String? contato,
  });

  Future<void> salvarFoto(
    int id,
    Uint8List foto, {
    bool verificada = false,
  });

  Future<Uint8List?> buscarFoto(int id);
}
