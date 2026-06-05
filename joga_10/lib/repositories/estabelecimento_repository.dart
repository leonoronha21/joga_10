import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/model/Estabelecimentos.dart';

class EstabelecimentoRepository {
  Future<Pool> get _conn async => AppDatabase.instance.db;

  Future<List<Estabelecimentos>> listarTodos() async {
    final conn = await _conn;
    final result = await conn.execute('SELECT * FROM estabelecimento ORDER BY nome');
    return result.map((r) => Estabelecimentos.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Estabelecimentos>> listarAtivos() async {
    final conn = await _conn;
    final result = await conn.execute(
      'SELECT * FROM estabelecimento WHERE status = 1 ORDER BY nome',
    );
    return result.map((r) => Estabelecimentos.fromRow(r.toColumnMap())).toList();
  }

  /// Apenas estabelecimentos com latitude/longitude (para o mapa).
  Future<List<Estabelecimentos>> listarComLocalizacao() async {
    final conn = await _conn;
    final result = await conn.execute(
      'SELECT * FROM estabelecimento WHERE latitude IS NOT NULL AND longitude IS NOT NULL ORDER BY nome',
    );
    return result.map((r) => Estabelecimentos.fromRow(r.toColumnMap())).toList();
  }

  Future<int> salvar({
    required String nome,
    String? cnpj,
    String? razaoSocial,
    String? cidade,
    String? cep,
    String? rua,
    String? bairro,
    String? numero,
    String? horaAbertura,
    String? horaFechamento,
    String? telefone,
    String? email,
    double? latitude,
    double? longitude,
  }) async {
    final conn = await _conn;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO estabelecimento
          (cnpj, nome, razao_social, cidade, cep, rua, bairro, numero,
           hora_abertura, hora_fechamento, telefone, email, status,
           latitude, longitude)
        VALUES
          (@cnpj, @nome, @razao_social, @cidade, @cep, @rua, @bairro, @numero,
           @hora_abertura::time, @hora_fechamento::time, @telefone, @email, 0,
           @latitude, @longitude)
        RETURNING id
      '''),
      parameters: {
        'cnpj': cnpj,
        'nome': nome.trim(),
        'razao_social': razaoSocial,
        'cidade': cidade,
        'cep': cep,
        'rua': rua,
        'bairro': bairro,
        'numero': numero,
        'hora_abertura': horaAbertura,
        'hora_fechamento': horaFechamento,
        'telefone': telefone,
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return result.first.toColumnMap()['id'] as int;
  }
}
