import 'dart:typed_data';

import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Postagem.dart';

class PostagemRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  /// Feed: posts do próprio usuário + dos amigos (status ACEITO).
  Future<List<Postagem>> listarFeed(int meuId) async {
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

  Future<int> criar({
    required int autorId,
    String? texto,
    Uint8List? foto,
    int? partidaId,
  }) async {
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

  Future<void> definirCurtida(int postagemId, int usuarioId, bool curtir) async {
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
}
