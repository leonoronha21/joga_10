import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/ClubeJogador.dart';
import 'package:joga_10/model/Confronto.dart';
import 'package:joga_10/model/Liga.dart';
import 'package:joga_10/model/LinhaClassificacao.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

class CampeonatoRepository {
  final DatabaseProvider _database;

  CampeonatoRepository({DatabaseProvider? database})
      : _database = database ?? AppDatabase.instance;

  Future<Pool> get _conn => _database.connection;

  // ---- Clubes ----
  Future<List<Clube>> listarClubes() async {
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.clubes);
    }
    final conn = await _conn;
    final r = await conn.execute('SELECT * FROM clube ORDER BY nome');
    return r.map((e) => Clube.fromRow(e.toColumnMap())).toList();
  }

  Future<int> criarClube({
    required String nome,
    String? cidade,
    String cor = '#1B3A6B',
    int? donoId,
  }) async {
    if (Sessao.instance.isAdminLocal) {
      final id = LocalDemoData.instance.novoId();
      LocalDemoData.instance.clubes.add(
        Clube(
            id: id,
            nome: nome.trim(),
            cidade: cidade,
            cor: cor,
            donoId: donoId),
      );
      return id;
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        INSERT INTO clube (nome, cidade, cor, dono_id)
        VALUES (@nome, @cidade, @cor, @dono)
        RETURNING id
      '''),
      parameters: {
        'nome': nome.trim(),
        'cidade': cidade?.trim(),
        'cor': cor,
        'dono': donoId,
      },
    );
    return r.first.toColumnMap()['id'] as int;
  }

  // ---- Elenco do clube ----
  Future<List<ClubeJogador>> listarElenco(int clubeId) async {
    if (clubeId < 0 || Sessao.instance.isAdminLocal) {
      return List.unmodifiable(
        LocalDemoData.instance.elencos[clubeId] ?? const [],
      );
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('SELECT * FROM clube_jogador WHERE clube_id = @id '
          'ORDER BY coalesce(numero, 999), nome'),
      parameters: {'id': clubeId},
    );
    return r.map((e) => ClubeJogador.fromRow(e.toColumnMap())).toList();
  }

  Future<void> adicionarJogadorClube({
    required int clubeId,
    required String nome,
    String? posicao,
    int? numero,
  }) async {
    if (clubeId < 0 || Sessao.instance.isAdminLocal) {
      final demo = LocalDemoData.instance;
      demo.elencos.putIfAbsent(clubeId, () => []);
      demo.elencos[clubeId]!.add(
        ClubeJogador(
          id: demo.novoId(),
          clubeId: clubeId,
          nome: nome.trim(),
          posicao: posicao,
          numero: numero,
        ),
      );
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO clube_jogador (clube_id, nome, posicao, numero)
        VALUES (@c, @nome, @pos, @num)
      '''),
      parameters: {
        'c': clubeId,
        'nome': nome.trim(),
        'pos': posicao,
        'num': numero,
      },
    );
  }

  Future<void> removerJogadorClube(int id) async {
    if (id < 0) {
      for (final elenco in LocalDemoData.instance.elencos.values) {
        elenco.removeWhere((j) => j.id == id);
      }
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('DELETE FROM clube_jogador WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  /// Salva a posição (escalação) de cada jogador do clube.
  Future<void> salvarEscalacaoClube(List<ClubeJogador> jogadores) async {
    if (jogadores.any((j) => j.id < 0)) return;
    final conn = await _conn;
    await conn.runTx((tx) async {
      for (final j in jogadores) {
        await tx.execute(
          Sql.named(
              'UPDATE clube_jogador SET pos_x = @px, pos_y = @py WHERE id = @id'),
          parameters: {'id': j.id, 'px': j.posX, 'py': j.posY},
        );
      }
    });
  }

  // ---- Confrontos ----
  static const String _selectConfronto = '''
    SELECT cf.*,
           cc.nome AS casa_nome, cc.cor AS casa_cor,
           cv.nome AS visitante_nome, cv.cor AS visitante_cor
    FROM confronto cf
    JOIN clube cc ON cc.id = cf.clube_casa_id
    JOIN clube cv ON cv.id = cf.clube_visitante_id
  ''';

  Future<List<Confronto>> listarConfrontos() async {
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.confrontos);
    }
    final conn = await _conn;
    final r = await conn.execute('$_selectConfronto ORDER BY cf.data_hora');
    return r.map((e) => Confronto.fromRow(e.toColumnMap())).toList();
  }

  Future<List<Confronto>> confrontosDaLiga(int ligaId) async {
    if (ligaId < 0 || Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.confrontos);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named(
          '$_selectConfronto WHERE cf.liga_id = @id ORDER BY cf.data_hora'),
      parameters: {'id': ligaId},
    );
    return r.map((e) => Confronto.fromRow(e.toColumnMap())).toList();
  }

  Future<int> criarConfronto({
    required int clubeCasaId,
    required int clubeVisitanteId,
    required DateTime dataHora,
    String tipo = 'AMISTOSO',
    String? local,
    int? ligaId,
  }) async {
    if (Sessao.instance.isAdminLocal) {
      final id = LocalDemoData.instance.novoId();
      final casa =
          LocalDemoData.instance.clubes.firstWhere((c) => c.id == clubeCasaId);
      final visitante = LocalDemoData.instance.clubes
          .firstWhere((c) => c.id == clubeVisitanteId);
      LocalDemoData.instance.confrontos.add(
        Confronto(
          id: id,
          clubeCasaId: clubeCasaId,
          clubeCasaNome: casa.nome,
          clubeCasaCor: casa.cor,
          clubeVisitanteId: clubeVisitanteId,
          clubeVisitanteNome: visitante.nome,
          clubeVisitanteCor: visitante.cor,
          dataHora: dataHora,
          tipo: tipo,
          local: local,
          status: ConfrontoStatus.agendado,
        ),
      );
      return id;
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        INSERT INTO confronto
          (clube_casa_id, clube_visitante_id, data_hora, tipo, local, liga_id)
        VALUES (@casa, @visitante, @data, @tipo, @local, @liga)
        RETURNING id
      '''),
      parameters: {
        'casa': clubeCasaId,
        'visitante': clubeVisitanteId,
        'data': dataHora,
        'tipo': tipo,
        'local': local,
        'liga': ligaId,
      },
    );
    return r.first.toColumnMap()['id'] as int;
  }

  Future<void> registrarPlacar(
      int confrontoId, int placarCasa, int placarVisitante) async {
    if (confrontoId < 0) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        UPDATE confronto SET
          placar_casa = @pc, placar_visitante = @pv, status = 'REALIZADO'
        WHERE id = @id
      '''),
      parameters: {'id': confrontoId, 'pc': placarCasa, 'pv': placarVisitante},
    );
  }

  Future<void> cancelar(int confrontoId) async {
    if (confrontoId < 0) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named("UPDATE confronto SET status = 'CANCELADO' WHERE id = @id"),
      parameters: {'id': confrontoId},
    );
  }

  // ---- Ligas ----
  Future<List<Liga>> listarLigas() async {
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.ligas);
    }
    final conn = await _conn;
    final r = await conn.execute('''
      SELECT l.*, count(lc.clube_id) AS total_times
      FROM liga l
      LEFT JOIN liga_clube lc ON lc.liga_id = l.id
      GROUP BY l.id
      ORDER BY l.nome
    ''');
    return r.map((e) => Liga.fromRow(e.toColumnMap())).toList();
  }

  Future<int> criarLiga({required String nome, String? cidade}) async {
    if (Sessao.instance.isAdminLocal) {
      final id = LocalDemoData.instance.novoId();
      LocalDemoData.instance.ligas.add(
        Liga(id: id, nome: nome.trim(), cidade: cidade, totalTimes: 0),
      );
      return id;
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named(
          'INSERT INTO liga (nome, cidade) VALUES (@nome, @cidade) RETURNING id'),
      parameters: {'nome': nome.trim(), 'cidade': cidade?.trim()},
    );
    return r.first.toColumnMap()['id'] as int;
  }

  Future<List<Clube>> clubesDaLiga(int ligaId) async {
    if (ligaId < 0 || Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.clubes);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT c.* FROM clube c
        JOIN liga_clube lc ON lc.clube_id = c.id
        WHERE lc.liga_id = @id
        ORDER BY c.nome
      '''),
      parameters: {'id': ligaId},
    );
    return r.map((e) => Clube.fromRow(e.toColumnMap())).toList();
  }

  /// Clubes que ainda NÃO estão na liga (para adicionar existentes).
  Future<List<Clube>> clubesForaDaLiga(int ligaId) async {
    if (ligaId < 0 || Sessao.instance.isAdminLocal) return const [];
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        SELECT c.* FROM clube c
        WHERE c.id NOT IN (SELECT clube_id FROM liga_clube WHERE liga_id = @id)
        ORDER BY c.nome
      '''),
      parameters: {'id': ligaId},
    );
    return r.map((e) => Clube.fromRow(e.toColumnMap())).toList();
  }

  Future<void> adicionarClubeNaLiga(int ligaId, int clubeId) async {
    if (ligaId < 0 || clubeId < 0 || Sessao.instance.isAdminLocal) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO liga_clube (liga_id, clube_id) VALUES (@l, @c)
        ON CONFLICT (liga_id, clube_id) DO NOTHING
      '''),
      parameters: {'l': ligaId, 'c': clubeId},
    );
  }

  Future<void> removerClubeDaLiga(int ligaId, int clubeId) async {
    if (ligaId < 0 || clubeId < 0 || Sessao.instance.isAdminLocal) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('DELETE FROM liga_clube WHERE liga_id = @l AND clube_id = @c'),
      parameters: {'l': ligaId, 'c': clubeId},
    );
  }

  /// Tabela de classificação da liga (a partir dos confrontos REALIZADOS).
  Future<List<LinhaClassificacao>> classificacao(int ligaId) async {
    if (ligaId < 0 || Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.classificacaoDemo);
    }
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        WITH jogos AS (
          SELECT clube_casa_id AS clube_id, placar_casa AS gp, placar_visitante AS gc
          FROM confronto WHERE liga_id = @id AND status = 'REALIZADO'
          UNION ALL
          SELECT clube_visitante_id, placar_visitante, placar_casa
          FROM confronto WHERE liga_id = @id AND status = 'REALIZADO'
        )
        SELECT c.id AS clube_id, c.nome, c.cor,
          count(j.clube_id) AS j,
          count(*) FILTER (WHERE j.gp > j.gc) AS v,
          count(*) FILTER (WHERE j.gp = j.gc) AS e,
          count(*) FILTER (WHERE j.gp < j.gc) AS d,
          coalesce(sum(j.gp), 0) AS gp,
          coalesce(sum(j.gc), 0) AS gc,
          coalesce(sum(j.gp - j.gc), 0) AS sg,
          coalesce(sum(CASE WHEN j.gp > j.gc THEN 3
                            WHEN j.gp = j.gc THEN 1 ELSE 0 END), 0) AS pts
        FROM clube c
        JOIN liga_clube lc ON lc.clube_id = c.id AND lc.liga_id = @id
        LEFT JOIN jogos j ON j.clube_id = c.id
        GROUP BY c.id, c.nome, c.cor
        ORDER BY pts DESC, sg DESC, gp DESC, c.nome
      '''),
      parameters: {'id': ligaId},
    );
    return r.map((e) => LinhaClassificacao.fromRow(e.toColumnMap())).toList();
  }
}
