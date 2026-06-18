import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Postagem.dart';
import 'package:joga_10/repositories/amizade_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
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

  static const _selectPostagem = '''
    SELECT p.id, p.autor_id, p.texto, p.foto, p.partida_id, p.criado_em,
           p.tipo, p.visibilidade,
           trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, '')) AS autor_nome,
           (SELECT count(*) FROM curtida c WHERE c.postagem_id = p.id) AS curtidas,
           EXISTS(
             SELECT 1 FROM curtida c
             WHERE c.postagem_id = p.id AND c.usuario_id = @me
           ) AS curtiu_eu,
           (SELECT count(*) FROM comentario cm
             WHERE cm.postagem_id = p.id) AS comentarios,
           partida.modalidade AS atividade_modalidade,
           coalesce(q.nome, e.nome) AS atividade_local,
           partida.data_hora AS atividade_data_hora,
           partida.duracao AS atividade_duracao,
           partida.placar_time1 AS atividade_placar_equipe_a,
           partida.placar_time2 AS atividade_placar_equipe_b,
           (SELECT count(*) FROM partida_membro pm
             WHERE pm.partida_id = partida.id) AS atividade_participantes
    FROM postagem p
    JOIN usuario u ON u.id = p.autor_id
    LEFT JOIN partida ON partida.id = p.partida_id
    LEFT JOIN quadra q ON q.id = partida.id_quadra
    LEFT JOIN estabelecimento e ON e.id = partida.id_estabelecimento
  ''';

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
            .where((doc) => autores.contains(doc.data()['autorId']))
            .toList();
      }
      final posts = docs.map((doc) => _postagemDeDoc(doc, uid)).toList();
      posts.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return posts;
    }
    if (meuId == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.postagens);
    }

    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        $_selectPostagem
        WHERE p.autor_id = @me
           OR p.autor_id IN (
                SELECT CASE
                  WHEN a.solicitante_id = @me THEN a.destinatario_id
                  ELSE a.solicitante_id
                END
                FROM amizade a
                WHERE a.status = 'ACEITO'
                  AND (a.solicitante_id = @me OR a.destinatario_id = @me)
              )
        ORDER BY p.criado_em DESC
      '''),
      parameters: {'me': meuId},
    );
    return rows.map((row) => Postagem.fromRow(row.toColumnMap())).toList();
  }

  Future<List<Postagem>> listarDescobrir(int meuId) async {
    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      if (uid == null) return const [];
      final docs = await _firestore.collection('postagens').get();
      final posts = docs.docs
          .map((doc) => _postagemDeDoc(doc, uid))
          .where((post) => post.publica)
          .toList();
      posts.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return posts;
    }
    if (meuId == LocalDemoData.adminId) {
      return LocalDemoData.instance.postagens.where((p) => p.publica).toList();
    }

    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        $_selectPostagem
        WHERE p.visibilidade = 'PUBLICO'
        ORDER BY p.criado_em DESC
      '''),
      parameters: {'me': meuId},
    );
    return rows.map((row) => Postagem.fromRow(row.toColumnMap())).toList();
  }

  Future<int> criar({
    required int autorId,
    String? texto,
    Uint8List? foto,
    String? fotoUrl,
    int? partidaId,
    String visibilidade = VisibilidadePostagem.publico,
  }) async {
    final partida = partidaId == null
        ? null
        : await PartidaRepository(firestore: _firestoreConfigurado)
            .buscarPorId(partidaId);
    final tipo =
        partida == null ? TipoPostagem.publicacao : TipoPostagem.atividade;

    if (FirestoreCompatIds.habilitado) {
      final uid = FirestoreCompatIds.usuarioUid;
      final amigos = visibilidade == VisibilidadePostagem.amigos
          ? await AmizadeRepository(firestore: _firestore).uidsAmigos()
          : <String>[];
      final ref = await _firestore.collection('postagens').add({
        'autorId': uid,
        'autorNome': Sessao.instance.atual?.nomeCompleto ?? 'Usuário',
        'texto': texto,
        'fotoUrl': fotoUrl,
        'partidaIdCompat': partidaId,
        'tipo': tipo,
        'visibilidade': visibilidade,
        'visivelPara': <String>{if (uid != null) uid, ...amigos}.toList(),
        'atividadeModalidade': partida?.modalidade,
        'atividadeLocal': partida?.quadraNome ?? partida?.estabelecimentoNome,
        'atividadeDataHora':
            partida == null ? null : Timestamp.fromDate(partida.dataHora),
        'atividadeDuracao': partida?.duracao,
        'atividadePlacarEquipeA': partida?.placarTime1,
        'atividadePlacarEquipeB': partida?.placarTime2,
        'atividadeParticipantes': partida?.membros.length,
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
          tipo: tipo,
          visibilidade: visibilidade,
          atividadeModalidade: partida?.modalidade,
          atividadeLocal: partida?.quadraNome ?? partida?.estabelecimentoNome,
          atividadeDataHora: partida?.dataHora,
          atividadeDuracao: partida?.duracao,
          atividadePlacarEquipeA: partida?.placarTime1,
          atividadePlacarEquipeB: partida?.placarTime2,
          atividadeParticipantes: partida?.membros.length,
          criadoEm: DateTime.now(),
        ),
      );
      return id;
    }

    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        INSERT INTO postagem
          (autor_id, texto, foto, partida_id, tipo, visibilidade)
        VALUES
          (@autor, @texto, @foto, @partida, @tipo, @visibilidade)
        RETURNING id
      '''),
      parameters: {
        'autor': autorId,
        'texto': texto,
        'foto': foto == null ? null : TypedValue(Type.byteArray, foto),
        'partida': partidaId,
        'tipo': tipo,
        'visibilidade': visibilidade,
      },
    );
    return rows.first.toColumnMap()['id'] as int;
  }

  Future<void> definirCurtida(
    int postagemId,
    int usuarioId,
    bool curtir,
  ) async {
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
          VALUES (@postagem, @usuario)
          ON CONFLICT (postagem_id, usuario_id) DO NOTHING
        '''),
        parameters: {'postagem': postagemId, 'usuario': usuarioId},
      );
    } else {
      await conn.execute(
        Sql.named('''
          DELETE FROM curtida
          WHERE postagem_id = @postagem AND usuario_id = @usuario
        '''),
        parameters: {'postagem': postagemId, 'usuario': usuarioId},
      );
    }
  }

  Postagem _postagemDeDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String meuUid,
  ) {
    final dados = doc.data();
    final curtidoPor =
        (dados['curtidoPor'] as List?)?.cast<String>() ?? const [];
    return Postagem(
      id: FirestoreCompatIds.registrar('postagens', doc.id),
      autorId: FirestoreCompatIds.registrar(
        'usuarios',
        (dados['autorId'] as String?) ?? '',
      ),
      autorNome: (dados['autorNome'] as String?) ?? 'Usuário',
      texto: dados['texto'] as String?,
      fotoUrl: dados['fotoUrl'] as String?,
      partidaId: (dados['partidaIdCompat'] as num?)?.toInt(),
      tipo: (dados['tipo'] as String?) ?? TipoPostagem.publicacao,
      visibilidade:
          (dados['visibilidade'] as String?) ?? VisibilidadePostagem.publico,
      atividadeModalidade: dados['atividadeModalidade'] as String?,
      atividadeLocal: dados['atividadeLocal'] as String?,
      atividadeDataHora: _dataHoraOpcional(dados['atividadeDataHora']),
      atividadeDuracao: dados['atividadeDuracao'] as String?,
      atividadePlacarEquipeA:
          (dados['atividadePlacarEquipeA'] as num?)?.toInt(),
      atividadePlacarEquipeB:
          (dados['atividadePlacarEquipeB'] as num?)?.toInt(),
      atividadeParticipantes:
          (dados['atividadeParticipantes'] as num?)?.toInt(),
      criadoEm: _dataHora(dados['criadoEm']),
      curtidas: curtidoPor.length,
      curtiuEu: curtidoPor.contains(meuUid),
      comentarios: (dados['comentariosCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _postDoc(int id) async {
    final conhecido = FirestoreCompatIds.documento('postagens', id);
    final ref = _firestore.collection('postagens');
    if (conhecido != null) {
      final doc = await ref.doc(conhecido).get();
      if (doc.exists) return doc;
    }
    final docs = await ref.get();
    for (final doc in docs.docs) {
      if (FirestoreCompatIds.registrar('postagens', doc.id) == id) return doc;
    }
    return null;
  }

  DateTime _dataHora(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor?.toString() ?? '') ?? DateTime.now();
  }

  DateTime? _dataHoraOpcional(dynamic valor) {
    if (valor == null) return null;
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor.toString());
  }
}
