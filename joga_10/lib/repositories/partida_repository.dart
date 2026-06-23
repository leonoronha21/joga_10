import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
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
    SELECT p.*, q.nome AS quadra_nome, e.nome AS estabelecimento_nome,
           trim(u.primeiro_nome || ' ' || coalesce(u.segundo_nome, '')) AS organizador_nome
    FROM partida p
    LEFT JOIN quadra q          ON q.id = p.id_quadra
    LEFT JOIN estabelecimento e ON e.id = p.id_estabelecimento
    LEFT JOIN usuario u         ON u.id = p.organizador_id
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
                capitao: membro.capitao,
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
            organizadorNome: demo.usuarios
                .where((u) => u.id == organizadorId)
                .firstOrNull
                ?.nomeCompleto,
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
                (partida_id, id_user, equipe, nome, telefone, capitao)
              VALUES
                (@partida_id, @id_user, @equipe, @nome, @telefone, @capitao)
            '''),
            parameters: {
              'partida_id': partidaId,
              'id_user': m.idUser,
              'equipe': m.equipe,
              'nome': m.nome,
              'telefone': m.telefone,
              'capitao': m.capitao,
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
    final partida = await buscarPorId(id);
    if (partida == null) return false;
    await _exigirOrganizador(partida);
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
    final partida = await buscarPorId(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    await _exigirOrganizador(partida);
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
                capitao: m.capitao,
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
    String? equipeEditada,
  }) async {
    final partida = await buscarPorId(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    await _validarPermissaoEscalacao(partida, equipeEditada);
    if (FirestoreCompatIds.habilitado) {
      return _salvarEscalacaoFirestore(
        partidaId: partidaId,
        formato: formato,
        formacaoTime1: formacaoTime1,
        formacaoTime2: formacaoTime2,
        membros: membros,
        equipeEditada: equipeEditada,
      );
    }
    if (partidaId < 0) {
      final demo = LocalDemoData.instance;
      final index = demo.partidas.indexWhere((p) => p.id == partidaId);
      if (index < 0) return;
      final atual = demo.partidas[index];
      final atualizados = atual.membros.map((anterior) {
        final membro =
            membros.where((item) => item.id == anterior.id).firstOrNull;
        if (membro == null ||
            (equipeEditada != null && anterior.equipe != equipeEditada)) {
          return anterior;
        }
        return PartidaMembro(
          id: anterior.id,
          partidaId: partidaId,
          idUser: anterior.idUser,
          telefone: anterior.telefone,
          equipe: equipeEditada == null ? membro.equipe : anterior.equipe,
          nome: anterior.nome,
          capitao: anterior.capitao,
          posX: membro.posX,
          posY: membro.posY,
          gols: anterior.gols,
        );
      }).toList();
      demo.partidas[index] = Partida(
        id: atual.id,
        idEstabelecimento: atual.idEstabelecimento,
        idQuadra: atual.idQuadra,
        organizadorId: atual.organizadorId,
        organizadorUid: atual.organizadorUid,
        organizadorNome: atual.organizadorNome,
        duracao: atual.duracao,
        dataHora: atual.dataHora,
        status: atual.status,
        preco: atual.preco,
        visibilidade: atual.visibilidade,
        modalidade: atual.modalidade,
        formato: equipeEditada == null ? formato : atual.formato,
        formacaoTime1:
            equipeEditada == Equipe.time2 ? atual.formacaoTime1 : formacaoTime1,
        formacaoTime2:
            equipeEditada == Equipe.time1 ? atual.formacaoTime2 : formacaoTime2,
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
      if (equipeEditada == null) {
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
      } else {
        final coluna =
            equipeEditada == Equipe.time1 ? 'formacao_time1' : 'formacao_time2';
        final formacao =
            equipeEditada == Equipe.time1 ? formacaoTime1 : formacaoTime2;
        await tx.execute(
          Sql.named('UPDATE partida SET $coluna = @formacao WHERE id = @id'),
          parameters: {'id': partidaId, 'formacao': formacao},
        );
      }
      for (final m in membros) {
        if (m.id == null) continue;
        if (equipeEditada != null && m.equipe != equipeEditada) continue;
        if (equipeEditada == null) {
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
        } else {
          await tx.execute(
            Sql.named('''
              UPDATE partida_membro SET
                pos_x = @px,
                pos_y = @py
              WHERE id = @id AND equipe = @equipe
            '''),
            parameters: {
              'id': m.id,
              'equipe': equipeEditada,
              'px': m.posX,
              'py': m.posY,
            },
          );
        }
      }
    });
  }

  @override
  Future<void> definirCapitao({
    required int partidaId,
    required String equipe,
    required int membroId,
  }) async {
    final partida = await buscarPorId(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    await _exigirOrganizador(partida);
    final membro = partida.membros
        .where((item) => item.id == membroId && item.equipe == equipe)
        .firstOrNull;
    if (membro == null || membro.idUser == null) {
      throw StateError('Escolha um jogador cadastrado no app.');
    }
    if (FirestoreCompatIds.habilitado) {
      return _definirCapitaoFirestore(
        partidaId: partidaId,
        equipe: equipe,
        membroId: membroId,
      );
    }
    if (partidaId < 0) {
      final demo = LocalDemoData.instance;
      final index = demo.partidas.indexWhere((item) => item.id == partidaId);
      if (index < 0) return;
      final atual = demo.partidas[index];
      demo.partidas[index] = demo.copiarPartida(
        atual,
        membros: atual.membros
            .map(
              (item) => item.copyWith(
                capitao: item.equipe == equipe && item.id == membroId,
              ),
            )
            .toList(),
      );
      return;
    }
    final conn = await _conn;
    await conn.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          UPDATE partida_membro
          SET capitao = FALSE
          WHERE partida_id = @partida AND equipe = @equipe
        '''),
        parameters: {
          'partida': partidaId,
          'equipe': equipe,
        },
      );
      await tx.execute(
        Sql.named('''
          UPDATE partida_membro
          SET capitao = TRUE
          WHERE id = @membro AND partida_id = @partida AND equipe = @equipe
        '''),
        parameters: {
          'partida': partidaId,
          'equipe': equipe,
          'membro': membroId,
        },
      );
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
    final partida = await buscarPorId(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    final usuarioId = await Sessao.instance.usuarioId;
    final autoEntrada = idUser != null && idUser == usuarioId;
    if (partida.organizadorId != usuarioId && !autoEntrada) {
      throw StateError(
        'Apenas o criador pode adicionar outros jogadores à partida.',
      );
    }
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

  @override
  Future<void> removerMembro({
    required int partidaId,
    required int membroId,
  }) async {
    final partida = await buscarPorId(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    final usuarioId = await Sessao.instance.usuarioId;
    final membro =
        partida.membros.where((item) => item.id == membroId).firstOrNull;
    if (usuarioId == null || membro == null) {
      throw StateError('Participante não encontrado.');
    }
    if (partida.organizadorId == usuarioId) {
      throw StateError('O criador não pode sair da própria partida.');
    }
    if (membro.idUser != usuarioId) {
      throw StateError('Você só pode sair da sua própria participação.');
    }

    if (FirestoreCompatIds.habilitado) {
      return _removerMembroFirestore(
        partidaId: partidaId,
        membroId: membroId,
        membro: membro,
      );
    }
    if (partidaId < 0) {
      LocalDemoData.instance.removerMembro(
        partidaId: partidaId,
        membroId: membroId,
      );
      return;
    }
    final conn = await _conn;
    await conn.execute(
      Sql.named('''
        DELETE FROM partida_membro
        WHERE id = @membro AND partida_id = @partida AND id_user = @usuario
      '''),
      parameters: {
        'membro': membroId,
        'partida': partidaId,
        'usuario': usuarioId,
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
    final organizadorUid = FirestoreCompatIds.usuarioUid;
    final organizadorNome = Sessao.instance.atual?.nomeCompleto.trim();
    final participantesUids = membros
        .map((membro) => _uidDoUsuario(membro.idUser))
        .whereType<String>()
        .toSet()
      ..addAll([
        if (organizadorUid != null) organizadorUid,
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
        'organizadorId': organizadorUid,
        if (organizadorNome != null && organizadorNome.isNotEmpty)
          'organizadorNome': organizadorNome,
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
          'organizadorId': organizadorUid,
          'nome': membro.nome,
          'telefone': membro.telefone,
          'equipe': membro.equipe,
          'capitao': membro.capitao,
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
    final organizadorUid = dados['organizadorId'] as String?;
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
      organizadorId: organizadorUid == null
          ? FirestoreCompatIds.registrar('usuarios', 'partida:${documento.id}')
          : FirestoreCompatIds.registrar('usuarios', organizadorUid),
      organizadorUid: organizadorUid,
      organizadorNome: (dados['organizadorNome'] as String?) ??
          await _nomePublicoUsuario(organizadorUid),
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
        capitao: (dados['capitao'] as bool?) ?? false,
        posX: (dados['posX'] as num?)?.toDouble(),
        posY: (dados['posY'] as num?)?.toDouble(),
        gols: (dados['gols'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<String?> _nomePublicoUsuario(String? uid) async {
    if (uid == null || uid.isEmpty) return null;
    final doc = await _firestore.collection('usuariosPublicos').doc(uid).get();
    final dados = doc.data();
    return dados?['nomeCompleto'] as String?;
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
    String? equipeEditada,
  }) async {
    final partida = await _documentoPartida(partidaId);
    if (partida == null) return;
    final batch = _firestore.batch();
    batch.update(partida.reference, {
      if (equipeEditada == null) 'formato': formato,
      if (equipeEditada == null || equipeEditada == Equipe.time1)
        'formacaoTime1': formacaoTime1,
      if (equipeEditada == null || equipeEditada == Equipe.time2)
        'formacaoTime2': formacaoTime2,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    for (final membro in membros) {
      if (membro.id == null) continue;
      if (equipeEditada != null && membro.equipe != equipeEditada) continue;
      final documento = await _documentoMembro(partida.id, membro.id!);
      if (documento == null) continue;
      batch.update(documento.reference, {
        if (equipeEditada == null) 'equipe': membro.equipe,
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
      'capitao': false,
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

  Future<void> _removerMembroFirestore({
    required int partidaId,
    required int membroId,
    required PartidaMembro membro,
  }) async {
    final partida = await _documentoPartida(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    final membroDoc = await _documentoMembro(partida.id, membroId);
    if (membroDoc == null) throw StateError('Participante não encontrado.');
    final membroUid = (membroDoc.data()?['usuarioId'] as String?) ??
        _uidDoUsuario(membro.idUser);
    if (membroUid == null || membroUid != FirestoreCompatIds.usuarioUid) {
      throw StateError('Você só pode sair da sua própria participação.');
    }

    final batch = _firestore.batch();
    batch.delete(membroDoc.reference);
    final atualizacao = <String, Object?>{
      'participantesUids': FieldValue.arrayRemove([membroUid]),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
    if (membro.capitao) {
      atualizacao[membro.equipe == Equipe.time1
          ? 'capitaoTime1Uid'
          : 'capitaoTime2Uid'] = FieldValue.delete();
    }
    batch.update(partida.reference, atualizacao);
    await batch.commit();
  }

  Future<void> _definirCapitaoFirestore({
    required int partidaId,
    required String equipe,
    required int membroId,
  }) async {
    final partida = await _documentoPartida(partidaId);
    if (partida == null) throw StateError('Partida não encontrada.');
    final membros = await partida.reference.collection('membros').get();
    final registro = _registroMembros(partida.id);
    QueryDocumentSnapshot<Map<String, dynamic>>? selecionado;
    for (final documento in membros.docs) {
      if (FirestoreCompatIds.registrar(registro, documento.id) == membroId) {
        selecionado = documento;
        break;
      }
    }
    final capitaoUid = selecionado?.data()['usuarioId'] as String?;
    if (selecionado == null ||
        selecionado.data()['equipe'] != equipe ||
        capitaoUid == null) {
      throw StateError('Escolha um jogador cadastrado no app.');
    }
    final batch = _firestore.batch();
    batch.update(partida.reference, {
      (equipe == Equipe.time1 ? 'capitaoTime1Uid' : 'capitaoTime2Uid'):
          capitaoUid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    for (final documento in membros.docs) {
      if (documento.data()['equipe'] != equipe) continue;
      batch.update(documento.reference, {
        'capitao': documento.id == selecionado.id,
      });
    }
    await batch.commit();
  }

  Future<void> _exigirOrganizador(Partida partida) async {
    final usuarioId = await Sessao.instance.usuarioId;
    if (usuarioId == null || partida.organizadorId != usuarioId) {
      throw StateError('Apenas o criador da partida pode realizar esta ação.');
    }
  }

  Future<void> _validarPermissaoEscalacao(
    Partida partida,
    String? equipeEditada,
  ) async {
    final usuarioId = await Sessao.instance.usuarioId;
    if (usuarioId == null) {
      throw StateError('Entre na sua conta para alterar a escalação.');
    }
    if (partida.organizadorId == usuarioId) return;
    final membro = partida.membroDoUsuario(usuarioId);
    if (equipeEditada == null ||
        membro == null ||
        !membro.capitao ||
        membro.equipe != equipeEditada) {
      throw StateError(
        'Somente o criador ou o capitão do time pode alterar a escalação.',
      );
    }
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
