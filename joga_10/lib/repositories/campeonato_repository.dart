import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/ClubeJogador.dart';
import 'package:joga_10/model/Confronto.dart';

class CampeonatoRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  // ---- Clubes ----
  Future<List<Clube>> listarClubes() async {
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
    final conn = await _conn;
    await conn.execute(
      Sql.named('DELETE FROM clube_jogador WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  /// Salva a posição (escalação) de cada jogador do clube.
  Future<void> salvarEscalacaoClube(List<ClubeJogador> jogadores) async {
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
    final conn = await _conn;
    final r = await conn.execute('$_selectConfronto ORDER BY cf.data_hora');
    return r.map((e) => Confronto.fromRow(e.toColumnMap())).toList();
  }

  Future<int> criarConfronto({
    required int clubeCasaId,
    required int clubeVisitanteId,
    required DateTime dataHora,
    String tipo = 'AMISTOSO',
    String? local,
  }) async {
    final conn = await _conn;
    final r = await conn.execute(
      Sql.named('''
        INSERT INTO confronto
          (clube_casa_id, clube_visitante_id, data_hora, tipo, local)
        VALUES (@casa, @visitante, @data, @tipo, @local)
        RETURNING id
      '''),
      parameters: {
        'casa': clubeCasaId,
        'visitante': clubeVisitanteId,
        'data': dataHora,
        'tipo': tipo,
        'local': local,
      },
    );
    return r.first.toColumnMap()['id'] as int;
  }

  Future<void> registrarPlacar(
      int confrontoId, int placarCasa, int placarVisitante) async {
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
    final conn = await _conn;
    await conn.execute(
      Sql.named("UPDATE confronto SET status = 'CANCELADO' WHERE id = @id"),
      parameters: {'id': confrontoId},
    );
  }
}
