import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Contratacao.dart';
import 'package:joga_10/model/Goleiro.dart';
import 'package:joga_10/services/local_demo_data.dart';

class GoleiroRepository {
  final DatabaseProvider _database;

  GoleiroRepository({DatabaseProvider? database})
      : _database = database ?? AppDatabase.instance;

  Future<Pool> get _conn => _database.connection;

  static const String _selectGoleiro = '''
    SELECT g.*,
           trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, '')) AS nome,
           u.contato
    FROM goleiro g
    JOIN usuario u ON u.id = g.usuario_id
  ''';

  Future<Goleiro?> meuPerfil(int usuarioId) async {
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
    if (contratacaoId < 0) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('UPDATE contratacao_goleiro SET status = @s WHERE id = @id'),
      parameters: {
        'id': contratacaoId,
        's': aceitar ? ContratacaoStatus.aceita : ContratacaoStatus.recusada,
      },
    );
  }
}
