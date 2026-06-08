import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/sessao.dart';

class QuadraRepository {
  final DatabaseProvider _database;

  QuadraRepository({DatabaseProvider? database})
      : _database = database ?? AppDatabase.instance;

  Future<Pool> get _conn => _database.connection;

  Future<List<Quadras>> listarTodas() async {
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.quadras);
    }
    final conn = await _conn;
    final result = await conn.execute('SELECT * FROM quadra ORDER BY nome');
    return result.map((r) => Quadras.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Quadras>> listarPorEstabelecimento(int idEstabelecimento) async {
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
}
