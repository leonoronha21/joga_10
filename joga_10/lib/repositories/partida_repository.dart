import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

class PartidaRepository implements PartidaRepositoryContract {
  final DatabaseProvider _database;

  PartidaRepository({DatabaseProvider? database})
      : _database = database ?? AppDatabase.instance;

  Future<Pool> get _conn => _database.connection;

  static const String _selectBase = '''
    SELECT p.*, q.nome AS quadra_nome, e.nome AS estabelecimento_nome
    FROM partida p
    LEFT JOIN quadra q          ON q.id = p.id_quadra
    LEFT JOIN estabelecimento e ON e.id = p.id_estabelecimento
  ''';

  /// Cria a partida e seus membros numa única transação.
  @override
  Future<int> criar({
    int? idEstabelecimento,
    int? idQuadra,
    required int organizadorId,
    String? duracao,
    required DateTime dataHora,
    String status = PartidaStatus.agendada,
    required double preco,
    List<PartidaMembro> membros = const [],
  }) async {
    if (organizadorId == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      final quadra = demo.quadras.where((q) => q.id == idQuadra).firstOrNull;
      final estab = demo.estabelecimentos
          .where((e) => e.id == idEstabelecimento)
          .firstOrNull;
      final id = demo.novoId();
      demo.partidas.insert(
        0,
        Partida(
          id: id,
          idEstabelecimento: idEstabelecimento,
          idQuadra: idQuadra,
          organizadorId: organizadorId,
          duracao: duracao,
          dataHora: dataHora,
          status: status,
          preco: preco,
          membros: membros,
          quadraNome: quadra?.nome,
          estabelecimentoNome: estab?.nome,
        ),
      );
      return id;
    }
    final conn = await _conn;
    return conn.runTx((tx) async {
      final res = await tx.execute(
        Sql.named('''
          INSERT INTO partida
            (id_estabelecimento, id_quadra, organizador_id,
             duracao, data_hora, status, preco)
          VALUES
            (@id_estabelecimento, @id_quadra, @organizador_id,
             @duracao, @data_hora, @status, @preco)
          RETURNING id
        '''),
        parameters: {
          'id_estabelecimento': idEstabelecimento,
          'id_quadra': idQuadra,
          'organizador_id': organizadorId,
          'duracao': duracao,
          'data_hora': dataHora,
          'status': status,
          'preco': preco,
        },
      );
      final partidaId = res.first.toColumnMap()['id'] as int;

      for (final m in membros) {
        await tx.execute(
          Sql.named('''
            INSERT INTO partida_membro (partida_id, id_user, equipe, nome)
            VALUES (@partida_id, @id_user, @equipe, @nome)
          '''),
          parameters: {
            'partida_id': partidaId,
            'id_user': m.idUser,
            'equipe': m.equipe,
            'nome': m.nome,
          },
        );
      }
      return partidaId;
    });
  }

  Future<List<PartidaMembro>> _carregarMembros(
    Session conn,
    int partidaId,
  ) async {
    final result = await conn.execute(
      Sql.named(
        'SELECT * FROM partida_membro WHERE partida_id = @id ORDER BY id',
      ),
      parameters: {'id': partidaId},
    );
    return result.map((r) => PartidaMembro.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Partida>> _montarComMembros(
    Pool conn,
    Result rows,
  ) async {
    final partidas = <Partida>[];
    for (final r in rows) {
      final map = r.toColumnMap();
      final membros = await _carregarMembros(conn, map['id'] as int);
      partidas.add(Partida.fromRow(map, membros: membros));
    }
    return partidas;
  }

  @override
  Future<List<Partida>> listarTodas() async {
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.partidas);
    }
    final conn = await _conn;
    final rows = await conn.execute('$_selectBase ORDER BY p.data_hora DESC');
    return _montarComMembros(conn, rows);
  }

