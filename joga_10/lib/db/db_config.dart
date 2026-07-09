import 'package:postgres/postgres.dart';

import 'package:joga_10/config/build_config.dart';

/// Configuração da conexão com o PostgreSQL.
///
/// MONÓLITO: o app fala direto com o banco, sem API/servidor.
///
/// Sobre o [host]:
///  - Emulador Android: use '10.0.2.2' (alias do localhost da máquina host).
///  - Celular físico:   use o IP da máquina na rede Wi‑Fi (ex.: '192.168.0.10')
///                      e lembre de liberar o Postgres na rede (listen_addresses
///                      e pg_hba.conf) — veja o README do projeto.
///  - Flutter Desktop/iOS Simulator: use 'localhost'.
class DbConfig {
  /// Pode ser sobrescrito com `--dart-define=DB_HOST=192.168.x.x`.
  static const String _host =
      String.fromEnvironment('DB_HOST', defaultValue: '');
  static const String host =
      _host != '' ? _host : (BuildConfig.localAuthEnabled ? '10.0.2.2' : '');

  static const int port = int.fromEnvironment('DB_PORT', defaultValue: 5432);
  static const String _database =
      String.fromEnvironment('DB_NAME', defaultValue: '');
  static const String database = _database != ''
      ? _database
      : (BuildConfig.localAuthEnabled ? 'joga10' : '');
  static const String _username =
      String.fromEnvironment('DB_USER', defaultValue: '');
  static const String username = _username != ''
      ? _username
      : (BuildConfig.localAuthEnabled ? 'joga10_app' : '');
  static const String _password =
      String.fromEnvironment('DB_PASSWORD', defaultValue: '');
  static const String password = _password != ''
      ? _password
      : (BuildConfig.localAuthEnabled ? 'joga10_app_pwd' : '');

  /// Em desenvolvimento local o Postgres roda sem TLS.
  static SslMode get sslMode =>
      BuildConfig.localAuthEnabled ? SslMode.disable : SslMode.require;

  // ignore: prefer_const_constructors  (Endpoint não tem construtor const)
  static Endpoint get endpoint => Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      );

  static ConnectionSettings get settings =>
      ConnectionSettings(sslMode: sslMode);
}
