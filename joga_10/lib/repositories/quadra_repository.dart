import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/sessao.dart';

class QuadraRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  QuadraRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  Future<List<Quadras>> listarTodas() async {
    if (FirestoreCompatIds.habilitado) return _listarFirestore();
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.quadras);
    }
    final conn = await _conn;
    final result = await conn.execute('SELECT * FROM quadra ORDER BY nome');
    return result.map((r) => Quadras.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Quadras>> listarPorEstabelecimento(int idEstabelecimento) async {
    if (FirestoreCompatIds.habilitado) {
      final estabelecimentoId =
          FirestoreCompatIds.documento('estabelecimentos', idEstabelecimento);
      if (estabelecimentoId == null) return [];
      return _listarFirestore(estabelecimentoId: estabelecimentoId);
    }
    if (idEstabelecimento < 0 || Sessao.instance.isAdminLocal) {
      return LocalDemoData.instance.quadras
          .where((q) => q.idEstabelecimento == idEstabelecimento)
          .toList();
    }
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named(
        'SELECT * FROM quadra WHERE id_estabelecimento = @id ORDER BY nome',
      ),
      parameters: {'id': idEstabelecimento},
    );
    return result.map((r) => Quadras.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Quadras>> _listarFirestore({String? estabelecimentoId}) async {
    final documentos = await _firestore.collection('quadras').get();
    final quadras = documentos.docs.where((documento) {
      return estabelecimentoId == null ||
          documento.data()['estabelecimentoId'] == estabelecimentoId;
    }).map((documento) {
      final dados = documento.data();
      final estabelecimento = (dados['estabelecimentoId'] as String?) ?? '';
      return Quadras(
        id: FirestoreCompatIds.registrar('quadras', documento.id),
        idEstabelecimento:
            FirestoreCompatIds.registrar('estabelecimentos', estabelecimento),
        nome: (dados['nome'] as String?) ?? '',
        tipoQuadra: (dados['tipoQuadra'] as String?) ?? '',
        preco: (dados['preco'] as num?)?.toDouble() ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return quadras;
  }
}