  @override
  Future<List<Partida>> listarPorUsuario(int userId) async {
    if (userId == LocalDemoData.adminId) {
      return LocalDemoData.instance.partidas
          .where((p) =>
              p.organizadorId == userId ||
              p.membros.any((m) => m.idUser == userId))
          .toList();
    }
    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        $_selectBase
        WHERE p.organizador_id = @uid
           OR EXISTS (
             SELECT 1 FROM partida_membro pm
             WHERE pm.partida_id = p.id AND pm.id_user = @uid
           )
        ORDER BY p.data_hora DESC
      '''),
      parameters: {'uid': userId},
    );
    return _montarComMembros(conn, rows);
  }

  @override
  Future<List<Partida>> listarPorUsuarioEStatus(
      int userId, String status) async {
    if (userId == LocalDemoData.adminId) {
      return (await listarPorUsuario(userId))
          .where((p) => p.status == status)
          .toList();
    }
    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named(
        '''
        $_selectBase
        WHERE p.status = @status
          AND (
            p.organizador_id = @uid
            OR EXISTS (
              SELECT 1 FROM partida_membro pm
              WHERE pm.partida_id = p.id AND pm.id_user = @uid
            )
          )
        ORDER BY p.data_hora DESC
        ''',
      ),
      parameters: {'uid': userId, 'status': status},
    );
    return _montarComMembros(conn, rows);
  }

  @override
  Future<Partida?> buscarPorId(int id) async {
    if (id < 0) return LocalDemoData.instance.buscarPartida(id);
    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('$_selectBase WHERE p.id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    final map = rows.first.toColumnMap();
    final membros = await _carregarMembros(conn, id);
    return Partida.fromRow(map, membros: membros);
  }

  @override
  Future<bool> atualizarStatus(int id, String status) async {
    if (id < 0) {
      final demo = LocalDemoData.instance;
      final index = demo.partidas.indexWhere((p) => p.id == id);
      if (index < 0) return false;
      demo.partidas[index] =
          demo.copiarPartida(demo.partidas[index], status: status);
      return true;
    }
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('UPDATE partida SET status = @status WHERE id = @id'),
      parameters: {'id': id, 'status': status},
    );
    return result.affectedRows > 0;
  }

  @override
  Future<bool> finalizar(int id) =>
      atualizarStatus(id, PartidaStatus.finalizada);

  /// Finaliza a partida salvando o placar e os gols de cada jogador.
  @override
  Future<void> finalizarComPlacar({
    required int partidaId,
    required int placarTime1,
    required int placarTime2,
    required Map<int, int> golsPorMembro, // id do membro -> gols
  }) async {
    if (partidaId < 0) {
      final demo = LocalDemoData.instance;
      final index = demo.partidas.indexWhere((p) => p.id == partidaId);
      if (index < 0) return;
      final partida = demo.partidas[index];
      final membros = partida.membros
          .map((m) => PartidaMembro(
                id: m.id,
                partidaId: m.partidaId,
                idUser: m.idUser,
                equipe: m.equipe,
                nome: m.nome,
                posX: m.posX,
                posY: m.posY,
                gols: golsPorMembro[m.id] ?? m.gols,
              ))
          .toList();
      demo.partidas[index] = demo.copiarPartida(
        partida,
        status: PartidaStatus.finalizada,
        placarTime1: placarTime1,
        placarTime2: placarTime2,
        membros: membros,
      );
      return;
    }
    final conn = await _conn;
    await conn.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          UPDATE partida SET
            status = @status,
            placar_time1 = @p1,
            placar_time2 = @p2
          WHERE id = @id
        '''),
        parameters: {
          'id': partidaId,
          'status': PartidaStatus.finalizada,
          'p1': placarTime1,
          'p2': placarTime2,
        },
      );
      for (final entry in golsPorMembro.entries) {
        await tx.execute(
          Sql.named('UPDATE partida_membro SET gols = @g WHERE id = @id'),
          parameters: {'id': entry.key, 'g': entry.value},
        );
      }
    });
  }

  /// Salva a escalação: formato/formações da partida e a posição (e time)
  /// de cada membro, numa única transação.
  @override
  Future<void> salvarEscalacao({
    required int partidaId,
    required String formato,
    String? formacaoTime1,
    String? formacaoTime2,
    required List<PartidaMembro> membros,
  }) async {
    if (partidaId < 0) return;
    final conn = await _conn;
    await conn.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          UPDATE partida SET
            formato = @formato,
            formacao_time1 = @f1,
            formacao_time2 = @f2
          WHERE id = @id
        '''),
        parameters: {
          'id': partidaId,
          'formato': formato,
          'f1': formacaoTime1,
          'f2': formacaoTime2,
        },
      );
      for (final m in membros) {
        if (m.id == null) continue;
        await tx.execute(
          Sql.named('''
            UPDATE partida_membro SET
              equipe = @equipe,
              pos_x = @px,
              pos_y = @py
            WHERE id = @id
          '''),
          parameters: {
            'id': m.id,
            'equipe': m.equipe,
            'px': m.posX,
            'py': m.posY,
          },
        );
      }
    });
  }

  @override
  Future<void> adicionarMembro({
    required int partidaId,
    int? idUser,
    required String equipe,
    required String nome,
  }) async {
    if (partidaId < 0) {
      LocalDemoData.instance.adicionarMembro(
        partidaId: partidaId,
        idUser: idUser,
        equipe: equipe,
        nome: nome,
      );
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO partida_membro (partida_id, id_user, equipe, nome)
        VALUES (@partida_id, @id_user, @equipe, @nome)
      '''),
      parameters: {
        'partida_id': partidaId,
        'id_user': idUser,
        'equipe': equipe,
        'nome': nome,
      },
    );
  }
}
