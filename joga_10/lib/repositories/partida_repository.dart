import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/sessao.dart';

class PartidaRepository implements PartidaRepositoryContract {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  PartidaRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

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
    List<PartidaMembro> membros = const [],
  }) async {
    if (FirestoreCompatIds.habilitado) {
      return _criarFirestore(
        idEstabelecimento: idEstabelecimento,
        idQuadra: idQuadra,
        organizadorId: organizadorId,
        duracao: duracao,
        dataHora: dataHora,
        status: status,
        preco: preco,
        membros: membros,
      );
    }
    if (organizadorId == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      final quadra = demo.quadras.where((q) => q.id == idQuadra).firstOrNull;
      final estab = demo.estabelecimentos
          .where((e) => e.id == idEstabelecimento)
          .firstOrNull;
      final id = demo.novoId();
      final membrosComId = membros
          .map(
            (membro) => PartidaMembro(
              id: membro.id ?? demo.novoId(),
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
          dataHora: dataHora,
          status: status,
          preco: preco,
          membros: membrosComId,
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
    if (FirestoreCompatIds.habilitado) return _listarFirestore();
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.partidas);
    }
    final conn = await _conn;
    final rows = await conn.execute('$_selectBase ORDER BY p.data_hora DESC');
    return _montarComMembros(conn, rows);
  }

  @override
  Future<List<Partida>> listarPorUsuario(int userId) async {
    if (FirestoreCompatIds.habilitado) return _listarFirestore();
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
    if (FirestoreCompatIds.habilitado) {
      return (await _listarFirestore())
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
        formato: formato,
        formacaoTime1: formacaoTime1,
        formacaoTime2: formacaoTime2,
        placarTime1: atual.placarTime1,
        placarTime2: atual.placarTime2,
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
    required DateTime dataHora,
    required String status,
    required double preco,
    required List<PartidaMembro> membros,
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
    final referencia = _firestore.collection('partidas').doc();
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
      'formato': '5x5',
      'ambiente': 'DEMO',
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    for (final membro in membros) {
      final membroRef = referencia.collection('membros').doc();
      batch.set(membroRef, {
        'usuarioId':
            membro.idUser == null ? null : FirestoreCompatIds.usuarioUid,
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
    return FirestoreCompatIds.registrar('partidas', referencia.id);
  }

  Future<List<Partida>> _listarFirestore() async {
    final documentos = await _firestore.collection('partidas').get();
    final partidas = await Future.wait(documentos.docs.map(_partidaFirestore));
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
    final documentos = await _firestore.collection('partidas').get();
    for (final documento in documentos.docs) {
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
      formato: (dados['formato'] as String?) ?? '5x5',
      formacaoTime1: dados['formacaoTime1'] as String?,
      formacaoTime2: dados['formacaoTime2'] as String?,
      placarTime1: (dados['placarTime1'] as num?)?.toInt(),
      placarTime2: (dados['placarTime2'] as num?)?.toInt(),
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
    await partida.reference.collection('membros').add({
      'usuarioId': idUser == null ? null : FirestoreCompatIds.usuarioUid,
      'nome': nome,
      'telefone': telefone,
      'equipe': equipe,
      'gols': 0,
      'ambiente': 'DEMO',
      'criadoEm': FieldValue.serverTimestamp(),
    });
    await partida.reference
        .update({'atualizadoEm': FieldValue.serverTimestamp()});
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
}
