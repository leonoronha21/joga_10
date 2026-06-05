import 'package:joga_10/db/row_utils.dart';

class Estabelecimentos {
  final int id;
  final String? cnpj;
  final String nome;
  final String? razaoSocial;
  final String? cidade;
  final String? cep;
  final String? rua;
  final String? bairro;
  final String? numero;
  final String? horaAbertura;
  final String? horaFechamento;
  final String? telefone;
  final String? email;
  final int status;
  final double? latitude;
  final double? longitude;

  Estabelecimentos({
    required this.id,
    this.cnpj,
    required this.nome,
    this.razaoSocial,
    this.cidade,
    this.cep,
    this.rua,
    this.bairro,
    this.numero,
    this.horaAbertura,
    this.horaFechamento,
    this.telefone,
    this.email,
    this.status = 0,
    this.latitude,
    this.longitude,
  });

  bool get temLocalizacao => latitude != null && longitude != null;

  String get enderecoResumo => [rua, numero, bairro, cidade]
      .where((p) => p != null && p.isNotEmpty)
      .join(', ');

  factory Estabelecimentos.fromRow(Map<String, dynamic> row) {
    return Estabelecimentos(
      id: row['id'] as int,
      cnpj: row['cnpj'] as String?,
      nome: row['nome'] as String,
      razaoSocial: row['razao_social'] as String?,
      cidade: row['cidade'] as String?,
      cep: row['cep'] as String?,
      rua: row['rua'] as String?,
      bairro: row['bairro'] as String?,
      numero: row['numero'] as String?,
      horaAbertura: formatHora(row['hora_abertura']),
      horaFechamento: formatHora(row['hora_fechamento']),
      telefone: row['telefone'] as String?,
      email: row['email'] as String?,
      status: (row['status'] as int?) ?? 0,
      latitude: row['latitude'] == null ? null : asDouble(row['latitude']),
      longitude: row['longitude'] == null ? null : asDouble(row['longitude']),
    );
  }
}
