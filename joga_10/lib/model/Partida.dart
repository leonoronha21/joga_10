import 'package:joga_10/db/row_utils.dart';
import 'package:joga_10/model/PartidaMembro.dart';

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
  final String formato; // '5x5' ou '7x7'
  final String? formacaoTime1;
  final String? formacaoTime2;
  final int? placarTime1;
  final int? placarTime2;
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
    this.formato = '5x5',
    this.formacaoTime1,
    this.formacaoTime2,
    this.placarTime1,
    this.placarTime2,
    this.membros = const [],
    this.quadraNome,
    this.estabelecimentoNome,
  });

  int get jogadoresPorTime => formato == '7x7' ? 7 : 5;
  bool get temPlacar => placarTime1 != null && placarTime2 != null;

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
      formato: (row['formato'] as String?) ?? '5x5',
      formacaoTime1: row['formacao_time1'] as String?,
      formacaoTime2: row['formacao_time2'] as String?,
      placarTime1:
          row['placar_time1'] == null ? null : asInt(row['placar_time1']),
      placarTime2:
          row['placar_time2'] == null ? null : asInt(row['placar_time2']),
      membros: membros,
      quadraNome: row['quadra_nome'] as String?,
      estabelecimentoNome: row['estabelecimento_nome'] as String?,
    );
  }
}
