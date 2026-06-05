import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Usuario.dart';

/// Resultado possível de um cadastro.
enum ResultadoCadastro { sucesso, emailJaExiste, erro }

class UsuarioRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  /// Autentica por email + senha. Retorna o [Usuario] ou null se inválido.
  Future<Usuario?> login(String email, String senha) async {
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('SELECT * FROM usuario WHERE email = @email'),
      parameters: {'email': email.trim().toLowerCase()},
    );
    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    final hash = row['senha_hash'] as String;
    if (!BCrypt.checkpw(senha, hash)) return null;

    return Usuario.fromRow(row);
  }

  /// Cadastra um novo usuário (senha guardada como hash BCrypt).
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
  }) async {
    final conn = await _conn;
    final emailNorm = email.trim().toLowerCase();

    final existe = await conn.execute(
      Sql.named('SELECT 1 FROM usuario WHERE email = @email'),
      parameters: {'email': emailNorm},
    );
    if (existe.isNotEmpty) return ResultadoCadastro.emailJaExiste;

    try {
      final hash = BCrypt.hashpw(senha, BCrypt.gensalt());
      await conn.execute(
        Sql.named('''
          INSERT INTO usuario
            (primeiro_nome, segundo_nome, email, senha_hash,
             cidade, bairro, rua, complemento, contato, role)
          VALUES
            (@primeiro_nome, @segundo_nome, @email, @senha_hash,
             @cidade, @bairro, @rua, @complemento, @contato, @role)
        '''),
        parameters: {
          'primeiro_nome': primeiroNome.trim(),
          'segundo_nome': segundoNome?.trim(),
          'email': emailNorm,
          'senha_hash': hash,
          'cidade': cidade?.trim(),
          'bairro': bairro?.trim(),
          'rua': rua?.trim(),
          'complemento': complemento?.trim(),
          'contato': contato?.trim(),
          'role': role,
        },
      );
      return ResultadoCadastro.sucesso;
    } catch (_) {
      return ResultadoCadastro.erro;
    }
  }

  /// Redefine a senha localmente (MVP sem servidor de email).
  /// Retorna true se o email existia e a senha foi atualizada.
  Future<bool> redefinirSenha(String email, String novaSenha) async {
    final conn = await _conn;
    final hash = BCrypt.hashpw(novaSenha, BCrypt.gensalt());
    final result = await conn.execute(
      Sql.named(
          'UPDATE usuario SET senha_hash = @hash WHERE email = @email'),
      parameters: {'hash': hash, 'email': email.trim().toLowerCase()},
    );
    return result.affectedRows > 0;
  }

  Future<Usuario?> buscarPorId(int id) async {
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('SELECT * FROM usuario WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Usuario.fromRow(result.first.toColumnMap());
  }

  Future<Usuario?> buscarPorEmail(String email) async {
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('SELECT * FROM usuario WHERE email = @email'),
      parameters: {'email': email.trim().toLowerCase()},
    );
    if (result.isEmpty) return null;
    return Usuario.fromRow(result.first.toColumnMap());
  }

  /// Atualiza os dados cadastrais (não mexe em email/senha aqui).
  Future<bool> atualizar({
    required int id,
    required String primeiroNome,
    String? segundoNome,
    String? cidade,
    String? bairro,
    String? rua,
    String? complemento,
    String? contato,
  }) async {
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('''
        UPDATE usuario SET
          primeiro_nome = @primeiro_nome,
          segundo_nome  = @segundo_nome,
          cidade        = @cidade,
          bairro        = @bairro,
          rua           = @rua,
          complemento   = @complemento,
          contato       = @contato
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'primeiro_nome': primeiroNome.trim(),
        'segundo_nome': segundoNome?.trim(),
        'cidade': cidade?.trim(),
        'bairro': bairro?.trim(),
        'rua': rua?.trim(),
        'complemento': complemento?.trim(),
        'contato': contato?.trim(),
      },
    );
    return result.affectedRows > 0;
  }
}
