import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:joga_10/domain/contracts/media_storage_contract.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';

/// Armazena imagens no Firebase Cloud Storage (disponível no plano Blaze).
///
/// Guarda os arquivos sob `<{pasta}>/<{uid}>/...` e devolve a URL de download,
/// que é persistida no Firestore. As regras (`storage.rules`) restringem a
/// escrita ao próprio usuário.
class FirebaseMediaStorage implements MediaStorageContract {
  final FirebaseStorage _storage;

  FirebaseMediaStorage({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  bool get uploadsHabilitados => true;

  @override
  String get mensagemIndisponivel =>
      'Envio de imagens indisponível. Entre com a sua conta Google.';

  @override
  Future<MidiaArmazenada> enviar({
    required TipoMidia tipo,
    required String proprietarioId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final uid = FirestoreCompatIds.usuarioUid ?? proprietarioId;
    final pasta = switch (tipo) {
      TipoMidia.fotoPerfil => 'perfis',
      TipoMidia.postagem => 'postagens',
      TipoMidia.documento => 'documentos',
    };
    final caminho =
        '$pasta/$uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref(caminho);
    final snap = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final url = await snap.ref.getDownloadURL();
    return MidiaArmazenada(id: caminho, url: url);
  }

  @override
  Future<void> excluir(String id) async {
    try {
      await _storage.ref(id).delete();
    } catch (_) {
      // Ignora se o arquivo não existir.
    }
  }
}
