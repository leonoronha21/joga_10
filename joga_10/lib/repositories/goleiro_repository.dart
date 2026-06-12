// 'Type' colide entre cloud_firestore e postgres; escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Contratacao.dart';
import 'package:joga_10/model/Goleiro.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

/// Goleiros e contratações.
///
/// Com sessão Google usa o Firestore: `goleiros/{uid}` (1 perfil por usuário)
/// e `contratacoesGoleiro`. Sem Firebase, mantém o demo local / PostgreSQL.
class GoleiroRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  GoleiroRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  static const String _selectGoleiro = '''
    SELECT g.*,
           trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, '')) AS nome,
           u.contato
    FROM goleiro g
    JOIN usuario u ON u.id = g.usuario_id
  ''';

  Future<Goleiro?> meuPerfil(int usuarioId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return null;
      final doc = await _firestore.collection('goleiros').doc(uid).get();
      if (!doc.exists) return null;
      return _goleiroDeDoc(doc, usuarioId: usuarioId);
    }
    if (usuarioId == LocalDemoData.adminId) {
      return LocalDemoData.instance.perfilGoleiroAdmin;
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('$_selectGoleiro WHERE g.usuario_id = @id'),
      parameters: {'id': usuarioId},
    );
    if (r.isEmpty) return null;
    return Goleiro.fromRow(r.first.toColumnMap());
  }

  /// Cria ou atualiza o perfil de goleiro do usuário.
  Future<void> salvarPerfil({
    required int usuarioId,
    String? cidade,
    required double preco,
    required int nivel,
    required bool disponivel,
    String? observacao,
  }) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return;
      final usuario = Sessao.instance.atual;
      await _firestore.collection('goleiros').doc(uid).set(
        {
          'usuarioId': uid,
          'nome': usuario?.nomeCompleto ?? 'Goleiro',
          'contato': usuario?.contato,
          'cidade': cidade?.trim(),
          'precoJogo': preco,
          'nivel': nivel,
          'disponivel': disponivel,
          'observacao': observacao?.trim(),
          'ambiente': 'DEMO',
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }
    if (usuarioId == LocalDemoData.adminId) {
      LocalDemoData.instance.perfilGoleiroAdmin = Goleiro(
        id: -700,
        usuarioId: usuarioId,
        nome: 'Admin Local',
        cidade: cidade,
        precoJogo: preco,
        nivel: nivel,
        disponivel: disponivel,
        observacao: observacao,
      );
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO goleiro (usuario_id, cidade, preco_jogo, nivel, disponivel, observacao)
        VALUES (@uid, @cidade, @preco, @nivel, @disp, @obs)
        ON CONFLICT (usuario_id) DO UPDATE SET
          cidade = EXCLUDED.cidade,
          preco_jogo = EXCLUDED.preco_jogo,
          nivel = EXCLUDED.nivel,
          disponivel = EXCLUDED.disponivel,
          observacao = EXCLUDED.observacao
      '''),
      parameters: {
        'uid': usuarioId,
        'cidade': cidade?.trim(),
        'preco': preco,
        'nivel': nivel,
        'disp': disponivel,
        'obs': observacao?.trim(),
      },
    );
  }

  Future<List<Goleiro>> listarDisponiveis(int excluirUsuarioId) async {
    if (FirestoreCompatIds.habilitado) {
      final meuUid = FirestoreCompatIds.usuarioUid;
      final docs = await _firestore
          .collection('goleiros')
          .where('disponivel', isEqualTo: true)
          .get();
      final goleiros = docs.docs
          .where((d) => d.id != meuUid)
          .map((d) => _goleiroDeDoc(d))
          .toList();
      goleiros.sort((a, b) {
        if (b.nivel != a.nivel) return b.nivel.compareTo(a.nivel);
        return a.nome.compareTo(b.nome);
      });
      return goleiros;
    }
    if (excluirUsuarioId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.goleiros);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('$_selectGoleiro '
          'WHERE g.disponivel = true AND g.usuario_id <> @me '
          'ORDER BY g.nivel DESC, nome'),
      parameters: {'me': excluirUsuarioId},
    );
    return r.map((e) => Goleiro.fromRow(e.toColumnMap())).toList();
  }

  Future<void> contratar({
    required int goleiroId,
    int? partidaId,
    required int solicitanteId,
    double? valor,
  }) async {
    if (FirestoreCompatIds.habilitado) {
      final solicitanteUid = FirestoreCompatIds.usuarioUid;
      if (solicitanteUid == null) return;
      final goleiroUid = FirestoreCompatIds.documento('goleiros', goleiroId) ??
          (await _goleiroDocPorId(goleiroId))?.id;
      if (goleiroUid == null) return;

      String? partidaQuadra;
      DateTime? partidaData;
      if (partidaId != null) {
        final partidaDocId = FirestoreCompatIds.documento('partidas', partidaId);
        if (partidaDocId != null) {
          final partida =
              await _firestore.collection('partidas').doc(partidaDocId).get();
          final dados = partida.data();
          partidaQuadra = dados?['quadraNome'] as String?;
          final data = dados?['dataHora'];
          if (data is Timestamp) partidaData = data.toDate();
        }
      }

      await _firestore.collection('contratacoesGoleiro').add({
        'goleiroId': goleiroUid,
        'goleiroUid': goleiroUid,
        'solicitanteId': solicitanteUid,
        'solicitanteNome': Sessao.instance.atual?.nomeCompleto ?? 'Usuário',
        'partidaQuadra': partidaQuadra,
        'partidaData':
            partidaData == null ? null : Timestamp.fromDate(partidaData),
        'valor': valor,
        'status': ContratacaoStatus.pendente,
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return;
    }
    if (solicitanteId == LocalDemoData.adminId || goleiroId < 0) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO contratacao_goleiro
          (goleiro_id, partida_id, solicitante_id, valor)
        VALUES (@g, @p, @s, @v)
      '''),
      parameters: {
        'g': goleiroId,
        'p': partidaId,
        's': solicitanteId,
        'v': valor,
      },
    );
  }

  /// Contratações recebidas pelo goleiro logado.
  Future<List<Contratacao>> contratacoesRecebidas(int usuarioId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final docs = await _firestore
          .collection('contratacoesGoleiro')
          .where('goleiroUid', isEqualTo: uid)
          .get();
      final lista = docs.docs.map((d) {
        final m = d.data();
        final data = m['partidaData'];
        final criado = m['criadoEm'];
        return Contratacao(
          id: FirestoreCompatIds.registrar('contratacoesGoleiro', d.id),
          goleiroId: FirestoreCompatIds.registrar('goleiros', uid),
          partidaId: null,
          solicitanteId: FirestoreCompatIds.registrar(
              'usuarios', (m['solicitanteId'] as String?) ?? ''),
          status: (m['status'] as String?) ?? ContratacaoStatus.pendente,
          valor: (m['valor'] as num?)?.toDouble(),
          criadoEm: criado is Timestamp ? criado.toDate() : DateTime.now(),
          solicitanteNome: (m['solicitanteNome'] as String?) ?? 'Usuário',
          partidaQuadra: m['partidaQuadra'] as String?,
          partidaData: data is Timestamp ? data.toDate() : null,
        );
      }).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    }
    if (usuarioId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.solicitacoesGoleiro);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT ct.*,
               trim(s.primeiro_nome || ' ' || coalesce(s.segundo_nome, '')) AS solicitante_nome,
               q.nome AS partida_quadra, p.data_hora AS partida_data
        FROM contratacao_goleiro ct
        JOIN usuario s ON s.id = ct.solicitante_id
        LEFT JOIN partida p ON p.id = ct.partida_id
        LEFT JOIN quadra q ON q.id = p.id_quadra
        WHERE ct.goleiro_id IN (SELECT id FROM goleiro WHERE usuario_id = @me)
        ORDER BY ct.criado_em DESC
      '''),
      parameters: {'me': usuarioId},
    );
    return r.map((e) => Contratacao.fromRow(e.toColumnMap())).toList();
  }

  Future<void> responder(int contratacaoId, bool aceitar) async {
    final status =
        aceitar ? ContratacaoStatus.aceita : ContratacaoStatus.recusada;
    if (FirestoreCompatIds.habilitado) {
      final doc = await _contratacaoDocPorId(contratacaoId);
      if (doc == null) return;
      await doc.reference.update({'status': status});
      return;
    }
    if (contratacaoId < 0) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('UPDATE contratacao_goleiro SET status = @s WHERE id = @id'),
      parameters: {'id': contratacaoId, 's': status},
    );
  }

  // ---- Helpers Firestore ----
  Goleiro _goleiroDeDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    int? usuarioId,
  }) {
    final m = doc.data() ?? const {};
    return Goleiro(
      id: FirestoreCompatIds.registrar('goleiros', doc.id),
      usuarioId:
          usuarioId ?? FirestoreCompatIds.registrar('usuarios', doc.id),
      nome: (m['nome'] as String?)?.trim() ?? 'Goleiro',
      cidade: m['cidade'] as String?,
      precoJogo: (m['precoJogo'] as num?)?.toDouble() ?? 0,
      nivel: (m['nivel'] as num?)?.toInt() ?? 3,
      disponivel: (m['disponivel'] as bool?) ?? true,
      observacao: m['observacao'] as String?,
      contato: m['contato'] as String?,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _goleiroDocPorId(
      int id) async {
    final docs = await _firestore.collection('goleiros').get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('goleiros', d.id) == id) return d;
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _contratacaoDocPorId(
      int id) async {
    final conhecido = FirestoreCompatIds.documento('contratacoesGoleiro', id);
    final ref = _firestore.collection('contratacoesGoleiro');
    if (conhecido != null) {
      final d = await ref.doc(conhecido).get();
      if (d.exists) return d;
    }
    final docs = await ref.get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('contratacoesGoleiro', d.id) == id) {
        return d;
      }
    }
    return null;
  }
}
