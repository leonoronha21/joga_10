import 'dart:typed_data';

import 'package:joga_10/domain/contracts/media_storage_contract.dart';

class MediaStorageDesabilitado implements MediaStorageContract {
  const MediaStorageDesabilitado();

  @override
  bool get uploadsHabilitados => false;

  @override
  String get mensagemIndisponivel =>
      'Fotos estao desativadas nesta demonstracao no plano Spark.';

  @override
  Future<MidiaArmazenada> enviar({
    required TipoMidia tipo,
    required String proprietarioId,
    required Uint8List bytes,
    required String contentType,
  }) {
    throw UnsupportedError(mensagemIndisponivel);
  }

  @override
  Future<void> excluir(String id) {
    throw UnsupportedError(mensagemIndisponivel);
  }
}
