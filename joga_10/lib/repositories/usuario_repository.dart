import 'dart:typed_data';

import 'package:bcrypt/bcrypt.dart';
// 'Type' colide com postgres (usado em TypedValue) — escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/domain/contracts/usuario_repository_contract.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';

/// Resultado possível de um cadastro.
class UsuarioRepository implements UsuarioRepositoryContract {
  final DatabaseProvider _database;

  UsuarioRepository({DatabaseProvider? database})
      : _database = database ?? AppDatabase.instance;

  Future<Pool> get _conn => _database.connection;

  /// Autentica por email + senha. Retorna o [Usuario] ou null se inválido.
  @override
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
  @override
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
  @override
  Future<bool> redefinirSenha(String email, String novaSenha) async {
    final conn = await _conn;
    final hash = BCrypt.hashpw(novaSenha, BCrypt.gensalt());
    final result = await conn.execute(
      Sql.named('UPDATE usuario SET senha_hash = @hash WHERE email = @email'),
      parameters: {'hash': hash, 'email': email.trim().toLowerCase()},
    );
    return result.affectedRows > 0;
  }

  @override
  Future<Usuario?> buscarPorId(int id) async {
    if (id <= 0) {
      return LocalDemoData.instance.usuarios
          .where((u) => u.id == id)
          .firstOrNull;
    }
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('SELECT * FROM usuario WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Usuario.fromRow(result.first.toColumnMap());
  }

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    if (email.trim().toLowerCase() == 'admin') {
      return LocalDemoData.instance.usuarios.first;
    }
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('SELECT * FROM usuario WHERE email = @email'),
      parameters: {'email': email.trim().toLowerCase()},
    );
    if (result.isEmpty) return null;
    return Usuario.fromRow(result.first.toColumnMap());
  }

  /// Atualiza os dados cadastrais (não mexe em email/senha aqui).
  @override
  Future<bool> atualizar({
    required int id,
    required String primeiroNome,
    String? segundoNome,
    String? cep,
    String? cidade,
    String? bairro,
    String? rua,
    String? numero,
    String? complemento,
    String? contato,
  }) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return false;
      final nomeCompleto = [primeiroNome.trim(), (segundoNome ?? '').trim()]
          .where((p) => p.isNotEmpty)
          .join(' ');
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(
        firestore.collection('usuarios').doc(uid),
        {
          'firebaseUid': uid,
          'primeiroNome': primeiroNome.trim(),
          'segundoNome': segundoNome?.trim(),
          'nomeCompleto': nomeCompleto,
          'cep': cep?.trim(),
          'cidade': cidade?.trim(),
          'bairro': bairro?.trim(),
          'rua': rua?.trim(),
          'numero': numero?.trim(),
          'complemento': complemento?.trim(),
          'contato': contato?.trim(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('usuariosPublicos').doc(uid),
        {
          'primeiroNome': primeiroNome.trim(),
          'segundoNome': segundoNome?.trim(),
          'nomeCompleto': nomeCompleto,
          'cidade': cidade?.trim(),
          'ativo': true,
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      return true;
    }
    if (id == LocalDemoData.adminId) return true;
    final conn = await _conn;
    // OBS: a tabela usuario (Postgres) não tem colunas cep/numero — esses campos
    // são persistidos apenas no Firestore (sessão Google) por enquanto.
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

  /// Perfil completo (com endereço) da sessão Google, lido de `usuarios/{uid}`.
  /// Usado para pré-preencher o formulário de dados cadastrais.
  Future<Usuario?> perfilFirestore() async {
    if (!FirestoreCompatIds.habilitado) return null;
    final uid = FirestoreCompatIds.usuarioUid;
    if (uid == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    final m = doc.data() ?? const {};
    return Usuario(
      id: LocalDemoData.adminId,
      primeiroNome: (m['primeiroNome'] as String?) ?? '',
      segundoNome: m['segundoNome'] as String?,
      email: (m['email'] as String?) ?? '',
      cep: m['cep'] as String?,
      cidade: m['cidade'] as String?,
      bairro: m['bairro'] as String?,
      rua: m['rua'] as String?,
      numero: m['numero'] as String?,
      complemento: m['complemento'] as String?,
      contato: m['contato'] as String?,
      role: (m['role'] as String?) ?? 'USER',
    );
  }

  /// Salva a foto de perfil (bytes) e a marca como verificada (liveness) ou não.
  @override
  Future<void> salvarFoto(int id, Uint8List foto,
      {bool verificada = false}) async {
    if (id == LocalDemoData.adminId) {
      LocalDemoData.instance.fotoAdmin = foto;
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        UPDATE usuario SET foto = @foto, foto_verificada = @v WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'foto': TypedValue(Type.byteArray, foto),
        'v': verificada,
      },
    );
  }

  /// Busca apenas a foto de um usuário (evita carregar bytes nas listas).
  @override
  Future<Uint8List?> buscarFoto(int id) async {
    if (id == LocalDemoData.adminId) return LocalDemoData.instance.fotoAdmin;
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('SELECT foto FROM usuario WHERE id = @id'),
      parameters: {'id': id},
    );
    if (r.isEmpty) return null;
    final foto = r.first.toColumnMap()['foto'];
    if (foto == null) return null;
    return foto is Uint8List ? foto : Uint8List.fromList(List<int>.from(foto));
  }

  /// Salva a URL da foto de perfil (storage externo). No Firestore grava em
  /// `usuarios/{uid}.fotoUrl`; na sessão local guarda em memória (demo).
  Future<void> salvarFotoUrl(int id, String url,
      {bool verificada = false, double? score}) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return;
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(
        firestore.collection('usuarios').doc(uid),
        {
          'firebaseUid': uid,
          'fotoUrl': url,
          'fotoVerificada': verificada,
          if (score != null) 'faceMatchScore': score,
          if (verificada) 'verificadoEm': FieldValue.serverTimestamp(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('usuariosPublicos').doc(uid),
        {
          'fotoUrl': url,
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      return;
    }
    if (id == LocalDemoData.adminId) {
      LocalDemoData.instance.fotoAdminUrl = url;
    }
  }

  /// Busca a URL da foto de perfil (Firestore `usuarios/{uid}` ou demo local).
  Future<String?> buscarFotoUrl(int id) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return null;
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      final dados = doc.data();
      // Foto própria no Storage tem prioridade; senão usa a do Google.
      return (dados?['fotoUrl'] as String?) ??
          (dados?['fotoUrlGoogle'] as String?);
    }
    if (id == LocalDemoData.adminId) return LocalDemoData.instance.fotoAdminUrl;
    return null;
  }
}
