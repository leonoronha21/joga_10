import 'package:joga_10/db/row_utils.dart';

class ContratacaoStatus {
  static const pendente = 'PENDENTE';
  static const aceita = 'ACEITA';
  static const recusada = 'RECUSADA';

  static String label(String s) {
    switch (s) {
      case pendente:
        return 'Pendente';
      case aceita:
        return 'Aceita';
      case recusada:
        return 'Recusada';
      default:
        return s;
    }
  }
}

class Contratacao {
  final int id;
  final int goleiroId;
  final int? partidaId;
  final int solicitanteId;
  final String status;
  final double? valor;
  final DateTime criadoEm;
  final String solicitanteNome;
  final String? partidaQuadra;
  final DateTime? partidaData;

  Contratacao({
    required this.id,
    required this.goleiroId,
    this.partidaId,
    required this.solicitanteId,
    required this.status,
    this.valor,
    required this.criadoEm,
    required this.solicitanteNome,
    this.partidaQuadra,
    this.partidaData,
  });

  factory Contratacao.fromRow(Map<String, dynamic> row) {
    return Contratacao(
      id: asInt(row['id']),
      goleiroId: asInt(row['goleiro_id']),
      partidaId: row['partida_id'] == null ? null : asInt(row['partida_id']),
      solicitanteId: asInt(row['solicitante_id']),
      status: (row['status'] as String?) ?? ContratacaoStatus.pendente,
      valor: row['valor'] == null ? null : asDouble(row['valor']),
      criadoEm: row['criado_em'] as DateTime,
      solicitanteNome: (row['solicitante_nome'] as String?)?.trim() ?? 'Usuário',
      partidaQuadra: row['partida_quadra'] as String?,
      partidaData: row['partida_data'] as DateTime?,
    );
  }
}
