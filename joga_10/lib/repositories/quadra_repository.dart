import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Quadras.dart';

class QuadraRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  Future<List<Quadras>> listarTodas() async {
    final conn = await _conn;
    final result = await conn.execute('SELECT * FROM quadra ORDER BY nome');
    return result.map((r) => Quadras.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Quadras>> listarPorEstabelecimento(int idEstabelecimento) async {
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named(
        'SELECT * FROM quadra WHERE id_estabelecimento = @id ORDER BY nome',
      ),
      parameters: {'id': idEstabelecimento},
    );
    return result.map((r) => Quadras.fromRow(r.toColumnMap())).toList();
  }
}
