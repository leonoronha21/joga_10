import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Amizade.dart';
import 'package:joga_10/model/Usuario.dart';

class AmizadeRepository {
  final DatabaseProvider _database;

  AmizadeRepository({DatabaseProvider? database})
      : _database = database ?? AppDatabase.instance;

  Future<Pool> get _conn => _database.connection;

  static const String _nomeSql =
      "trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, ''))";

  Future<List<Usuario>> listarAmigos(int meuId) async {
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

  /// IDs dos amigos (para montar o feed).
  Future<List<int>> idsAmigos(int meuId) async {
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

  Future<List<PedidoAmizade>> listarPedidosRecebidos(int meuId) async {
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
    final conn = await _conn;
    await conn.execute(
      Sql.named('UPDATE amizade SET status = @s WHERE id = @id'),
      parameters: {'id': amizadeId, 's': aceitar ? 'ACEITO' : 'RECUSADO'},
    );
  }
}
