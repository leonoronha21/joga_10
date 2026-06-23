// 'Type' colide entre cloud_firestore e postgres; escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Amizade.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';

class AmizadeRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  AmizadeRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  static const String _nomeSql =
      "trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, ''))";

  Future<List<Usuario>> listarAmigos(int meuId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final docs = await _firestore
          .collection('amizades')
          .where('usuarios', arrayContains: uid)
          .get();
      final amigos = <Usuario>[];
      for (final d in docs.docs) {
        final m = d.data();
        if (m['status'] != 'ACEITO') continue;
        final outro = _outroUid(m, uid);
        if (outro == null) continue;
        final u =
            await _firestore.collection('usuariosPublicos').doc(outro).get();
        if (u.exists) amigos.add(_usuarioDeDoc(u));
      }
      amigos.sort((a, b) => a.primeiroNome.compareTo(b.primeiroNome));
      return amigos;
    }
    if (meuId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.amigos);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT u.* FROM usuario u
        JOIN amizade a
          ON ((a.solicitante_id = u.id AND a.destinatario_id = @me)
           OR (a.destinatario_id = u.id AND a.solicitante_id = @me))
        WHERE a.status = 'ACEITO'
        ORDER BY u.primeiro_nome
      '''),
      parameters: {'me': meuId},
    );
    return r.map((e) => Usuario.fromRow(e.toColumnMap())).toList();
  }

  /// IDs (compat) dos amigos — usado para montar o feed.
  Future<List<int>> idsAmigos(int meuId) async {
    if (FirestoreCompatIds.habilitado) {
      final uids = await uidsAmigos();
      return uids
          .map((u) => FirestoreCompatIds.registrar('usuarios', u))
          .toList();
    }
    if (meuId == LocalDemoData.adminId) {
      return LocalDemoData.instance.amigos.map((u) => u.id).toList();
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT CASE WHEN a.solicitante_id = @me THEN a.destinatario_id
                    ELSE a.solicitante_id END AS amigo_id
        FROM amizade a
        WHERE a.status = 'ACEITO'
          AND (a.solicitante_id = @me OR a.destinatario_id = @me)
      '''),
      parameters: {'me': meuId},
    );
    return r.map((e) => e.toColumnMap()['amigo_id'] as int).toList();
  }

  /// UIDs (Firebase) dos amigos aceitos do usuário logado.
  Future<List<String>> uidsAmigos() async {
    final uid = FirestoreCompatIds.usuarioUid;
    if (uid == null) return const [];
    final docs = await _firestore
        .collection('amizades')
        .where('usuarios', arrayContains: uid)
        .get();
    return docs.docs
        .where((d) => d.data()['status'] == 'ACEITO')
        .map((d) => _outroUid(d.data(), uid))
        .whereType<String>()
        .toList();
  }

  Future<List<PedidoAmizade>> listarPedidosRecebidos(int meuId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final docs = await _firestore
          .collection('amizades')
          .where('destinatarioId', isEqualTo: uid)
          .get();
      final pedidos = <PedidoAmizade>[];
      for (final d in docs.docs) {
        final m = d.data();
        if (m['status'] != 'PENDENTE') continue;
        final solicitante = m['solicitanteId'] as String?;
        if (solicitante == null) continue;
        final u = await _firestore
            .collection('usuariosPublicos')
            .doc(solicitante)
            .get();
        final dados = u.data() ?? const {};
        pedidos.add(PedidoAmizade(
          amizadeId: FirestoreCompatIds.registrar('amizades', d.id),
          usuarioId: FirestoreCompatIds.registrar('usuarios', solicitante),
          nome: (dados['nomeCompleto'] as String?) ?? 'Usuário',
          email: '',
        ));
      }
      return pedidos;
    }
    if (meuId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.pedidos);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT a.id AS amizade_id, u.id AS usuario_id,
               $_nomeSql AS nome, u.email
        FROM amizade a
        JOIN usuario u ON u.id = a.solicitante_id
        WHERE a.destinatario_id = @me AND a.status = 'PENDENTE'
        ORDER BY a.criado_em DESC
      '''),
      parameters: {'me': meuId},
    );
    return r.map((e) => PedidoAmizade.fromRow(e.toColumnMap())).toList();
  }

  Future<List<UsuarioBusca>> buscarUsuarios(int meuId, String termo) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final relDocs = await _firestore
          .collection('amizades')
          .where('usuarios', arrayContains: uid)
          .get();
      final relacoes = <String, _Relacao>{};
      for (final d in relDocs.docs) {
        final m = d.data();
        final outro = _outroUid(m, uid);
        if (outro == null) continue;
        relacoes[outro] = _Relacao(
          status: (m['status'] as String?) ?? '',
          docId: d.id,
          solicitante: (m['solicitanteId'] as String?) ?? '',
        );
      }
      final termoLower = termo.trim().toLowerCase();
      final usuarios = await _firestore.collection('usuariosPublicos').get();
      final resultados = <UsuarioBusca>[];
      for (final u in usuarios.docs) {
        if (u.id == uid) continue;
        final m = u.data();
        final nome = (m['nomeCompleto'] as String?) ?? '';
        if (termoLower.isNotEmpty && !nome.toLowerCase().contains(termoLower)) {
          continue;
        }
        final rel = relacoes[u.id];
        final StatusAmizade status;
        if (rel == null) {
          status = StatusAmizade.nenhuma;
        } else if (rel.status == 'ACEITO') {
          status = StatusAmizade.amigos;
        } else if (rel.status == 'PENDENTE') {
          status = rel.solicitante == uid
              ? StatusAmizade.pendenteEnviado
              : StatusAmizade.pendenteRecebido;
        } else {
          status = StatusAmizade.nenhuma;
        }
        resultados.add(UsuarioBusca(
          id: FirestoreCompatIds.registrar('usuarios', u.id),
          nome: nome.isEmpty ? 'Usuário' : nome,
          email: '',
          status: status,
          amizadeId: rel == null
              ? null
              : FirestoreCompatIds.registrar('amizades', rel.docId),
        ));
      }
      resultados.sort((a, b) => a.nome.compareTo(b.nome));
      return resultados;
    }
    if (meuId == LocalDemoData.adminId) {
      return LocalDemoData.instance.buscarUsuarios(termo);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT u.id, $_nomeSql AS nome, u.email,
               a.id AS amizade_id, a.status AS a_status, a.solicitante_id
        FROM usuario u
        LEFT JOIN amizade a
          ON ((a.solicitante_id = u.id AND a.destinatario_id = @me)
           OR (a.destinatario_id = u.id AND a.solicitante_id = @me))
        WHERE u.id <> @me
          AND (u.primeiro_nome ILIKE @q OR u.email ILIKE @q
               OR coalesce(u.segundo_nome, '') ILIKE @q)
        ORDER BY nome
      '''),
      parameters: {'me': meuId, 'q': '%$termo%'},
    );
    return r.map((e) {
      final m = e.toColumnMap();
      final aStatus = m['a_status'] as String?;
      StatusAmizade status;
      if (aStatus == 'ACEITO') {
        status = StatusAmizade.amigos;
      } else if (aStatus == 'PENDENTE') {
        status = (m['solicitante_id'] as int?) == meuId
            ? StatusAmizade.pendenteEnviado
            : StatusAmizade.pendenteRecebido;
      } else {
        status = StatusAmizade.nenhuma;
      }
      return UsuarioBusca(
        id: m['id'] as int,
        nome: (m['nome'] as String?) ?? 'Usuário',
        email: (m['email'] as String?) ?? '',
        status: status,
        amizadeId: m['amizade_id'] == null ? null : m['amizade_id'] as int,
      );
    }).toList();
  }

  Future<void> enviarPedido(int meuId, int outroId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) {
        throw StateError('Entre na sua conta para adicionar amigos.');
      }
      final outroUid = await _uidUsuario(outroId);
      if (outroUid == null || outroUid == uid) {
        throw StateError('Perfil nao encontrado.');
      }
      final ref = _firestore.collection('amizades').doc(_pairId(uid, outroUid));
      final existente = await ref.get();
      final statusAtual = existente.data()?['status'] as String?;
      if (statusAtual == 'ACEITO') return;
      await ref.set({
        'solicitanteId': uid,
        'destinatarioId': outroUid,
        'usuarios': existente.data()?['usuarios'] ?? [uid, outroUid],
        'status': 'PENDENTE',
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: existente.exists));
      return;
    }
    if (meuId == LocalDemoData.adminId) {
      LocalDemoData.instance.enviarPedidoAmizade(outroId);
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO amizade (solicitante_id, destinatario_id, status)
        VALUES (@me, @outro, 'PENDENTE')
        ON CONFLICT (solicitante_id, destinatario_id)
        DO UPDATE SET status = 'PENDENTE'
      '''),
      parameters: {'me': meuId, 'outro': outroId},
    );
  }

  Future<void> responder(int amizadeId, bool aceitar) async {
    final status = aceitar ? 'ACEITO' : 'RECUSADO';
    if (FirestoreCompatIds.habilitado) {
      final doc = await _amizadeDoc(amizadeId);
      if (doc == null) return;
      await doc.reference.update({'status': status});
      return;
    }
    if (amizadeId < 0) {
      LocalDemoData.instance.responderPedidoAmizade(amizadeId, aceitar);
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('UPDATE amizade SET status = @s WHERE id = @id'),
      parameters: {'id': amizadeId, 's': status},
    );
  }

  // ---- Helpers Firestore ----
  String? _outroUid(Map<String, dynamic> amizade, String meuUid) {
    final solicitante = amizade['solicitanteId'] as String?;
    final destinatario = amizade['destinatarioId'] as String?;
    if (solicitante == meuUid) return destinatario;
    if (destinatario == meuUid) return solicitante;
    return null;
  }

  String _pairId(String a, String b) =>
      a.compareTo(b) <= 0 ? '${a}_$b' : '${b}_$a';

  Usuario _usuarioDeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final nomeCompleto = (m['nomeCompleto'] as String?) ?? '';
    final primeiro = (m['primeiroNome'] as String?) ??
        (nomeCompleto.isEmpty ? 'Usuário' : nomeCompleto.split(' ').first);
    return Usuario(
      id: FirestoreCompatIds.registrar('usuarios', doc.id),
      primeiroNome: primeiro,
      segundoNome: m['segundoNome'] as String?,
      email: '',
      cidade: m['cidade'] as String?,
      role: (m['role'] as String?) ?? 'USER',
    );
  }

  Future<String?> _uidUsuario(int id) async {
    final conhecido = FirestoreCompatIds.documento('usuarios', id);
    if (conhecido != null) return conhecido;
    final docs = await _firestore.collection('usuariosPublicos').get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('usuarios', d.id) == id) return d.id;
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _amizadeDoc(int id) async {
    final conhecido = FirestoreCompatIds.documento('amizades', id);
    final ref = _firestore.collection('amizades');
    if (conhecido != null) {
      final d = await ref.doc(conhecido).get();
      if (d.exists) return d;
    }
    final docs = await ref.get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('amizades', d.id) == id) return d;
    }
    return null;
  }
}

class _Relacao {
  final String status;
  final String docId;
  final String solicitante;
  _Relacao({
    required this.status,
    required this.docId,
    required this.solicitante,
  });
}
