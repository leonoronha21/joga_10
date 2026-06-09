import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';

abstract interface class PartidaRepositoryContract {
  Future<int> criar({
    int? idEstabelecimento,
    int? idQuadra,
    required int organizadorId,
    String? duracao,
    required DateTime dataHora,
    String status = PartidaStatus.agendada,
    required double preco,
    List<PartidaMembro> membros = const [],
  });

  Future<List<Partida>> listarTodas();

  Future<List<Partida>> listarPorUsuario(int userId);

  Future<List<Partida>> listarPorUsuarioEStatus(int userId, String status);

  Future<Partida?> buscarPorId(int id);

  Future<bool> atualizarStatus(int id, String status);

  Future<bool> finalizar(int id);

  Future<void> finalizarComPlacar({
    required int partidaId,
    required int placarTime1,
    required int placarTime2,
    required Map<int, int> golsPorMembro,
  });

  Future<void> salvarEscalacao({
    required int partidaId,
    required String formato,
    String? formacaoTime1,
    String? formacaoTime2,
    required List<PartidaMembro> membros,
  });

  Future<void> adicionarMembro({
    required int partidaId,
    int? idUser,
    required String equipe,
    required String nome,
    String? telefone,
  });
}
