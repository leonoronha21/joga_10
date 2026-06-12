// 'Type' colide entre cloud_firestore e postgres; escondemos o do Firestore.
import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/ClubeJogador.dart';
import 'package:joga_10/model/Confronto.dart';
import 'package:joga_10/model/Liga.dart';
import 'package:joga_10/model/LinhaClassificacao.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

/// Campeonatos (ligas, clubes, elenco, confrontos e classificação).
///
/// Com sessão Google usa o Firestore (coleções top-level: `clubes`, `ligas`,
/// `ligaClubes`, `confrontos`, `clubeJogadores`), convertendo os IDs textuais
/// dos documentos em inteiros deterministas via [FirestoreCompatIds]. Sem
/// Firebase, mantém o modo demo local / PostgreSQL.
class CampeonatoRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  CampeonatoRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  // ---- Clubes ----
  Future<List<Clube>> listarClubes() async {
    if (FirestoreCompatIds.habilitado) {
      final docs = await _firestore.collection('clubes').get();
      return docs.docs.map(_clubeDeDoc).toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));
    }
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
    if (FirestoreCompatIds.habilitado) {
      final ref = await _firestore.collection('clubes').add({
        'nome': nome.trim(),
        'cidade': cidade?.trim(),
        'cor': cor,
        'donoId': FirestoreCompatIds.usuarioUid,
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return FirestoreCompatIds.registrar('clubes', ref.id);
    }
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
    if (FirestoreCompatIds.habilitado) {
      final clubeDoc = await _docPorId('clubes', clubeId);
      if (clubeDoc == null) return const [];
      final docs = await _firestore
          .collection('clubeJogadores')
          .where('clubeId', isEqualTo: clubeDoc.id)
          .get();
      final jogadores = docs.docs.map((d) {
        final m = d.data();
        return ClubeJogador(
          id: FirestoreCompatIds.registrar('clubeJogadores', d.id),
          clubeId: clubeId,
          nome: (m['nome'] as String?) ?? '',
          posicao: m['posicao'] as String?,
          numero: (m['numero'] as num?)?.toInt(),
          posX: (m['posX'] as num?)?.toDouble(),
          posY: (m['posY'] as num?)?.toDouble(),
        );
      }).toList();
      jogadores.sort((a, b) {
        final na = a.numero ?? 999;
        final nb = b.numero ?? 999;
        return na != nb ? na.compareTo(nb) : a.nome.compareTo(b.nome);
      });
      return jogadores;
    }
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
    if (FirestoreCompatIds.habilitado) {
      final clubeDoc = await _docPorId('clubes', clubeId);
      if (clubeDoc == null) return;
      await _firestore.collection('clubeJogadores').add({
        'clubeId': clubeDoc.id,
        'nome': nome.trim(),
        'posicao': posicao,
        'numero': numero,
        'posX': null,
        'posY': null,
        'donoId': FirestoreCompatIds.usuarioUid,
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return;
    }
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
    if (FirestoreCompatIds.habilitado) {
      final doc = await _docPorId('clubeJogadores', id);
      if (doc != null) await doc.reference.delete();
      return;
    }
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
    if (FirestoreCompatIds.habilitado) {
      final batch = _firestore.batch();
      for (final j in jogadores) {
        final doc = await _docPorId('clubeJogadores', j.id);
        if (doc == null) continue;
        batch.update(doc.reference, {'posX': j.posX, 'posY': j.posY});
      }
      await batch.commit();
      return;
    }
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
    if (FirestoreCompatIds.habilitado) {
      final docs = await _firestore.collection('confrontos').get();
      return docs.docs.map(_confrontoDeDoc).toList()
        ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    }
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.confrontos);
    }
    final conn = await _conn;
    final r = await conn.execute('$_selectConfronto ORDER BY cf.data_hora');
    return r.map((e) => Confronto.fromRow(e.toColumnMap())).toList();
  }

  Future<List<Confronto>> confrontosDaLiga(int ligaId) async {
    if (FirestoreCompatIds.habilitado) {
      final ligaDoc = await _docPorId('ligas', ligaId);
      if (ligaDoc == null) return const [];
      final docs = await _firestore
          .collection('confrontos')
          .where('ligaId', isEqualTo: ligaDoc.id)
          .get();
      return docs.docs.map(_confrontoDeDoc).toList()
        ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    }
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
    if (FirestoreCompatIds.habilitado) {
      final casaDoc = await _docPorId('clubes', clubeCasaId);
      final visitanteDoc = await _docPorId('clubes', clubeVisitanteId);
      if (casaDoc == null || visitanteDoc == null) return 0;
      final casa = casaDoc.data() ?? const {};
      final visitante = visitanteDoc.data() ?? const {};
      String? ligaDocId;
      if (ligaId != null) {
        ligaDocId = (await _docPorId('ligas', ligaId))?.id;
      }
      final ref = await _firestore.collection('confrontos').add({
        'ligaId': ligaDocId,
        'clubeCasaId': casaDoc.id,
        'clubeCasaNome': casa['nome'],
        'clubeCasaCor': casa['cor'] ?? '#1B3A6B',
        'clubeVisitanteId': visitanteDoc.id,
        'clubeVisitanteNome': visitante['nome'],
        'clubeVisitanteCor': visitante['cor'] ?? '#C0392B',
        'dataHora': Timestamp.fromDate(dataHora),
        'tipo': tipo,
        'local': local,
        'status': ConfrontoStatus.agendado,
        'placarCasa': null,
        'placarVisitante': null,
        'donoId': FirestoreCompatIds.usuarioUid,
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return FirestoreCompatIds.registrar('confrontos', ref.id);
    }
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
    if (FirestoreCompatIds.habilitado) {
      final doc = await _docPorId('confrontos', confrontoId);
      if (doc == null) return;
      await doc.reference.update({
        'placarCasa': placarCasa,
        'placarVisitante': placarVisitante,
        'status': ConfrontoStatus.realizado,
      });
      return;
    }
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
    if (FirestoreCompatIds.habilitado) {
      final doc = await _docPorId('confrontos', confrontoId);
      if (doc == null) return;
      await doc.reference.update({'status': ConfrontoStatus.cancelado});
      return;
    }
    if (confrontoId < 0) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named("UPDATE confronto SET status = 'CANCELADO' WHERE id = @id"),
      parameters: {'id': confrontoId},
    );
  }

  // ---- Ligas ----
  Future<List<Liga>> listarLigas() async {
    if (FirestoreCompatIds.habilitado) {
      final ligaDocs = await _firestore.collection('ligas').get();
      final membros = await _firestore.collection('ligaClubes').get();
      final contagem = <String, int>{};
      for (final m in membros.docs) {
        final lid = m.data()['ligaId'] as String?;
        if (lid != null) contagem[lid] = (contagem[lid] ?? 0) + 1;
      }
      return ligaDocs.docs.map((d) {
        final m = d.data();
        return Liga(
          id: FirestoreCompatIds.registrar('ligas', d.id),
          nome: (m['nome'] as String?) ?? '',
          cidade: m['cidade'] as String?,
          totalTimes: contagem[d.id] ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));
    }
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
    if (FirestoreCompatIds.habilitado) {
      final ref = await _firestore.collection('ligas').add({
        'nome': nome.trim(),
        'cidade': cidade?.trim(),
        'donoId': FirestoreCompatIds.usuarioUid,
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return FirestoreCompatIds.registrar('ligas', ref.id);
    }
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
    if (FirestoreCompatIds.habilitado) {
      final ligaDoc = await _docPorId('ligas', ligaId);
      if (ligaDoc == null) return const [];
      final docs = await _firestore
          .collection('ligaClubes')
          .where('ligaId', isEqualTo: ligaDoc.id)
          .get();
      return docs.docs.map((d) {
        final m = d.data();
        return Clube(
          id: FirestoreCompatIds.registrar(
              'clubes', (m['clubeId'] as String?) ?? ''),
          nome: (m['nome'] as String?) ?? '',
          cidade: m['cidade'] as String?,
          cor: (m['cor'] as String?) ?? '#1B3A6B',
        );
      }).toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));
    }
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
    if (FirestoreCompatIds.habilitado) {
      final ligaDoc = await _docPorId('ligas', ligaId);
      if (ligaDoc == null) return const [];
      final membros = await _firestore
          .collection('ligaClubes')
          .where('ligaId', isEqualTo: ligaDoc.id)
          .get();
      final dentro = membros.docs
          .map((d) => d.data()['clubeId'] as String?)
          .whereType<String>()
          .toSet();
      final docs = await _firestore.collection('clubes').get();
      return docs.docs
          .where((d) => !dentro.contains(d.id))
          .map(_clubeDeDoc)
          .toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));
    }
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
    if (FirestoreCompatIds.habilitado) {
      final ligaDoc = await _docPorId('ligas', ligaId);
      final clubeDoc = await _docPorId('clubes', clubeId);
      if (ligaDoc == null || clubeDoc == null) return;
      final m = clubeDoc.data() ?? const {};
      await _firestore
          .collection('ligaClubes')
          .doc('${ligaDoc.id}_${clubeDoc.id}')
          .set({
        'ligaId': ligaDoc.id,
        'clubeId': clubeDoc.id,
        'nome': m['nome'],
        'cidade': m['cidade'],
        'cor': m['cor'] ?? '#1B3A6B',
        'donoId': FirestoreCompatIds.usuarioUid,
      });
      return;
    }
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
    if (FirestoreCompatIds.habilitado) {
      final ligaDoc = await _docPorId('ligas', ligaId);
      final clubeDoc = await _docPorId('clubes', clubeId);
      if (ligaDoc == null || clubeDoc == null) return;
      await _firestore
          .collection('ligaClubes')
          .doc('${ligaDoc.id}_${clubeDoc.id}')
          .delete();
      return;
    }
    if (ligaId < 0 || clubeId < 0 || Sessao.instance.isAdminLocal) return;
    final conn = await _conn;
    await conn.execute(
      Sql.named('DELETE FROM liga_clube WHERE liga_id = @l AND clube_id = @c'),
      parameters: {'l': ligaId, 'c': clubeId},
    );
  }

  /// Tabela de classificação da liga (a partir dos confrontos REALIZADOS).
  Future<List<LinhaClassificacao>> classificacao(int ligaId) async {
    if (FirestoreCompatIds.habilitado) {
      return _classificacaoFirestore(ligaId);
    }
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

  Future<List<LinhaClassificacao>> _classificacaoFirestore(int ligaId) async {
    final ligaDoc = await _docPorId('ligas', ligaId);
    if (ligaDoc == null) return const [];

    // Clubes da liga (com nome/cor denormalizados em ligaClubes).
    final membros = await _firestore
        .collection('ligaClubes')
        .where('ligaId', isEqualTo: ligaDoc.id)
        .get();
    final stats = <String, _StatClassificacao>{};
    for (final d in membros.docs) {
      final m = d.data();
      final clubeDocId = (m['clubeId'] as String?) ?? '';
      stats[clubeDocId] = _StatClassificacao(
        nome: (m['nome'] as String?) ?? '',
        cor: (m['cor'] as String?) ?? '#1B3A6B',
      );
    }

    // Confrontos da liga (filtra REALIZADO em memória p/ evitar índice composto).
    final confrontos = await _firestore
        .collection('confrontos')
        .where('ligaId', isEqualTo: ligaDoc.id)
        .get();
    for (final d in confrontos.docs) {
      final m = d.data();
      if (m['status'] != ConfrontoStatus.realizado) continue;
      final casa = m['clubeCasaId'] as String?;
      final visitante = m['clubeVisitanteId'] as String?;
      final pc = (m['placarCasa'] as num?)?.toInt();
      final pv = (m['placarVisitante'] as num?)?.toInt();
      if (casa == null || visitante == null || pc == null || pv == null) {
        continue;
      }
      stats[casa]?.aplicar(pc, pv);
      stats[visitante]?.aplicar(pv, pc);
    }

    final linhas = stats.entries.map((entrada) {
      final s = entrada.value;
      return LinhaClassificacao(
        clubeId: FirestoreCompatIds.registrar('clubes', entrada.key),
        nome: s.nome,
        cor: s.cor,
        jogos: s.jogos,
        vitorias: s.vitorias,
        empates: s.empates,
        derrotas: s.derrotas,
        golsPro: s.golsPro,
        golsContra: s.golsContra,
        saldo: s.golsPro - s.golsContra,
        pontos: s.vitorias * 3 + s.empates,
      );
    }).toList();
    linhas.sort((a, b) {
      if (b.pontos != a.pontos) return b.pontos.compareTo(a.pontos);
      if (b.saldo != a.saldo) return b.saldo.compareTo(a.saldo);
      if (b.golsPro != a.golsPro) return b.golsPro.compareTo(a.golsPro);
      return a.nome.compareTo(b.nome);
    });
    return linhas;
  }

  // ---- Helpers Firestore ----
  Future<DocumentSnapshot<Map<String, dynamic>>?> _docPorId(
      String colecao, int id) async {
    final conhecido = FirestoreCompatIds.documento(colecao, id);
    final ref = _firestore.collection(colecao);
    if (conhecido != null) {
      final d = await ref.doc(conhecido).get();
      if (d.exists) return d;
    }
    final docs = await ref.get();
    for (final d in docs.docs) {
      if (FirestoreCompatIds.registrar(colecao, d.id) == id) return d;
    }
    return null;
  }

  Clube _clubeDeDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return Clube(
      id: FirestoreCompatIds.registrar('clubes', d.id),
      nome: (m['nome'] as String?) ?? '',
      cidade: m['cidade'] as String?,
      cor: (m['cor'] as String?) ?? '#1B3A6B',
    );
  }

  Confronto _confrontoDeDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return Confronto(
      id: FirestoreCompatIds.registrar('confrontos', d.id),
      clubeCasaId: FirestoreCompatIds.registrar(
          'clubes', (m['clubeCasaId'] as String?) ?? ''),
      clubeCasaNome: (m['clubeCasaNome'] as String?) ?? '',
      clubeCasaCor: (m['clubeCasaCor'] as String?) ?? '#1B3A6B',
      clubeVisitanteId: FirestoreCompatIds.registrar(
          'clubes', (m['clubeVisitanteId'] as String?) ?? ''),
      clubeVisitanteNome: (m['clubeVisitanteNome'] as String?) ?? '',
      clubeVisitanteCor: (m['clubeVisitanteCor'] as String?) ?? '#C0392B',
      dataHora: _dataHora(m['dataHora']),
      tipo: (m['tipo'] as String?) ?? 'AMISTOSO',
      local: m['local'] as String?,
      status: (m['status'] as String?) ?? ConfrontoStatus.agendado,
      placarCasa: (m['placarCasa'] as num?)?.toInt(),
      placarVisitante: (m['placarVisitante'] as num?)?.toInt(),
    );
  }

  DateTime _dataHora(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor?.toString() ?? '') ?? DateTime.now();
  }
}

class _StatClassificacao {
  final String nome;
  final String cor;
  int jogos = 0;
  int vitorias = 0;
  int empates = 0;
  int derrotas = 0;
  int golsPro = 0;
  int golsContra = 0;

  _StatClassificacao({required this.nome, required this.cor});

  void aplicar(int gp, int gc) {
    jogos++;
    golsPro += gp;
    golsContra += gc;
    if (gp > gc) {
      vitorias++;
    } else if (gp == gc) {
      empates++;
    } else {
      derrotas++;
    }
  }
}
