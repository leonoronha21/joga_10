import 'dart:typed_data';

// 'Type' colide entre cloud_firestore e postgres; escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/repositories/amizade_repository.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

class PostagemRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  PostagemRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  /// Feed: posts do próprio usuário + dos amigos (status ACEITO).
  Future<List<Postagem>> listarFeed(int meuId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final amigos =
          await AmizadeRepository(firestore: _firestore).uidsAmigos();
      final autores = <String>{uid, ...amigos}.toList();
      final colecao = _firestore.collection('postagens');
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
      if (autores.length <= 10) {
        docs = (await colecao.where('autorId', whereIn: autores).get()).docs;
      } else {
        docs = (await colecao.get())
            .docs
            .where((d) => autores.contains(d.data()['autorId']))
            .toList();
      }
      final posts = docs.map((d) => _postagemDeDoc(d, uid)).toList();
      posts.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return posts;
    }
    if (meuId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.postagens);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT p.id, p.autor_id, p.texto, p.foto, p.partida_id, p.criado_em,
               trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, '')) AS autor_nome,
               (SELECT count(*) FROM curtida c WHERE c.postagem_id = p.id) AS curtidas,
               EXISTS(SELECT 1 FROM curtida c WHERE c.postagem_id = p.id AND c.usuario_id = @me) AS curtiu_eu,
               (SELECT count(*) FROM comentario cm WHERE cm.postagem_id = p.id) AS comentarios
        FROM postagem p
        JOIN usuario u ON u.id = p.autor_id
        WHERE p.autor_id = @me
           OR p.autor_id IN (
                SELECT CASE WHEN a.solicitante_id = @me THEN a.destinatario_id
                            ELSE a.solicitante_id END
                FROM amizade a
                WHERE a.status = 'ACEITO'
                  AND (a.solicitante_id = @me OR a.destinatario_id = @me)
              )
        ORDER BY p.criado_em DESC
      '''),
      parameters: {'me': meuId},
    );
    return r.map((e) => Postagem.fromRow(e.toColumnMap())).toList();
  }

  /// Posts públicos recentes, independentemente de amizade.
  Future<List<Postagem>> listarDescobrir(int meuId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final docs = await _firestore.collection('postagens').get();
      final posts = docs.docs.map((d) => _postagemDeDoc(d, uid)).toList();
      posts.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return posts;
    }
    if (meuId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.postagens);
    }
    return listarFeed(meuId);
  }

  Future<int> criar({
    required int autorId,
    String? texto,
    Uint8List? foto,
    String? fotoUrl,
    int? partidaId,
  }) async {
    if (FirestoreCompatIds.habilitado) {
      final ref = await _firestore.collection('postagens').add({
        'autorId': FirestoreCompatIds.usuarioUid,
        'autorNome': Sessao.instance.atual?.nomeCompleto ?? 'Usuário',
        'texto': texto,
        'fotoUrl': fotoUrl,
        'partidaId': null,
        'curtidoPor': <String>[],
        'comentariosCount': 0,
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return FirestoreCompatIds.registrar('postagens', ref.id);
    }
    if (autorId == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      final id = demo.novoId();
      demo.postagens.insert(
        0,
        Postagem(
          id: id,
          autorId: autorId,
          autorNome: 'Admin Local',
          texto: texto,
          foto: foto,
          fotoUrl: fotoUrl,
          partidaId: partidaId,
          criadoEm: DateTime.now(),
        ),
      );
      return id;
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        INSERT INTO postagem (autor_id, texto, foto, partida_id)
        VALUES (@autor, @texto, @foto, @partida)
        RETURNING id
      '''),
      parameters: {
        'autor': autorId,
        'texto': texto,
        'foto': foto == null ? null : TypedValue(Type.byteArray, foto),
        'partida': partidaId,
      },
    );
    return r.first.toColumnMap()['id'] as int;
  }

  Future<void> definirCurtida(
      int postagemId, int usuarioId, bool curtir) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return;
      final doc = await _postDoc(postagemId);
      if (doc == null) return;
      await doc.reference.update({
        'curtidoPor': curtir
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
      });
      return;
    }
    if (usuarioId == LocalDemoData.adminId && postagemId < 0) {
      final demo = LocalDemoData.instance;
      final index = demo.postagens.indexWhere((p) => p.id == postagemId);
      if (index < 0) return;
      final atual = demo.postagens[index];
      demo.postagens[index] = atual.copyWith(
        curtiuEu: curtir,
        curtidas: atual.curtidas + (curtir ? 1 : -1),
      );
      return;
    }
    final conn = await _conn;
    if (curtir) {
      await conn.execute(
        Sql.named('''
          INSERT INTO curtida (postagem_id, usuario_id)
          VALUES (@p, @u)
          ON CONFLICT (postagem_id, usuario_id) DO NOTHING
        '''),
        parameters: {'p': postagemId, 'u': usuarioId},
      );
    } else {
      await conn.execute(
        Sql.named(
            'DELETE FROM curtida WHERE postagem_id = @p AND usuario_id = @u'),
        parameters: {'p': postagemId, 'u': usuarioId},
      );
    }
  }

  // ---- Helpers Firestore ----
  Postagem _postagemDeDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    String meuUid,
  ) {
    final m = d.data();
    final curtidoPor = (m['curtidoPor'] as List?)?.cast<String>() ?? const [];
    return Postagem(
      id: FirestoreCompatIds.registrar('postagens', d.id),
      autorId: FirestoreCompatIds.registrar(
          'usuarios', (m['autorId'] as String?) ?? ''),
      autorNome: (m['autorNome'] as String?) ?? 'Usuário',
      texto: m['texto'] as String?,
      fotoUrl: m['fotoUrl'] as String?,
      partidaId: null,
      criadoEm: _dataHora(m['criadoEm']),
      curtidas: curtidoPor.length,
      curtiuEu: curtidoPor.contains(meuUid),
      comentarios: (m['comentariosCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _postDoc(int id) async {
    final conhecido = FirestoreCompatIds.documento('postagens', id);
    final ref = _firestore.collection('postagens');
    if (conhecido != null) {
      final d = await ref.doc(conhecido).get();
      if (d.exists) return d;
    }
    final docs = await ref.get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('postagens', d.id) == id) return d;
    }
    return null;
  }

  DateTime _dataHora(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor?.toString() ?? '') ?? DateTime.now();
  }
}
