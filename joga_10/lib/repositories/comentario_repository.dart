// 'Type' colide entre cloud_firestore e postgres; escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Comentario.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

class ComentarioRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  ComentarioRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  Future<List<Comentario>> listarPorPostagem(int postagemId) async {
    if (FirestoreCompatIds.habilitado) {
      final post = await _postDoc(postagemId);
      if (post == null) return const [];
      final docs = await post.reference.collection('comentarios').get();
      final registro = 'postagens/${post.id}/comentarios';
      final lista = docs.docs.map((d) {
        final m = d.data();
        return Comentario(
          id: FirestoreCompatIds.registrar(registro, d.id),
          autorId: FirestoreCompatIds.registrar(
              'usuarios', (m['autorId'] as String?) ?? ''),
          autorNome: (m['autorNome'] as String?) ?? 'Usuário',
          texto: (m['texto'] as String?) ?? '',
          criadoEm: _dataHora(m['criadoEm']),
        );
      }).toList();
      lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
      return lista;
    }
    if (postagemId < 0) {
      return List.unmodifiable(
        LocalDemoData.instance.comentarios[postagemId] ?? const [],
      );
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT cm.id, cm.autor_id, cm.texto, cm.criado_em,
               trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, '')) AS autor_nome
        FROM comentario cm
        JOIN usuario u ON u.id = cm.autor_id
        WHERE cm.postagem_id = @p
        ORDER BY cm.criado_em ASC
      '''),
      parameters: {'p': postagemId},
    );
    return r.map((e) => Comentario.fromRow(e.toColumnMap())).toList();
  }

  Future<void> adicionar(int postagemId, int autorId, String texto) async {
    if (FirestoreCompatIds.habilitado) {
      final post = await _postDoc(postagemId);
      if (post == null) return;
      final batch = _firestore.batch();
      batch.set(post.reference.collection('comentarios').doc(), {
        'autorId': FirestoreCompatIds.usuarioUid,
        'autorNome': Sessao.instance.atual?.nomeCompleto ?? 'Usuário',
        'texto': texto.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
      batch.update(post.reference, {
        'comentariosCount': FieldValue.increment(1),
      });
      await batch.commit();
      return;
    }
    if (postagemId < 0 && autorId == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      demo.comentarios.putIfAbsent(postagemId, () => []);
      demo.comentarios[postagemId]!.add(
        Comentario(
          id: demo.novoId(),
          autorId: autorId,
          autorNome: 'Admin Local',
          texto: texto.trim(),
          criadoEm: DateTime.now(),
        ),
      );
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO comentario (postagem_id, autor_id, texto)
        VALUES (@p, @a, @t)
      '''),
      parameters: {'p': postagemId, 'a': autorId, 't': texto.trim()},
    );
  }

  // ---- Helpers Firestore ----
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
