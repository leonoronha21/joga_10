class SolicitacaoPagamento {
  final String referenciaCobranca;
  final int valorCentavos;
  final String descricao;
  final Map<String, String> metadados;

  const SolicitacaoPagamento({
    required this.referenciaCobranca,
    required this.valorCentavos,
    required this.descricao,
    this.metadados = const {},
  });
}

class ResultadoPagamento {
  final String provedor;
  final String referenciaExterna;
  final String status;
  final DateTime processadoEm;

  const ResultadoPagamento({
    required this.provedor,
    required this.referenciaExterna,
    required this.status,
    required this.processadoEm,
  });
}

abstract interface class PagamentoProviderContract {
  String get nome;

  bool get modoDemonstracao;

  Future<ResultadoPagamento> pagar(SolicitacaoPagamento solicitacao);
}
