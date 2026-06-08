import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/services/calculadora_rateio.dart';
import 'package:joga_10/model/Monetizacao.dart';
import 'package:joga_10/model/Rateio.dart';

class MonetizacaoRepository implements MonetizacaoRepositoryContract {
  final DatabaseProvider _database;
  final CalculadoraRateio _calculadora;

  MonetizacaoRepository({
    DatabaseProvider? database,
    CalculadoraRateio calculadora = const CalculadoraRateio(),
  })  : _database = database ?? AppDatabase.instance,
        _calculadora = calculadora;

  Future<Pool> get _conn => _database.connection;

  @override
  Future<PartidaRateio?> buscarRateioPorPartida(int partidaId) async {
    final conn = await _conn;
    final rateios = await conn.execute(
      Sql.named('SELECT * FROM partida_rateio WHERE partida_id = @id'),
      parameters: {'id': partidaId},
    );
    if (rateios.isEmpty) return null;

    final rateioRow = rateios.first.toColumnMap();
    final cobrancas = await conn.execute(
      Sql.named('''
        SELECT * FROM rateio_cobranca
        WHERE rateio_id = @id
        ORDER BY status = 'PENDENTE' DESC, nome
      '''),
      parameters: {'id': rateioRow['id']},
    );
    return PartidaRateio.fromRow(
      rateioRow,
      cobrancas: cobrancas
          .map((r) => RateioCobranca.fromRow(r.toColumnMap()))
          .toList(),
    );
  }

  @override
  Future<PartidaRateio> criarOuAtualizarRateio({
    required int partidaId,
    required double valorQuadra,
    required double taxaPercentual,
  }) async {
    final conn = await _conn;
    final usuariosAfetados = <int>{};

    await conn.runTx((tx) async {
      final membros = await tx.execute(
        Sql.named('''
          SELECT id, id_user, nome
          FROM partida_membro
          WHERE partida_id = @partida
          ORDER BY id
        '''),
        parameters: {'partida': partidaId},
      );
      final valores = _calculadora.calcular(
        valorQuadra: valorQuadra,
        taxaPercentual: taxaPercentual,
        participantes: membros.length,
      );

      final rateioResult = await tx.execute(
        Sql.named('''
          INSERT INTO partida_rateio
            (partida_id, valor_quadra, taxa_percentual, status, atualizado_em)
          VALUES
            (@partida, @valor, @taxa, 'ABERTO', now())
          ON CONFLICT (partida_id) DO UPDATE SET
            valor_quadra = EXCLUDED.valor_quadra,
            taxa_percentual = EXCLUDED.taxa_percentual,
            status = 'ABERTO',
            atualizado_em = now()
          RETURNING id
        '''),
        parameters: {
          'partida': partidaId,
          'valor': valorQuadra,
          'taxa': taxaPercentual,
        },
      );
      final rateioId = rateioResult.first.toColumnMap()['id'] as int;
      for (final membro in membros) {
        final row = membro.toColumnMap();
        final idUser = row['id_user'] as int?;
        if (idUser != null) usuariosAfetados.add(idUser);

        await tx.execute(
          Sql.named('''
            INSERT INTO rateio_cobranca
              (rateio_id, partida_membro_id, id_user, nome, valor_quadra,
               taxa_servico, valor_total, atualizado_em)
            VALUES
              (@rateio, @membro, @usuario, @nome, @valor_quadra,
               @taxa_servico, @valor_total, now())
            ON CONFLICT (rateio_id, partida_membro_id) DO UPDATE SET
              id_user = EXCLUDED.id_user,
              nome = EXCLUDED.nome,
              valor_quadra = CASE
                WHEN rateio_cobranca.status = 'PAGO'
                THEN rateio_cobranca.valor_quadra
                ELSE EXCLUDED.valor_quadra
              END,
              taxa_servico = CASE
                WHEN rateio_cobranca.status = 'PAGO'
                THEN rateio_cobranca.taxa_servico
                ELSE EXCLUDED.taxa_servico
              END,
              valor_total = CASE
                WHEN rateio_cobranca.status = 'PAGO'
                THEN rateio_cobranca.valor_total
                ELSE EXCLUDED.valor_total
              END,
              atualizado_em = now()
          '''),
          parameters: {
            'rateio': rateioId,
            'membro': row['id'],
            'usuario': idUser,
            'nome': row['nome'],
            'valor_quadra': valores.valorQuadraPorJogador,
            'taxa_servico': valores.taxaPorJogador,
            'valor_total': valores.totalPorJogador,
          },
        );
      }

      await tx.execute(
        Sql.named('''
          DELETE FROM rateio_cobranca c
          WHERE c.rateio_id = @rateio
            AND c.status <> 'PAGO'
            AND NOT EXISTS (
              SELECT 1 FROM partida_membro pm
              WHERE pm.id = c.partida_membro_id
                AND pm.partida_id = @partida
            )
        '''),
        parameters: {'rateio': rateioId, 'partida': partidaId},
      );

      for (final usuarioId in usuariosAfetados) {
        await _sincronizarGamificacao(tx, usuarioId);
      }
    });

    return (await buscarRateioPorPartida(partidaId))!;
  }

