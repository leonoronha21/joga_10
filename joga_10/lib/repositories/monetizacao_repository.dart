// 'Type' colide entre cloud_firestore e postgres; escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/pagamento_provider_contract.dart';
import 'package:joga_10/domain/services/beneficios_assinatura.dart';
import 'package:joga_10/domain/services/calculadora_rateio.dart';
import 'package:joga_10/model/Monetizacao.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/Rateio.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/pagamento_demo_provider.dart';
import 'package:joga_10/services/sessao.dart';

class MonetizacaoRepository implements MonetizacaoRepositoryContract {
  final DatabaseProvider _database;
  final CalculadoraRateio _calculadora;
  final BeneficiosAssinatura _beneficios;
  final PagamentoProviderContract _pagamentos;
  final FirebaseFirestore? _firestoreConfigurado;

  MonetizacaoRepository({
    DatabaseProvider? database,
    CalculadoraRateio calculadora = const CalculadoraRateio(),
    BeneficiosAssinatura beneficios = const BeneficiosAssinatura(),
    PagamentoProviderContract pagamentos = const PagamentoDemoProvider(),
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _calculadora = calculadora,
        _beneficios = beneficios,
        _pagamentos = pagamentos,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  @override
  Future<PartidaRateio?> buscarRateioPorPartida(int partidaId) async {
    if (FirestoreCompatIds.habilitado) return _buscarRateioFirestore(partidaId);
    if (partidaId < 0) return LocalDemoData.instance.rateios[partidaId];
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
  }) async {
    final taxaPercentual = await _taxaRateioDaPartida(partidaId);
    if (FirestoreCompatIds.habilitado) {
      return _criarOuAtualizarRateioFirestore(
        partidaId: partidaId,
        valorQuadra: valorQuadra,
        taxaPercentual: taxaPercentual,
      );
    }
    if (partidaId < 0) {
      return LocalDemoData.instance.criarRateio(
        partidaId: partidaId,
        valorQuadra: valorQuadra,
        taxaPercentual: taxaPercentual,
      );
    }
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

  Future<double> _taxaRateioDaPartida(int partidaId) async {
    if (FirestoreCompatIds.habilitado) {
      final partida = await _partidaDocPorId(partidaId);
      final organizadorUid = partida?.data()?['organizadorId'] as String?;
      if (organizadorUid != FirestoreCompatIds.usuarioUid) {
        return BeneficiosAssinatura.taxaRateioFree;
      }
      final usuarioId = Sessao.instance.atual?.id;
      final assinatura =
          usuarioId == null ? null : await buscarAssinatura(usuarioId);
      return _beneficios.taxaRateio(assinatura);
    }

    if (partidaId < 0) {
      final partida = LocalDemoData.instance.buscarPartida(partidaId);
      final assinatura = partida?.organizadorId == LocalDemoData.adminId
          ? LocalDemoData.instance.assinatura
          : null;
      return _beneficios.taxaRateio(assinatura);
    }

    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        SELECT
          a.status,
          a.inicio_em,
          a.fim_em,
          a.origem,
          a.id AS assinatura_id,
          a.usuario_id,
          pl.*
        FROM partida p
        LEFT JOIN assinatura_usuario a ON a.usuario_id = p.organizador_id
        LEFT JOIN plano_assinatura pl ON pl.id = a.plano_id
        WHERE p.id = @partida
      '''),
      parameters: {'partida': partidaId},
    );
    if (rows.isEmpty) throw StateError('Partida não encontrada.');
    final row = rows.first.toColumnMap();
    if (row['assinatura_id'] == null || row['id'] == null) {
      return BeneficiosAssinatura.taxaRateioFree;
    }
    final assinatura = AssinaturaUsuario(
      id: row['assinatura_id'] as int,
      usuarioId: row['usuario_id'] as int,
      plano: PlanoAssinatura.fromRow(row),
      status: row['status'] as String,
      inicioEm: row['inicio_em'] as DateTime,
      fimEm: row['fim_em'] as DateTime?,
      origem: row['origem'] as String,
    );
    return _beneficios.taxaRateio(assinatura);
  }

  @override
  Future<void> atualizarStatusCobranca(int cobrancaId, String status) async {
    if (FirestoreCompatIds.habilitado) {
      return _atualizarStatusCobrancaFirestore(cobrancaId, status);
    }
    if (cobrancaId < 0) {
      final demo = LocalDemoData.instance;
      for (final entry in demo.rateios.entries) {
        final index =
            entry.value.cobrancas.indexWhere((c) => c.id == cobrancaId);
        if (index < 0) continue;
        final atual = entry.value;
        final cobranca = atual.cobrancas[index];
        if (status == CobrancaStatus.pago) {
          await _pagamentos.pagar(
            SolicitacaoPagamento(
              referenciaCobranca: cobranca.id.toString(),
              valorCentavos: (cobranca.valorTotal * 100).round(),
              descricao: 'Rateio da partida ${atual.partidaId}',
            ),
          );
        }
        final cobrancas = [...atual.cobrancas];
        cobrancas[index] = RateioCobranca(
          id: cobranca.id,
          rateioId: cobranca.rateioId,
          partidaMembroId: cobranca.partidaMembroId,
          idUser: cobranca.idUser,
          nome: cobranca.nome,
          valorQuadra: cobranca.valorQuadra,
          taxaServico: cobranca.taxaServico,
          valorTotal: cobranca.valorTotal,
          status: status,
          pagoEm: status == CobrancaStatus.pago ? DateTime.now() : null,
        );
        demo.rateios[entry.key] = PartidaRateio(
          id: atual.id,
          partidaId: atual.partidaId,
          valorQuadra: atual.valorQuadra,
          taxaPercentual: atual.taxaPercentual,
          status: atual.status,
          cobrancas: cobrancas,
        );
        return;
      }
      return;
    }
    final conn = await _conn;
    ResultadoPagamento? pagamento;
    if (status == CobrancaStatus.pago) {
      final cobrancas = await conn.execute(
        Sql.named('SELECT valor_total FROM rateio_cobranca WHERE id = @id'),
        parameters: {'id': cobrancaId},
      );
      if (cobrancas.isEmpty) return;
      final valorTotal =
          (cobrancas.first.toColumnMap()['valor_total'] as num).toDouble();
      pagamento = await _pagamentos.pagar(
        SolicitacaoPagamento(
          referenciaCobranca: cobrancaId.toString(),
          valorCentavos: (valorTotal * 100).round(),
          descricao: 'Rateio Joga10',
        ),
      );
    }

    await conn.runTx((tx) async {
      final cobrancas = await tx.execute(
        Sql.named('SELECT id_user FROM rateio_cobranca WHERE id = @id'),
        parameters: {'id': cobrancaId},
      );
      if (cobrancas.isEmpty) return;
      final cobranca = cobrancas.first.toColumnMap();

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
            SELECT id, @provedor, @referencia, valor_total, @status
              FROM rateio_cobranca
             WHERE id = @id
          '''),
          parameters: {
            'id': cobrancaId,
            'provedor': pagamento!.provedor,
            'referencia': pagamento.referenciaExterna,
            'status': pagamento.status,
          },
        );
      }

