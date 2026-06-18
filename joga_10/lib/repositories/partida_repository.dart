import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/domain/services/recorrencia_partida.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/util/convite_privado.dart';

class PartidaRepository implements PartidaRepositoryContract {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;
  final RecorrenciaPartida _recorrencia;

  PartidaRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
    RecorrenciaPartida recorrencia = const RecorrenciaPartida(),
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore,
        _recorrencia = recorrencia;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

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
    String visibilidade = VisibilidadePartida.publica,
    String modalidade = ModalidadePartida.futebol,
    String? formato,
    List<PartidaMembro> membros = const [],
    String recorrencia = TipoRecorrenciaPartida.nenhuma,
    DateTime? recorrenciaAte,
  }) async {
    final datas = _recorrencia.gerarDatas(
      inicio: dataHora,
      tipo: recorrencia,
      ate: recorrenciaAte,
    );
    final grupoRecorrencia = datas.length > 1
        ? '${organizadorId}_${DateTime.now().microsecondsSinceEpoch}'
        : null;
    final formatoPartida =
        formato ?? ModalidadePartida.formatoPadrao(modalidade);
    if (FirestoreCompatIds.habilitado) {
      return _criarFirestore(
        idEstabelecimento: idEstabelecimento,
        idQuadra: idQuadra,
        organizadorId: organizadorId,
        duracao: duracao,
        datas: datas,
        status: status,
        preco: preco,
        visibilidade: visibilidade,
        modalidade: modalidade,
        formato: formatoPartida,
        membros: membros,
        recorrencia: recorrencia,
        recorrenciaAte: recorrenciaAte,
        grupoRecorrencia: grupoRecorrencia,
      );
    }
    if (organizadorId == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      final quadra = demo.quadras.where((q) => q.id == idQuadra).firstOrNull;
      final estab = demo.estabelecimentos
          .where((e) => e.id == idEstabelecimento)
          .firstOrNull;
      int? primeiraPartidaId;
      for (final data in datas.reversed) {
        final id = demo.novoId();
        if (data == datas.first) primeiraPartidaId = id;
        final membrosComId = membros
            .map(
              (membro) => PartidaMembro(
                id: demo.novoId(),
                partidaId: id,
                idUser: membro.idUser,
                telefone: membro.telefone,
                equipe: membro.equipe,
                nome: membro.nome,
                posX: membro.posX,
                posY: membro.posY,
                gols: membro.gols,
              ),
            )
            .toList();
        demo.partidas.insert(
          0,
          Partida(
            id: id,
            idEstabelecimento: idEstabelecimento,
            idQuadra: idQuadra,
            organizadorId: organizadorId,
            duracao: duracao,
            dataHora: data,
            status: status,
            preco: preco,
            visibilidade: visibilidade,
            modalidade: modalidade,
            formato: formatoPartida,
            membros: membrosComId,
            quadraNome: quadra?.nome,
            estabelecimentoNome: estab?.nome,
            grupoRecorrencia: grupoRecorrencia,
            recorrencia: recorrencia,
            recorrenciaAte: recorrenciaAte,
          ),
        );
      }
      return primeiraPartidaId!;
    }
    final conn = await _conn;
    return conn.runTx((tx) async {
      int? primeiraPartidaId;
      for (final data in datas) {
        final res = await tx.execute(
          Sql.named('''
            INSERT INTO partida
              (id_estabelecimento, id_quadra, organizador_id,
               duracao, data_hora, status, preco, visibilidade,
               modalidade, formato,
               grupo_recorrencia,
               recorrencia, recorrencia_ate)
            VALUES
              (@id_estabelecimento, @id_quadra, @organizador_id,
               @duracao, @data_hora, @status, @preco, @visibilidade,
               @modalidade, @formato,
               @grupo_recorrencia,
               @recorrencia, @recorrencia_ate)
            RETURNING id
          '''),
          parameters: {
            'id_estabelecimento': idEstabelecimento,
            'id_quadra': idQuadra,
            'organizador_id': organizadorId,
            'duracao': duracao,
            'data_hora': data,
            'status': status,
            'preco': preco,
            'visibilidade': visibilidade,
            'modalidade': modalidade,
            'formato': formatoPartida,
            'grupo_recorrencia': grupoRecorrencia,
            'recorrencia': recorrencia,
            'recorrencia_ate': recorrenciaAte,
          },
        );
        final partidaId = res.first.toColumnMap()['id'] as int;
        primeiraPartidaId ??= partidaId;

        for (final m in membros) {
          await tx.execute(
            Sql.named('''
              INSERT INTO partida_membro
                (partida_id, id_user, equipe, nome, telefone)
              VALUES
                (@partida_id, @id_user, @equipe, @nome, @telefone)
            '''),
            parameters: {
              'partida_id': partidaId,
              'id_user': m.idUser,
              'equipe': m.equipe,
              'nome': m.nome,
              'telefone': m.telefone,
            },
          );
        }
      }
      return primeiraPartidaId!;
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
    if (FirestoreCompatIds.habilitado) return _listarFirestoreAcessiveis();
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.partidas);
    }
    final conn = await _conn;
    final rows = await conn.execute('$_selectBase ORDER BY p.data_hora DESC');
    return _montarComMembros(conn, rows);
  }

  @override
  Future<List<Partida>> listarPorUsuario(int userId) async {
    if (FirestoreCompatIds.habilitado) return _listarFirestorePorUsuario();
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
  Future<List<Partida>> listarPublicas() async {
    if (FirestoreCompatIds.habilitado) return _listarFirestorePublicas();
    if (Sessao.instance.isAdminLocal) {
      return LocalDemoData.instance.partidas
          .where((partida) =>
              partida.publica &&
              (partida.status == PartidaStatus.agendada ||
                  partida.status == PartidaStatus.emAndamento))
          .toList();
    }
    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('''
        $_selectBase
        WHERE p.visibilidade = @visibilidade
          AND p.status IN ('AGENDADA', 'EM_ANDAMENTO')
        ORDER BY p.data_hora ASC
      '''),
      parameters: {'visibilidade': VisibilidadePartida.publica},
    );
    return _montarComMembros(conn, rows);
  }

  @override
  Future<List<Partida>> listarPorUsuarioEStatus(
      int userId, String status) async {
    if (FirestoreCompatIds.habilitado) {
      return (await _listarFirestorePorUsuario())
          .where((partida) => partida.status == status)
          .toList();
    }
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
    if (FirestoreCompatIds.habilitado) return _buscarFirestore(id);
    if (id < 0) {
      final partida = LocalDemoData.instance.buscarPartida(id);
      return await _podeAcessarPartida(partida) ? partida : null;
    }
    final conn = await _conn;
    final rows = await conn.execute(
      Sql.named('$_selectBase WHERE p.id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    final map = rows.first.toColumnMap();
    final membros = await _carregarMembros(conn, id);
    final partida = Partida.fromRow(map, membros: membros);
    return await _podeAcessarPartida(partida) ? partida : null;
  }

  Future<bool> _podeAcessarPartida(Partida? partida) async {
    if (partida == null) return false;
    if (partida.publica) return true;
    final usuarioId = await Sessao.instance.usuarioId;
    if (usuarioId == null) return false;
    return partida.organizadorId == usuarioId ||
        partida.membros.any((membro) => membro.idUser == usuarioId);
  }

  @override
  Future<bool> atualizarStatus(int id, String status) async {
    if (FirestoreCompatIds.habilitado) {
      final documento = await _documentoPartida(id);
      if (documento == null) return false;
      await documento.reference.update({
        'status': status,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      return true;
    }
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
    if (FirestoreCompatIds.habilitado) {
      return _finalizarFirestore(
        partidaId: partidaId,
        placarTime1: placarTime1,
        placarTime2: placarTime2,
        golsPorMembro: golsPorMembro,
      );
    }
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
                telefone: m.telefone,
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
    if (FirestoreCompatIds.habilitado) {
      return _salvarEscalacaoFirestore(
        partidaId: partidaId,
        formato: formato,
        formacaoTime1: formacaoTime1,
        formacaoTime2: formacaoTime2,
        membros: membros,
      );
    }
    if (partidaId < 0) {
      final demo = LocalDemoData.instance;
      final index = demo.partidas.indexWhere((p) => p.id == partidaId);
      if (index < 0) return;
      final atual = demo.partidas[index];
      final atualizados = membros.map((membro) {
        final anterior =
            atual.membros.where((item) => item.id == membro.id).firstOrNull;
        return PartidaMembro(
          id: membro.id,
          partidaId: partidaId,
          idUser: anterior?.idUser,
          telefone: anterior?.telefone,
          equipe: membro.equipe,
          nome: membro.nome,
          posX: membro.posX,
          posY: membro.posY,
          gols: anterior?.gols ?? 0,
        );
      }).toList();
      demo.partidas[index] = Partida(
        id: atual.id,
        idEstabelecimento: atual.idEstabelecimento,
        idQuadra: atual.idQuadra,
        organizadorId: atual.organizadorId,
        duracao: atual.duracao,
        dataHora: atual.dataHora,
        status: atual.status,
        preco: atual.preco,
        visibilidade: atual.visibilidade,
        modalidade: atual.modalidade,
        formato: formato,
        formacaoTime1: formacaoTime1,
        formacaoTime2: formacaoTime2,
        placarTime1: atual.placarTime1,
        placarTime2: atual.placarTime2,
        grupoRecorrencia: atual.grupoRecorrencia,
        recorrencia: atual.recorrencia,
        recorrenciaAte: atual.recorrenciaAte,
        membros: atualizados,
        quadraNome: atual.quadraNome,
        estabelecimentoNome: atual.estabelecimentoNome,
      );
      return;
    }
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
    String? telefone,
  }) async {
    if (FirestoreCompatIds.habilitado) {
      return _adicionarMembroFirestore(
        partidaId: partidaId,
        idUser: idUser,
        equipe: equipe,
        nome: nome,
        telefone: telefone,
      );
    }
    if (partidaId < 0) {
      LocalDemoData.instance.adicionarMembro(
        partidaId: partidaId,
        idUser: idUser,
        equipe: equipe,
        nome: nome,
        telefone: telefone,
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

  Future<int> _criarFirestore({
    int? idEstabelecimento,
    int? idQuadra,
    required int organizadorId,
    String? duracao,
    required List<DateTime> datas,
    required String status,
    required double preco,
    required String visibilidade,
    required String modalidade,
    required String formato,
    required List<PartidaMembro> membros,
    required String recorrencia,
    required DateTime? recorrenciaAte,
    required String? grupoRecorrencia,
  }) async {
    final estabelecimentoId = idEstabelecimento == null
        ? null
        : FirestoreCompatIds.documento('estabelecimentos', idEstabelecimento);
    final quadraId = idQuadra == null
        ? null
        : FirestoreCompatIds.documento('quadras', idQuadra);
    final estabelecimento = estabelecimentoId == null
        ? null
        : await _firestore
            .collection('estabelecimentos')
            .doc(estabelecimentoId)
            .get();
    final quadra = quadraId == null
        ? null
        : await _firestore.collection('quadras').doc(quadraId).get();
    final participantesUids = membros
        .map((membro) => _uidDoUsuario(membro.idUser))
        .whereType<String>()
        .toSet()
      ..addAll([
        if (FirestoreCompatIds.usuarioUid != null)
          FirestoreCompatIds.usuarioUid!,
      ]);
    final conviteContatoKeys = visibilidade == VisibilidadePartida.privada
        ? membros
            .map((membro) => chaveContatoConvite(membro.telefone))
            .whereType<String>()
            .toSet()
            .toList()
        : const <String>[];
    DocumentReference<Map<String, dynamic>>? primeiraReferencia;
    for (final dataHora in datas) {
      final referencia = _firestore.collection('partidas').doc();
      primeiraReferencia ??= referencia;
      final batch = _firestore.batch();
      batch.set(referencia, {
        'organizadorId': FirestoreCompatIds.usuarioUid,
        'estabelecimentoId': estabelecimentoId,
        'estabelecimentoNome': estabelecimento?.data()?['nome'],
        'quadraId': quadraId,
        'quadraNome': quadra?.data()?['nome'],
        'duracao': duracao,
        'dataHora': Timestamp.fromDate(dataHora),
        'status': status,
        'preco': preco,
        'visibilidade': visibilidade,
        'participantesUids': participantesUids.toList(),
        if (conviteContatoKeys.isNotEmpty)
          'conviteContatoKeys': conviteContatoKeys,
        'modalidade': modalidade,
        'formato': formato,
        'grupoRecorrencia': grupoRecorrencia,
        'recorrencia': recorrencia,
        'recorrenciaAte':
            recorrenciaAte == null ? null : Timestamp.fromDate(recorrenciaAte),
        'ambiente': 'DEMO',
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      for (final membro in membros) {
        final membroRef = referencia.collection('membros').doc();
        final membroUid = _uidDoUsuario(membro.idUser);
        batch.set(membroRef, {
          'usuarioId': membroUid,
          // Denormalizado para as regras de segurança (sem get() no batch).
          'organizadorId': FirestoreCompatIds.usuarioUid,
          'nome': membro.nome,
          'telefone': membro.telefone,
          'equipe': membro.equipe,
          'posX': membro.posX,
          'posY': membro.posY,
          'gols': membro.gols,
          'ambiente': 'DEMO',
        });
      }
      await batch.commit();
    }
    return FirestoreCompatIds.registrar('partidas', primeiraReferencia!.id);
  }

  Future<List<Partida>> _listarFirestorePublicas() async {
    final documentos = await _firestore
        .collection('partidas')
        .where('visibilidade', isEqualTo: VisibilidadePartida.publica)
        .get();
    final partidas = await Future.wait(
      documentos.docs.map(_partidaFirestore),
    );
    partidas.removeWhere((partida) =>
        partida.status != PartidaStatus.agendada &&
        partida.status != PartidaStatus.emAndamento);
    partidas.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return partidas;
  }

  Future<List<Partida>> _listarFirestorePorUsuario() async {
    final uid = FirestoreCompatIds.usuarioUid;
    if (uid == null) return const [];
    final conviteContatoKey = await _conviteContatoKeyAtual();
    final colecao = _firestore.collection('partidas');
    final consultas = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      colecao.where('organizadorId', isEqualTo: uid).get(),
      colecao.where('participantesUids', arrayContains: uid).get(),
      if (conviteContatoKey != null)
        colecao
            .where('conviteContatoKeys', arrayContains: conviteContatoKey)
            .get(),
    ];
    final resultados = await Future.wait(consultas);
    final documentos = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final resultado in resultados) {
      for (final documento in resultado.docs) {
        documentos[documento.id] = documento;
      }
    }
    final partidas = await Future.wait(
      documentos.values.map(_partidaFirestore),
    );
    partidas.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return partidas;
  }

  Future<List<Partida>> _listarFirestoreAcessiveis() async {
    final publicas = await _listarFirestorePublicas();
    final minhas = await _listarFirestorePorUsuario();
    final partidas = <int, Partida>{
      for (final partida in publicas) partida.id: partida,
      for (final partida in minhas) partida.id: partida,
    }.values.toList();
    partidas.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return partidas;
  }

  Future<Partida?> _buscarFirestore(int id) async {
    final documento = await _documentoPartida(id);
    return documento == null ? null : _partidaFirestore(documento);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _documentoPartida(
      int id) async {
    final conhecido = FirestoreCompatIds.documento('partidas', id);
    if (conhecido != null) {
      final documento =
          await _firestore.collection('partidas').doc(conhecido).get();
      if (documento.exists) return documento;
    }
    final uid = FirestoreCompatIds.usuarioUid;
    final conviteContatoKey = await _conviteContatoKeyAtual();
    final colecao = _firestore.collection('partidas');
    final resultados = await Future.wait([
      colecao
          .where('visibilidade', isEqualTo: VisibilidadePartida.publica)
          .get(),
      if (uid != null) colecao.where('organizadorId', isEqualTo: uid).get(),
      if (uid != null)
        colecao.where('participantesUids', arrayContains: uid).get(),
      if (conviteContatoKey != null)
        colecao
            .where('conviteContatoKeys', arrayContains: conviteContatoKey)
            .get(),
    ]);
    final documentos = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final resultado in resultados) {
      for (final documento in resultado.docs) {
        documentos[documento.id] = documento;
      }
    }
    for (final documento in documentos.values) {
      if (FirestoreCompatIds.registrar('partidas', documento.id) == id) {
        return documento;
      }
    }
    return null;
  }

  Future<Partida> _partidaFirestore(
    DocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final dados = documento.data() ?? const <String, dynamic>{};
    final partidaId = FirestoreCompatIds.registrar('partidas', documento.id);
    final estabelecimentoId = dados['estabelecimentoId'] as String?;
    final quadraId = dados['quadraId'] as String?;
    final organizadorId = dados['organizadorId'] as String?;
    final estabelecimento = estabelecimentoId == null
        ? null
        : await _firestore
            .collection('estabelecimentos')
            .doc(estabelecimentoId)
            .get();
    final quadra = quadraId == null
        ? null
        : await _firestore.collection('quadras').doc(quadraId).get();
    final membros = await _membrosFirestore(documento.id, partidaId);
    return Partida(
      id: partidaId,
      idEstabelecimento: estabelecimentoId == null
          ? null
          : FirestoreCompatIds.registrar('estabelecimentos', estabelecimentoId),
      idQuadra: quadraId == null
          ? null
          : FirestoreCompatIds.registrar('quadras', quadraId),
      organizadorId: organizadorId == FirestoreCompatIds.usuarioUid
          ? (Sessao.instance.atual?.id ?? LocalDemoData.adminId)
          : FirestoreCompatIds.registrar('usuarios', organizadorId ?? 'demo'),
      duracao: dados['duracao'] as String?,
      dataHora: _dataHora(dados['dataHora']),
      status: (dados['status'] as String?) ?? PartidaStatus.agendada,
      preco: (dados['preco'] as num?)?.toDouble() ?? 0,
      visibilidade:
          (dados['visibilidade'] as String?) ?? VisibilidadePartida.publica,
      modalidade: (dados['modalidade'] as String?) ?? ModalidadePartida.futebol,
      formato: (dados['formato'] as String?) ??
          ModalidadePartida.formatoPadrao(
            (dados['modalidade'] as String?) ?? ModalidadePartida.futebol,
          ),
      formacaoTime1: dados['formacaoTime1'] as String?,
      formacaoTime2: dados['formacaoTime2'] as String?,
      placarTime1: (dados['placarTime1'] as num?)?.toInt(),
      placarTime2: (dados['placarTime2'] as num?)?.toInt(),
      grupoRecorrencia: dados['grupoRecorrencia'] as String?,
      recorrencia:
          (dados['recorrencia'] as String?) ?? TipoRecorrenciaPartida.nenhuma,
      recorrenciaAte: _dataHoraOpcional(dados['recorrenciaAte']),
      membros: membros,
      quadraNome: (quadra?.data()?['nome'] as String?) ??
          dados['quadraNome'] as String?,
      estabelecimentoNome: (estabelecimento?.data()?['nome'] as String?) ??
          dados['estabelecimentoNome'] as String?,
    );
  }

  Future<List<PartidaMembro>> _membrosFirestore(
    String partidaDocumentoId,
    int partidaId,
  ) async {
    final documentos = await _firestore
        .collection('partidas')
        .doc(partidaDocumentoId)
        .collection('membros')
        .get();
    final registro = _registroMembros(partidaDocumentoId);
    return documentos.docs.map((documento) {
      final dados = documento.data();
      final usuarioId = dados['usuarioId'] as String?;
      return PartidaMembro(
        id: FirestoreCompatIds.registrar(registro, documento.id),
        partidaId: partidaId,
        idUser: usuarioId == null
            ? null
            : usuarioId == FirestoreCompatIds.usuarioUid
                ? Sessao.instance.atual?.id
                : FirestoreCompatIds.registrar('usuarios', usuarioId),
        telefone: dados['telefone'] as String?,
        equipe: (dados['equipe'] as String?) ?? Equipe.time1,
        nome: (dados['nome'] as String?) ?? '',
        posX: (dados['posX'] as num?)?.toDouble(),
        posY: (dados['posY'] as num?)?.toDouble(),
        gols: (dados['gols'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> _finalizarFirestore({
    required int partidaId,
    required int placarTime1,
    required int placarTime2,
    required Map<int, int> golsPorMembro,
  }) async {
    final partida = await _documentoPartida(partidaId);
    if (partida == null) return;
    final batch = _firestore.batch();
    batch.update(partida.reference, {
      'status': PartidaStatus.finalizada,
      'placarTime1': placarTime1,
      'placarTime2': placarTime2,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    for (final gol in golsPorMembro.entries) {
      final membro = await _documentoMembro(partida.id, gol.key);
      if (membro != null) batch.update(membro.reference, {'gols': gol.value});
    }
    await batch.commit();
  }

  Future<void> _salvarEscalacaoFirestore({
    required int partidaId,
    required String formato,
    String? formacaoTime1,
    String? formacaoTime2,
    required List<PartidaMembro> membros,
  }) async {
    final partida = await _documentoPartida(partidaId);
    if (partida == null) return;
    final batch = _firestore.batch();
    batch.update(partida.reference, {
      'formato': formato,
      'formacaoTime1': formacaoTime1,
      'formacaoTime2': formacaoTime2,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    for (final membro in membros) {
      if (membro.id == null) continue;
      final documento = await _documentoMembro(partida.id, membro.id!);
      if (documento == null) continue;
      batch.update(documento.reference, {
        'equipe': membro.equipe,
        'posX': membro.posX,
        'posY': membro.posY,
      });
    }
    await batch.commit();
  }

  Future<void> _adicionarMembroFirestore({
    required int partidaId,
    int? idUser,
    required String equipe,
    required String nome,
    String? telefone,
  }) async {
    final partida = await _documentoPartida(partidaId);
    if (partida == null) return;
    // organizadorId vem da partida (denormalizado no membro p/ as regras).
    // O próprio usuário que entra grava seu usuarioId; o organizador pode
    // adicionar convidados. NÃO tocamos no doc da partida aqui: isso permitiria
    // que um não-organizador disparasse um update bloqueado pelas regras.
    final organizadorId = partida.data()?['organizadorId'] as String?;
    final visibilidade = partida.data()?['visibilidade'] as String?;
    final membroUid = _uidDoUsuario(idUser);
    final conviteContatoKey = visibilidade == VisibilidadePartida.privada
        ? chaveContatoConvite(telefone)
        : null;
    final membroRef = partida.reference.collection('membros').doc();
    final batch = _firestore.batch();
    batch.set(membroRef, {
      'usuarioId': membroUid,
      'organizadorId': organizadorId,
      'nome': nome,
      'telefone': telefone,
      'equipe': equipe,
      'gols': 0,
      'ambiente': 'DEMO',
      'criadoEm': FieldValue.serverTimestamp(),
    });
    if (membroUid != null) {
      batch.update(partida.reference, {
        'participantesUids': FieldValue.arrayUnion([membroUid]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } else if (conviteContatoKey != null &&
        organizadorId == FirestoreCompatIds.usuarioUid) {
      batch.update(partida.reference, {
        'conviteContatoKeys': FieldValue.arrayUnion([conviteContatoKey]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  String? _uidDoUsuario(int? idUser) {
    if (idUser == null) return null;
    return FirestoreCompatIds.documento('usuarios', idUser) ??
        (idUser == Sessao.instance.atual?.id
            ? FirestoreCompatIds.usuarioUid
            : null);
  }

  Future<String?> _conviteContatoKeyAtual() async {
    final uid = FirestoreCompatIds.usuarioUid;
    if (uid == null) return null;
    final usuario = await _firestore.collection('usuarios').doc(uid).get();
    return usuario.data()?['conviteContatoKey'] as String?;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _documentoMembro(
    String partidaDocumentoId,
    int membroId,
  ) async {
    final registro = _registroMembros(partidaDocumentoId);
    final conhecido = FirestoreCompatIds.documento(registro, membroId);
    final colecao = _firestore
        .collection('partidas')
        .doc(partidaDocumentoId)
        .collection('membros');
    if (conhecido != null) {
      final documento = await colecao.doc(conhecido).get();
      if (documento.exists) return documento;
    }
    final documentos = await colecao.get();
    for (final documento in documentos.docs) {
      if (FirestoreCompatIds.registrar(registro, documento.id) == membroId) {
        return documento;
      }
    }
    return null;
  }

  String _registroMembros(String partidaDocumentoId) =>
      'partidas/$partidaDocumentoId/membros';

  DateTime _dataHora(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor?.toString() ?? '') ?? DateTime.now();
  }

  DateTime? _dataHoraOpcional(dynamic valor) {
    if (valor == null) return null;
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor.toString());
  }
}
