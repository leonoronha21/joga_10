import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Comentario.dart';

class ComentarioRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  Future<List<Comentario>> listarPorPostagem(int postagemId) async {
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
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO comentario (postagem_id, autor_id, texto)
        VALUES (@p, @a, @t)
      '''),
      parameters: {'p': postagemId, 'a': autorId, 't': texto.trim()},
    );
  }
}
