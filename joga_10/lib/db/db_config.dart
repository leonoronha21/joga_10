import 'package:postgres/postgres.dart';

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
  static const String host =
      String.fromEnvironment('DB_HOST', defaultValue: '10.0.2.2');
  static const int port = int.fromEnvironment('DB_PORT', defaultValue: 5432);
  static const String database =
      String.fromEnvironment('DB_NAME', defaultValue: 'joga10');
  static const String username =
      String.fromEnvironment('DB_USER', defaultValue: 'joga10_app');
  static const String password =
      String.fromEnvironment('DB_PASSWORD', defaultValue: 'joga10_app_pwd');

  /// Em desenvolvimento local o Postgres roda sem TLS.
  static const SslMode sslMode = SslMode.disable;

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
