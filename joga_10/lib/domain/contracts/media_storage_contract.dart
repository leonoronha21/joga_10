import 'dart:typed_data';

enum TipoMidia {
  fotoPerfil,
  postagem,
  documento,
}

class MidiaArmazenada {
  final String id;
  final String url;

  const MidiaArmazenada({
    required this.id,
    required this.url,
  });
}

abstract interface class MediaStorageContract {
  bool get uploadsHabilitados;

  String get mensagemIndisponivel;

  Future<MidiaArmazenada> enviar({
    required TipoMidia tipo,
    required String proprietarioId,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> excluir(String id);
}
