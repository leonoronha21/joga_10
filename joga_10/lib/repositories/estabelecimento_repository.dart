import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:postgres/postgres.dart';

import 'package:joga_10/db/app_database.dart';
import 'package:joga_10/domain/contracts/database_provider.dart';
import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/services/local_demo_data.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/services/locais_esportivos_catalogo.dart';
import 'package:joga_10/services/sessao.dart';

class EstabelecimentoRepository {
  final DatabaseProvider _database;
  final FirebaseFirestore? _firestoreConfigurado;

  EstabelecimentoRepository({
    DatabaseProvider? database,
    FirebaseFirestore? firestore,
  })  : _database = database ?? AppDatabase.instance,
        _firestoreConfigurado = firestore;

  Future<Pool> get _conn => _database.connection;
  FirebaseFirestore get _firestore =>
      _firestoreConfigurado ?? FirebaseFirestore.instance;

  Future<List<Estabelecimentos>> listarTodos() async {
    if (FirestoreCompatIds.habilitado) return _listarFirestore();
    if (Sessao.instance.isAdminLocal) {
      return List.unmodifiable(LocalDemoData.instance.estabelecimentos);
    }
    final conn = await _conn;
    final result =
        await conn.execute('SELECT * FROM estabelecimento ORDER BY nome');
    return result
        .map((r) => Estabelecimentos.fromRow(r.toColumnMap()))
        .toList();
  }

  Future<List<Estabelecimentos>> listarAtivos() async {
    if (FirestoreCompatIds.habilitado) {
      return _listarFirestore(apenasAtivos: true);
    }
    if (Sessao.instance.isAdminLocal) {
      return LocalDemoData.instance.estabelecimentos
          .where((e) => e.status == 1)
          .toList();
    }
    final conn = await _conn;
    final result = await conn.execute(
      'SELECT * FROM estabelecimento WHERE status = 1 ORDER BY nome',
    );
    return result
        .map((r) => Estabelecimentos.fromRow(r.toColumnMap()))
        .toList();
  }

  /// Apenas estabelecimentos com latitude/longitude (para o mapa).
  Future<List<Estabelecimentos>> listarComLocalizacao() async {
    if (FirestoreCompatIds.habilitado) {
      final cadastrados = await _listarFirestore(apenasComLocalizacao: true);
      return LocaisEsportivosCatalogo.mesclarSomente(cadastrados);
    }
    if (Sessao.instance.isAdminLocal) {
      return const <Estabelecimentos>[];
    }
    final conn = await _conn;
    final result = await conn.execute(
      'SELECT * FROM estabelecimento WHERE latitude IS NOT NULL AND longitude IS NOT NULL ORDER BY nome',
    );
    return LocaisEsportivosCatalogo.mesclarSomente(
      result.map((r) => Estabelecimentos.fromRow(r.toColumnMap())),
    );
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
    if (FirestoreCompatIds.habilitado) {
      final referencia = await _firestore.collection('estabelecimentos').add({
        'nome': nome.trim(),
        'cnpj': cnpj,
        'razaoSocial': razaoSocial,
        'cidade': cidade,
        'cep': cep,
        'rua': rua,
        'bairro': bairro,
        'numero': numero,
        'horaAbertura': horaAbertura,
        'horaFechamento': horaFechamento,
        'telefone': telefone,
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'PENDENTE',
        'ambiente': 'DEMO',
        'criadoPor': FirestoreCompatIds.usuarioUid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return FirestoreCompatIds.registrar('estabelecimentos', referencia.id);
    }
    if (Sessao.instance.isAdminLocal) {
      final id = LocalDemoData.instance.novoId();
      LocalDemoData.instance.estabelecimentos.add(
        Estabelecimentos(
          id: id,
          nome: nome,
          cnpj: cnpj,
          razaoSocial: razaoSocial,
          cidade: cidade,
          cep: cep,
          rua: rua,
          bairro: bairro,
          numero: numero,
          horaAbertura: horaAbertura,
          horaFechamento: horaFechamento,
          telefone: telefone,
          email: email,
          latitude: latitude,
          longitude: longitude,
        ),
      );
      return id;
    }
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

  Future<List<Estabelecimentos>> _listarFirestore({
    bool apenasAtivos = false,
    bool apenasComLocalizacao = false,
  }) async {
    final documentos = await _firestore.collection('estabelecimentos').get();
    final locais = documentos.docs.map((documento) {
      final dados = documento.data();
      final status = dados['status'];
      return Estabelecimentos(
        id: FirestoreCompatIds.registrar('estabelecimentos', documento.id),
        cnpj: dados['cnpj'] as String?,
        nome: (dados['nome'] as String?) ?? '',
        razaoSocial: dados['razaoSocial'] as String?,
        cidade: dados['cidade'] as String?,
        cep: dados['cep'] as String?,
        rua: dados['rua'] as String?,
        bairro: dados['bairro'] as String?,
        numero: dados['numero']?.toString(),
        horaAbertura: dados['horaAbertura'] as String?,
        horaFechamento: dados['horaFechamento'] as String?,
        telefone: dados['telefone'] as String?,
        email: dados['email'] as String?,
        status: status == 'ATIVO' || status == 1 ? 1 : 0,
        latitude: (dados['latitude'] as num?)?.toDouble(),
        longitude: (dados['longitude'] as num?)?.toDouble(),
      );
    }).where((local) {
      if (apenasAtivos && local.status != 1) return false;
      if (apenasComLocalizacao && !local.temLocalizacao) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return locais;
  }
}
