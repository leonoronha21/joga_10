import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Cartao.dart';

class CartaoRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  Future<List<Cartao>> listarPorUsuario(int idUser) async {
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
    final ultimos4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits.padLeft(4, '0');

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
