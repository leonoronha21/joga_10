import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';

enum ResultadoParticipacao {
  sucesso,
  requerLogin,
  jaParticipa,
  timesCompletos,
}

class ParticipacaoPartida {
  final ResultadoParticipacao resultado;
  final int? usuarioId;
  final String? nome;

  const ParticipacaoPartida(this.resultado, {this.usuarioId, this.nome});
}

class ParticiparDaPartida {
  final PartidaRepositoryContract partidas;
  final SessaoContract sessao;

  const ParticiparDaPartida({
    required this.partidas,
    required this.sessao,
  });

  Future<ParticipacaoPartida> execute(Partida partida) async {
    final usuario = await sessao.restaurarLocal();
    final id = usuario?.id ?? await sessao.usuarioId;
    if (id == null) {
      return const ParticipacaoPartida(ResultadoParticipacao.requerLogin);
    }

    final nome = _nomeJogador(id, usuario?.nomeCompleto);
    if (_jaParticipa(partida, id, nome)) {
      return ParticipacaoPartida(
        ResultadoParticipacao.jaParticipa,
        usuarioId: id,
        nome: nome,
      );
    }

    final equipe = _equipeComVaga(partida);
    if (equipe == null) {
      return ParticipacaoPartida(
        ResultadoParticipacao.timesCompletos,
        usuarioId: id,
        nome: nome,
      );
    }

    await partidas.adicionarMembro(
      partidaId: partida.id,
      idUser: id,
      equipe: equipe,
      nome: nome,
    );
    return ParticipacaoPartida(
      ResultadoParticipacao.sucesso,
      usuarioId: id,
      nome: nome,
    );
  }

  bool jaParticipa(Partida partida, int? id, String nome) {
    if (id == null) return false;
    return _jaParticipa(partida, id, nome);
  }

  bool timesCompletos(Partida partida) {
    return partida.time1.length >= partida.jogadoresPorTime &&
        partida.time2.length >= partida.jogadoresPorTime;
  }

  String nomeJogador(int? id, String? nomeSessao) {
    return _nomeJogador(id, nomeSessao);
  }

  String _nomeJogador(int? id, String? nomeSessao) {
    final nome = (nomeSessao ?? '').trim();
    if (nome.isNotEmpty) return nome;
    return id == null || id <= 0 ? 'Admin Local' : 'Jogador $id';
  }

  bool _jaParticipa(Partida partida, int id, String nome) {
    if (id > 0 && partida.organizadorId == id) return true;
    return partida.membros.any((membro) {
      if (membro.idUser == id) return true;
      return id <= 0 && membro.idUser == null && membro.nome.trim() == nome;
    });
  }

  String? _equipeComVaga(Partida partida) {
    final limite = partida.jogadoresPorTime;
    final time1TemVaga = partida.time1.length < limite;
    final time2TemVaga = partida.time2.length < limite;

    if (!time1TemVaga && !time2TemVaga) return null;
    if (!time1TemVaga) return Equipe.time2;
    if (!time2TemVaga) return Equipe.time1;
    return partida.time1.length <= partida.time2.length
        ? Equipe.time1
        : Equipe.time2;
  }
}
