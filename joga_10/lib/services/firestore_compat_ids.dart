import 'package:firebase_auth/firebase_auth.dart';

class FirestoreCompatIds {
  FirestoreCompatIds._();

  static final Map<String, Map<int, String>> _documentos = {};

  static bool get habilitado {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  static String? get usuarioUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static int registrar(String colecao, String documentId) {
    final documentos = _documentos.putIfAbsent(colecao, () => {});
    var id = _hash('$colecao/$documentId');
    while (documentos[id] != null && documentos[id] != documentId) {
      id = id == 0x7fffffff ? 1 : id + 1;
    }
    documentos[id] = documentId;
    return id;
  }

  static String? documento(String colecao, int id) => _documentos[colecao]?[id];

  static int _hash(String valor) {
    var hash = 0x811c9dc5;
    for (final unidade in valor.codeUnits) {
      hash ^= unidade;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
