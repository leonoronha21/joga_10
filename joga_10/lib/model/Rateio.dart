import 'package:joga_10/db/row_utils.dart';

class RateioStatus {
  static const aberto = 'ABERTO';
  static const fechado = 'FECHADO';
  static const cancelado = 'CANCELADO';
}

class CobrancaStatus {
  static const pendente = 'PENDENTE';
  static const pago = 'PAGO';
  static const isento = 'ISENTO';

  static String label(String status) {
    switch (status) {
      case pago:
        return 'Pago';
      case isento:
        return 'Isento';
      default:
        return 'Pendente';
    }
  }
}

class RateioCobranca {
  final int id;
  final int rateioId;
  final int? partidaMembroId;
  final int? idUser;
  final String nome;
  final double valorQuadra;
  final double taxaServico;
  final double valorTotal;
  final String status;
  final DateTime? pagoEm;

  RateioCobranca({
    required this.id,
    required this.rateioId,
    this.partidaMembroId,
    this.idUser,
    required this.nome,
    required this.valorQuadra,
    required this.taxaServico,
    required this.valorTotal,
    required this.status,
    this.pagoEm,
  });

  bool get pago => status == CobrancaStatus.pago;
  bool get isento => status == CobrancaStatus.isento;
  bool get quitado => pago || isento;

  RateioCobranca copyWith({
    String? status,
    DateTime? pagoEm,
    bool limparPagoEm = false,
  }) {
    return RateioCobranca(
      id: id,
      rateioId: rateioId,
      partidaMembroId: partidaMembroId,
      idUser: idUser,
      nome: nome,
      valorQuadra: valorQuadra,
      taxaServico: taxaServico,
      valorTotal: valorTotal,
      status: status ?? this.status,
      pagoEm: limparPagoEm ? null : pagoEm ?? this.pagoEm,
    );
  }

  factory RateioCobranca.fromRow(Map<String, dynamic> row) {
    return RateioCobranca(
      id: asInt(row['id']),
      rateioId: asInt(row['rateio_id']),
      partidaMembroId: row['partida_membro_id'] == null
          ? null
          : asInt(row['partida_membro_id']),
      idUser: row['id_user'] == null ? null : asInt(row['id_user']),
      nome: (row['nome'] as String?) ?? '',
      valorQuadra: asDouble(row['valor_quadra']),
      taxaServico: asDouble(row['taxa_servico']),
      valorTotal: asDouble(row['valor_total']),
      status: (row['status'] as String?) ?? CobrancaStatus.pendente,
      pagoEm: row['pago_em'] as DateTime?,
    );
  }
}

class PartidaRateio {
  final int id;
  final int partidaId;
  final double valorQuadra;
  final double taxaPercentual;
  final String status;
  final List<RateioCobranca> cobrancas;

  PartidaRateio({
    required this.id,
    required this.partidaId,
    required this.valorQuadra,
    required this.taxaPercentual,
    required this.status,
    this.cobrancas = const [],
  });

  int get totalParticipantes => cobrancas.length;
  int get totalQuitados => cobrancas.where((c) => c.quitado).length;
  int get totalPendentes => cobrancas.where((c) => !c.quitado).length;

  double get totalTaxas =>
      cobrancas.fold(0, (total, c) => total + c.taxaServico);
  double get totalCobrado =>
      cobrancas.fold(0, (total, c) => total + c.valorTotal);
  double get totalRecebido => cobrancas
      .where((c) => c.pago)
      .fold(0, (total, c) => total + c.valorTotal);

  PartidaRateio copyWith({
    String? status,
    List<RateioCobranca>? cobrancas,
  }) {
    return PartidaRateio(
      id: id,
      partidaId: partidaId,
      valorQuadra: valorQuadra,
      taxaPercentual: taxaPercentual,
      status: status ?? this.status,
      cobrancas: cobrancas ?? this.cobrancas,
    );
  }

  factory PartidaRateio.fromRow(
    Map<String, dynamic> row, {
    List<RateioCobranca> cobrancas = const [],
  }) {
    return PartidaRateio(
      id: asInt(row['id']),
      partidaId: asInt(row['partida_id']),
      valorQuadra: asDouble(row['valor_quadra']),
      taxaPercentual: asDouble(row['taxa_percentual']),
      status: (row['status'] as String?) ?? RateioStatus.aberto,
      cobrancas: cobrancas,
    );
  }
}
