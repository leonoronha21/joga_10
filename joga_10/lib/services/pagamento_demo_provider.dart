import 'package:joga_10/domain/contracts/pagamento_provider_contract.dart';

class PagamentoDemoProvider implements PagamentoProviderContract {
  const PagamentoDemoProvider();

  @override
  String get nome => 'LOCAL_DEMO';

  @override
  bool get modoDemonstracao => true;

  @override
  Future<ResultadoPagamento> pagar(SolicitacaoPagamento solicitacao) async {
    final agora = DateTime.now();
    return ResultadoPagamento(
      provedor: nome,
      referenciaExterna:
          'DEMO-${solicitacao.referenciaCobranca}-${agora.microsecondsSinceEpoch}',
      status: 'APROVADO',
      processadoEm: agora,
    );
  }
}
