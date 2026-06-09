import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/domain/contracts/media_storage_contract.dart';
import 'package:joga_10/domain/contracts/pagamento_provider_contract.dart';
import 'package:joga_10/services/media_storage_desabilitado.dart';
import 'package:joga_10/services/pagamento_demo_provider.dart';

void main() {
  test('provedor demo aprova sem movimentar dinheiro', () async {
    const provider = PagamentoDemoProvider();

    final resultado = await provider.pagar(
      const SolicitacaoPagamento(
        referenciaCobranca: 'cobranca-demo',
        valorCentavos: 3150,
        descricao: 'Rateio demo',
      ),
    );

    expect(provider.modoDemonstracao, isTrue);
    expect(resultado.provedor, 'LOCAL_DEMO');
    expect(resultado.status, 'APROVADO');
    expect(resultado.referenciaExterna, startsWith('DEMO-cobranca-demo-'));
  });

  test('armazenamento bloqueia uploads no Spark', () {
    const storage = MediaStorageDesabilitado();

    expect(storage.uploadsHabilitados, isFalse);
    expect(
      () => storage.enviar(
        tipo: TipoMidia.postagem,
        proprietarioId: 'usuario-demo',
        bytes: Uint8List(0),
        contentType: 'image/jpeg',
      ),
      throwsUnsupportedError,
    );
  });
}
