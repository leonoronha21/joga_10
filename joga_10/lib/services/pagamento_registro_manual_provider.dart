import 'package:joga_10/domain/contracts/pagamento_provider_contract.dart';

class PagamentoRegistroManualProvider implements PagamentoProviderContract {
  const PagamentoRegistroManualProvider();

  @override
  String get nome => 'REGISTRO_MANUAL';

  @override
  bool get modoDemonstracao => false;

  @override
  Future<ResultadoPagamento> pagar(SolicitacaoPagamento solicitacao) async {
    final agora = DateTime.now();
    return ResultadoPagamento(
      provedor: nome,
      referenciaExterna:
          'MANUAL-${solicitacao.referenciaCobranca}-${agora.microsecondsSinceEpoch}',
      status: 'REGISTRADO',
      processadoEm: agora,
    );
  }
}