  @override
  Future<void> atualizarStatusCobranca(int cobrancaId, String status) async {
    final conn = await _conn;
    await conn.runTx((tx) async {
      final cobrancas = await tx.execute(
        Sql.named('SELECT id_user FROM rateio_cobranca WHERE id = @id'),
        parameters: {'id': cobrancaId},
      );
      if (cobrancas.isEmpty) return;

      await tx.execute(
        Sql.named('''
          UPDATE rateio_cobranca SET
            status = @status,
            pago_em = CASE WHEN @status = 'PAGO' THEN now() ELSE NULL END,
            atualizado_em = now()
          WHERE id = @id
        '''),
        parameters: {'id': cobrancaId, 'status': status},
      );

      if (status == CobrancaStatus.pago) {
        await tx.execute(
          Sql.named('''
            INSERT INTO pagamento_transacao
              (cobranca_id, provedor, referencia_externa, valor, status)
            SELECT
              id,
              'LOCAL_DEMO',
              concat(
                'LOCAL-', id, '-',
                floor(extract(epoch from clock_timestamp()) * 1000000)::bigint
              ),
              valor_total,
              'APROVADO'
            FROM rateio_cobranca
            WHERE id = @id
          '''),
          parameters: {'id': cobrancaId},
        );
      }

      final idUser = cobrancas.first.toColumnMap()['id_user'] as int?;
      if (idUser != null) await _sincronizarGamificacao(tx, idUser);
    });
  }

  @override
  Future<void> fecharRateio(int rateioId) async {
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        UPDATE partida_rateio
        SET status = 'FECHADO', atualizado_em = now()
        WHERE id = @id
      '''),
      parameters: {'id': rateioId},
    );
  }

  @override
  Future<GamificacaoUsuario> buscarGamificacao(int usuarioId) async {
    final conn = await _conn;
    await conn.runTx((tx) => _sincronizarGamificacao(tx, usuarioId));
    final rows = await conn.execute(
      Sql.named(
        'SELECT * FROM usuario_gamificacao WHERE usuario_id = @usuario',
      ),
      parameters: {'usuario': usuarioId},
    );
    return GamificacaoUsuario.fromRow(rows.first.toColumnMap());
  }

  Future<void> _sincronizarGamificacao(Session tx, int usuarioId) async {
    await tx.execute(
      Sql.named('''
        INSERT INTO usuario_gamificacao (
          usuario_id,
          pontos,
          partidas_confirmadas,
          pagamentos_em_dia,
          pagamentos_pendentes,
          confiabilidade,
          atualizado_em
        )
        SELECT
          @usuario,
          stats.partidas * 10 + stats.pagos * 20,
          stats.partidas,
          stats.pagos,
          stats.pendentes,
          GREATEST(0, 100 - stats.pendentes * 10),
          now()
        FROM (
          SELECT
            (
              SELECT COUNT(DISTINCT partida_id)::int
              FROM partida_membro
              WHERE id_user = @usuario
            ) AS partidas,
            (
              SELECT COUNT(*)::int
              FROM rateio_cobranca
              WHERE id_user = @usuario AND status = 'PAGO'
            ) AS pagos,
            (
              SELECT COUNT(*)::int
              FROM rateio_cobranca
              WHERE id_user = @usuario AND status = 'PENDENTE'
            ) AS pendentes
        ) stats
        ON CONFLICT (usuario_id) DO UPDATE SET
          pontos = EXCLUDED.pontos,
          partidas_confirmadas = EXCLUDED.partidas_confirmadas,
          pagamentos_em_dia = EXCLUDED.pagamentos_em_dia,
          pagamentos_pendentes = EXCLUDED.pagamentos_pendentes,
          confiabilidade = EXCLUDED.confiabilidade,
          atualizado_em = now()
      '''),
      parameters: {'usuario': usuarioId},
    );
  }

  @override
  Future<List<PlanoAssinatura>> listarPlanos() async {
    final conn = await _conn;
    final rows = await conn.execute(
      'SELECT * FROM plano_assinatura WHERE ativo = true ORDER BY preco_mensal',
    );
    return rows.map((r) => PlanoAssinatura.fromRow(r.toColumnMap())).toList();
  }

  @override
  Future<AssinaturaUsuario?> buscarAssinatura(int usuarioId) async {
    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        SELECT
          a.id AS assinatura_id,
          a.usuario_id,
          a.status,
          a.inicio_em,
          a.fim_em,
          a.origem,
          p.*
        FROM assinatura_usuario a
        JOIN plano_assinatura p ON p.id = a.plano_id
        WHERE a.usuario_id = @usuario
      '''),
      parameters: {'usuario': usuarioId},
    );
    if (rows.isEmpty) return null;
    final row = rows.first.toColumnMap();
    return AssinaturaUsuario(
      id: row['assinatura_id'] as int,
      usuarioId: row['usuario_id'] as int,
      plano: PlanoAssinatura.fromRow(row),
      status: row['status'] as String,
      inicioEm: row['inicio_em'] as DateTime,
      fimEm: row['fim_em'] as DateTime?,
      origem: row['origem'] as String,
    );
  }

  @override
  Future<void> ativarTestePro(int usuarioId) async {
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        INSERT INTO assinatura_usuario
          (usuario_id, plano_id, status, inicio_em, fim_em, origem, atualizado_em)
        SELECT
          @usuario, id, 'ATIVA', now(), now() + interval '30 days',
          'LOCAL_DEMO', now()
        FROM plano_assinatura
        WHERE codigo = 'PRO'
        ON CONFLICT (usuario_id) DO UPDATE SET
          plano_id = EXCLUDED.plano_id,
          status = 'ATIVA',
          inicio_em = now(),
          fim_em = now() + interval '30 days',
          origem = 'LOCAL_DEMO',
          atualizado_em = now()
      '''),
      parameters: {'usuario': usuarioId},
    );
  }
}
