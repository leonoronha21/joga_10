import 'package:postgres/postgres.dart';

abstract interface class DatabaseProvider {
  Future<Pool> get connection;
}
