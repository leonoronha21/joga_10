import 'package:postgres/postgres.dart';

import 'db_config.dart';

/// Acesso ao PostgreSQL via POOL de conexões.
///
/// Usamos um pool (e não uma conexão única) porque o app acessa o banco de
/// vários lugares ao mesmo tempo — o `IndexedStack` do HomeShell mantém as
/// abas vivas e cada uma dispara suas queries. Uma única conexão não suporta
/// queries concorrentes (corrompe o protocolo); o pool roteia cada query para
/// uma conexão livre e ainda lida com conexões que caíram.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Pool? _pool;

  Pool get db {
    return _pool ??= Pool.withEndpoints(
      [DbConfig.endpoint],
      settings: PoolSettings(
        maxConnectionCount: 5,
        sslMode: DbConfig.sslMode,
      ),
    );
  }

  Future<bool> testConnection() async {
    try {
      await db.execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