      final idUser = cobranca['id_user'] as int?;
      if (idUser != null) await _sincronizarGamificacao(tx, idUser);
    });
  }

  @override
  Future<void> fecharRateio(int rateioId) async {
    if (FirestoreCompatIds.habilitado) {
      final doc = await _rateioDocPorId(rateioId);
      if (doc != null) {
        await doc.reference.update({
          'status': RateioStatus.fechado,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }
      return;
    }
    if (rateioId < 0) {
      final demo = LocalDemoData.instance;
      final entry =
          demo.rateios.entries.where((e) => e.value.id == rateioId).firstOrNull;
      if (entry == null) return;
      final atual = entry.value;
      demo.rateios[entry.key] = PartidaRateio(
        id: atual.id,
        partidaId: atual.partidaId,
        valorQuadra: atual.valorQuadra,
        taxaPercentual: atual.taxaPercentual,
        status: RateioStatus.fechado,
        cobrancas: atual.cobrancas,
      );
      return;
    }
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
    if (FirestoreCompatIds.habilitado || usuarioId == LocalDemoData.adminId) {
      return LocalDemoData.instance.gamificacaoAdmin;
    }
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
    if (FirestoreCompatIds.habilitado || Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.planos);
    }
    final conn = await _conn;
    final rows = await conn.execute(
      'SELECT * FROM plano_assinatura WHERE ativo = true ORDER BY preco_mensal',
    );
    return rows.map((r) => PlanoAssinatura.fromRow(r.toColumnMap())).toList();
  }

  @override
  Future<AssinaturaUsuario?> buscarAssinatura(int usuarioId) async {
    if (FirestoreCompatIds.habilitado || usuarioId == LocalDemoData.adminId) {
      return LocalDemoData.instance.assinatura;
    }
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
    if (FirestoreCompatIds.habilitado || usuarioId == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      final pro = demo.planos.firstWhere((p) => p.codigo == 'PRO');
      demo.assinatura = AssinaturaUsuario(
        id: demo.novoId(),
        usuarioId: usuarioId,
        plano: pro,
        status: 'ATIVA',
        inicioEm: DateTime.now(),
        fimEm: DateTime.now().add(const Duration(days: 30)),
        origem: 'LOCAL_DEMO',
      );
      return;
    }
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

  // ---- Rateio no Firestore ----
  Future<PartidaRateio?> _buscarRateioFirestore(int partidaId) async {
    final partidaDoc = await _partidaDocPorId(partidaId);
    if (partidaDoc == null) return null;
    final rateioDoc =
        await _firestore.collection('rateios').doc(partidaDoc.id).get();
    if (!rateioDoc.exists) return null;
    final m = rateioDoc.data() ?? const {};
    final cobrancasDocs = await _firestore
        .collection('cobrancas')
        .where('rateioPartidaId', isEqualTo: partidaDoc.id)
        .get();
    final cobrancas = cobrancasDocs.docs.map(_cobrancaDeDoc).toList();
    cobrancas.sort((a, b) {
      final qa = a.quitado ? 1 : 0;
      final qb = b.quitado ? 1 : 0;
      if (qa != qb) return qa.compareTo(qb); // pendentes primeiro
      return a.nome.compareTo(b.nome);
    });
    return PartidaRateio(
      id: FirestoreCompatIds.registrar('rateios', partidaDoc.id),
      partidaId: partidaId,
      valorQuadra: (m['valorQuadra'] as num?)?.toDouble() ?? 0,
      taxaPercentual: (m['taxaPercentual'] as num?)?.toDouble() ?? 0,
      status: (m['status'] as String?) ?? RateioStatus.aberto,
      cobrancas: cobrancas,
    );
  }

  Future<PartidaRateio> _criarOuAtualizarRateioFirestore({
    required int partidaId,
    required double valorQuadra,
    required double taxaPercentual,
  }) async {
    final partidaDoc = await _partidaDocPorId(partidaId);
    if (partidaDoc == null) {
      throw StateError('Partida não encontrada.');
    }
    final organizadorId = partidaDoc.data()?['organizadorId'] as String?;
    final visibilidade = (partidaDoc.data()?['visibilidade'] as String?) ??
        VisibilidadePartida.publica;
    final participantesUids = (partidaDoc.data()?['participantesUids'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
    final conviteContatoKeys =
        (partidaDoc.data()?['conviteContatoKeys'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[];
    final membros = await partidaDoc.reference.collection('membros').get();
    final valores = _calculadora.calcular(
      valorQuadra: valorQuadra,
      taxaPercentual: taxaPercentual,
      participantes: membros.docs.length,
    );
    final meuUid = FirestoreCompatIds.usuarioUid;

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('rateios').doc(partidaDoc.id),
      {
        'partidaId': partidaDoc.id,
        'organizadorId': organizadorId,
        'visibilidade': visibilidade,
        'participantesUids': participantesUids,
        if (conviteContatoKeys.isNotEmpty)
          'conviteContatoKeys': conviteContatoKeys,
        'valorQuadra': valorQuadra,
        'taxaPercentual': taxaPercentual,
        'status': RateioStatus.aberto,
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    for (final membro in membros.docs) {
      final md = membro.data();
      final uid = md['usuarioId'] as String?;
      final idUserCompat = uid == null
          ? null
          : (uid == meuUid
              ? (Sessao.instance.atual?.id ?? LocalDemoData.adminId)
              : FirestoreCompatIds.registrar('usuarios', uid));
      final cobrancaRef = _firestore
          .collection('cobrancas')
          .doc('${partidaDoc.id}_${membro.id}');
      final existente = await cobrancaRef.get();
      final jaPago = existente.exists &&
          existente.data()?['status'] == CobrancaStatus.pago;
      batch.set(
        cobrancaRef,
        {
          'rateioPartidaId': partidaDoc.id,
          'organizadorId': organizadorId,
          'visibilidade': visibilidade,
          'participantesUids': participantesUids,
          if (conviteContatoKeys.isNotEmpty)
            'conviteContatoKeys': conviteContatoKeys,
          'partidaMembroId': FirestoreCompatIds.registrar(
              'partidas/${partidaDoc.id}/membros', membro.id),
          'idUserCompat': idUserCompat,
          'idUserUid': uid,
          'nome': (md['nome'] as String?) ?? '',
          if (!jaPago) 'valorQuadra': valores.valorQuadraPorJogador,
          if (!jaPago) 'taxaServico': valores.taxaPorJogador,
          if (!jaPago) 'valorTotal': valores.totalPorJogador,
          if (!jaPago) 'status': CobrancaStatus.pendente,
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return (await _buscarRateioFirestore(partidaId))!;
  }

  Future<void> _atualizarStatusCobrancaFirestore(
      int cobrancaId, String status) async {
    final doc = await _cobrancaDocPorId(cobrancaId);
    if (doc == null) return;
    if (status == CobrancaStatus.pago) {
      final valorTotal = (doc.data()?['valorTotal'] as num?)?.toDouble() ?? 0;
      await _pagamentos.pagar(
        SolicitacaoPagamento(
          referenciaCobranca: doc.id,
          valorCentavos: (valorTotal * 100).round(),
          descricao: 'Rateio Joga10',
        ),
      );
    }
    await doc.reference.update({
      'status': status,
      'pagoEm':
          status == CobrancaStatus.pago ? FieldValue.serverTimestamp() : null,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  RateioCobranca _cobrancaDeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final pagoEm = m['pagoEm'];
    return RateioCobranca(
      id: FirestoreCompatIds.registrar('cobrancas', doc.id),
      rateioId: FirestoreCompatIds.registrar(
          'rateios', (m['rateioPartidaId'] as String?) ?? ''),
      partidaMembroId: (m['partidaMembroId'] as num?)?.toInt(),
      idUser: (m['idUserCompat'] as num?)?.toInt(),
      nome: (m['nome'] as String?) ?? '',
      valorQuadra: (m['valorQuadra'] as num?)?.toDouble() ?? 0,
      taxaServico: (m['taxaServico'] as num?)?.toDouble() ?? 0,
      valorTotal: (m['valorTotal'] as num?)?.toDouble() ?? 0,
      status: (m['status'] as String?) ?? CobrancaStatus.pendente,
      pagoEm: pagoEm is Timestamp ? pagoEm.toDate() : null,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _partidaDocPorId(
      int id) async {
    final conhecido = FirestoreCompatIds.documento('partidas', id);
    final ref = _firestore.collection('partidas');
    if (conhecido != null) {
      final d = await ref.doc(conhecido).get();
      if (d.exists) return d;
    }
    final docs = await ref.get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('partidas', d.id) == id) return d;
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _rateioDocPorId(
      int id) async {
    final docs = await _firestore.collection('rateios').get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('rateios', d.id) == id) return d;
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _cobrancaDocPorId(
      int id) async {
    final conhecido = FirestoreCompatIds.documento('cobrancas', id);
    final ref = _firestore.collection('cobrancas');
    if (conhecido != null) {
      final d = await ref.doc(conhecido).get();
      if (d.exists) return d;
    }
    final docs = await ref.get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar('cobrancas', d.id) == id) return d;
    }
    return null;
  }
}
