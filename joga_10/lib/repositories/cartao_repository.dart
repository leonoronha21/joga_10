import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/local_demo_data.dart';

class CartaoRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;
  final String? _usuarioUidConfigurado;

  CartaoRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
    String? usuarioUid,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore,
        _usuarioUidConfigurado = usuarioUid;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;
  String? get _usuarioUid =>
      _usuarioUidConfigurado ?? FirestoreCompatIds.usuarioUid;

  Future<List<Cartao>> listarPorUsuario(int idUser) async {
    final uid = _usuarioUid;
    if (uid != null) {
      final docs = await _firestore
          .collection('cartoes')
          .doc(uid)
          .collection('itens')
          .orderBy('criadoEm', descending: true)
          .get();
      return docs.docs.map((doc) {
        final dados = doc.data();
        return Cartao(
          id: FirestoreCompatIds.registrar('cartoes/$uid/itens', doc.id),
          idUser: idUser,
          nomeTitular: (dados['nomeTitular'] as String?) ?? '',
          bandeira: dados['bandeira'] as String?,
          ultimos4: (dados['ultimos4'] as String?) ?? '',
          validade: (dados['validade'] as String?) ?? '',
        );
      }).toList();
    }
    if (idUser == LocalDemoData.adminId) {
      return List.unmodifiable(LocalDemoData.instance.cartoes);
    }
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('SELECT * FROM cartao WHERE id_user = @id ORDER BY id DESC'),
      parameters: {'id': idUser},
    );
    return result.map((r) => Cartao.fromRow(r.toColumnMap())).toList();
  }

  /// Salva um cartão guardando apenas dados de exibição.
  /// Recebe o número completo só para extrair os últimos 4 dígitos —
  /// o número NÃO é persistido.
  Future<int> salvar({
    required int idUser,
    required String nomeTitular,
    String? bandeira,
    required String numeroCompleto,
    required String validade,
  }) async {
    final digits = numeroCompleto.replaceAll(RegExp(r'\D'), '');
    final ultimos4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits.padLeft(4, '0');

    final uid = _usuarioUid;
    if (uid != null) {
      final referencia = await _firestore
          .collection('cartoes')
          .doc(uid)
          .collection('itens')
          .add({
        'nomeTitular': nomeTitular.trim(),
        'bandeira': bandeira?.trim(),
        'ultimos4': ultimos4,
        'validade': validade.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return FirestoreCompatIds.registrar('cartoes/$uid/itens', referencia.id);
    }

    if (idUser == LocalDemoData.adminId) {
      final demo = LocalDemoData.instance;
      final id = demo.novoId();
      demo.cartoes.add(
        Cartao(
          id: id,
          idUser: idUser,
          nomeTitular: nomeTitular.trim(),
          bandeira: bandeira,
          ultimos4: ultimos4,
          validade: validade,
        ),
      );
      return id;
    }

    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO cartao (id_user, nome_titular, bandeira, ultimos4, validade)
        VALUES (@id_user, @nome_titular, @bandeira, @ultimos4, @validade)
        RETURNING id
      '''),
      parameters: {
        'id_user': idUser,
        'nome_titular': nomeTitular.trim(),
        'bandeira': bandeira,
        'ultimos4': ultimos4,
        'validade': validade,
      },
    );
    return result.first.toColumnMap()['id'] as int;
  }
}
