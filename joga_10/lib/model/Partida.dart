import 'package:joga_10/db/row_utils.dart';
import 'package:joga_10/model/PartidaMembro.dart';

class ModalidadePartida {
  static const futebol = 'FUTEBOL';
  static const volei = 'VOLEI';

  static const valores = [futebol, volei];

  static String label(String modalidade) {
    return modalidade == volei ? 'Vôlei' : 'Futebol';
  }

  static String formatoPadrao(String modalidade) {
    return modalidade == volei ? '6x6' : '5x5';
  }
}

class VisibilidadePartida {
  static const publica = 'PUBLICA';
  static const privada = 'PRIVADA';

  static String label(String visibilidade) {
    return visibilidade == privada ? 'Privada' : 'Pública';
  }
}

/// Status possiveis de uma partida (espelha o CHECK do banco).
class PartidaStatus {
  static const agendada = 'AGENDADA';
  static const emAndamento = 'EM_ANDAMENTO';
  static const finalizada = 'FINALIZADA';
  static const cancelada = 'CANCELADA';

  static String label(String status) {
    switch (status) {
      case agendada:
        return 'Agendada';
      case emAndamento:
        return 'Em andamento';
      case finalizada:
        return 'Finalizada';
      case cancelada:
        return 'Cancelada';
      default:
        return status;
    }
  }
}

class Partida {
  final int id;
  final int? idEstabelecimento;
  final int? idQuadra;
  final int organizadorId;
  final String? duracao;
  final DateTime dataHora;
  final String status;
  final double preco;
  final String visibilidade;
  final String modalidade;
  final String formato;
  final String? formacaoTime1;
  final String? formacaoTime2;
  final int? placarTime1;
  final int? placarTime2;
  final String? grupoRecorrencia;
  final String recorrencia;
  final DateTime? recorrenciaAte;
  final List<PartidaMembro> membros;

  // Campos opcionais vindos de JOIN (para exibicao).
  final String? quadraNome;
  final String? estabelecimentoNome;

  Partida({
    required this.id,
    this.idEstabelecimento,
    this.idQuadra,
    required this.organizadorId,
    this.duracao,
    required this.dataHora,
    required this.status,
    required this.preco,
    this.visibilidade = VisibilidadePartida.publica,
    this.modalidade = ModalidadePartida.futebol,
    this.formato = '5x5',
    this.formacaoTime1,
    this.formacaoTime2,
    this.placarTime1,
    this.placarTime2,
    this.grupoRecorrencia,
    this.recorrencia = 'NENHUMA',
    this.recorrenciaAte,
    this.membros = const [],
    this.quadraNome,
    this.estabelecimentoNome,
  });

  bool get isVolei => modalidade == ModalidadePartida.volei;
  bool get publica => visibilidade == VisibilidadePartida.publica;
  int get jogadoresPorTime {
    if (isVolei) return formato == '2x2' ? 2 : 6;
    if (formato == '11x11') return 11;
    return formato == '7x7' ? 7 : 5;
  }

  String get unidadePlacar => isVolei ? 'sets' : 'gols';
  bool get temPlacar => placarTime1 != null && placarTime2 != null;
  bool get recorrente => recorrencia != 'NENHUMA';

  List<PartidaMembro> get time1 =>
      membros.where((m) => m.equipe == Equipe.time1).toList();
  List<PartidaMembro> get time2 =>
      membros.where((m) => m.equipe == Equipe.time2).toList();

  factory Partida.fromRow(
    Map<String, dynamic> row, {
    List<PartidaMembro> membros = const [],
  }) {
    return Partida(
      id: asInt(row['id']),
      idEstabelecimento: row['id_estabelecimento'] == null
          ? null
          : asInt(row['id_estabelecimento']),
      idQuadra: row['id_quadra'] == null ? null : asInt(row['id_quadra']),
      organizadorId: asInt(row['organizador_id']),
      duracao: row['duracao'] as String?,
      dataHora: row['data_hora'] as DateTime,
      status: (row['status'] as String?) ?? PartidaStatus.agendada,
      preco: asDouble(row['preco']),
      visibilidade:
          (row['visibilidade'] as String?) ?? VisibilidadePartida.publica,
      modalidade: (row['modalidade'] as String?) ?? ModalidadePartida.futebol,
      formato: (row['formato'] as String?) ?? '5x5',
      formacaoTime1: row['formacao_time1'] as String?,
      formacaoTime2: row['formacao_time2'] as String?,
      placarTime1:
          row['placar_time1'] == null ? null : asInt(row['placar_time1']),
      placarTime2:
          row['placar_time2'] == null ? null : asInt(row['placar_time2']),
      grupoRecorrencia: row['grupo_recorrencia'] as String?,
      recorrencia: (row['recorrencia'] as String?) ?? 'NENHUMA',
      recorrenciaAte: row['recorrencia_ate'] as DateTime?,
      membros: membros,
      quadraNome: row['quadra_nome'] as String?,
      estabelecimentoNome: row['estabelecimento_nome'] as String?,
    );
  }
}
