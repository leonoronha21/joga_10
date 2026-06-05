import 'package:joga_10/db/row_utils.dart';

/// Cartão do usuário.
///
/// SEGURANÇA (PCI-DSS / LGPD): guardamos apenas dados de exibição.
/// Nunca armazenamos número completo, CVC ou CPF.
class Cartao {
  final int? id;
  final int idUser;
  final String nomeTitular;
  final String? bandeira;
  final String ultimos4;
  final String validade; // MM/AAAA

  Cartao({
    this.id,
    required this.idUser,
    required this.nomeTitular,
    this.bandeira,
    required this.ultimos4,
    required this.validade,
  });

  String get mascarado => '•••• •••• •••• $ultimos4';

  factory Cartao.fromRow(Map<String, dynamic> row) {
    return Cartao(
      id: row['id'] == null ? null : asInt(row['id']),
      idUser: asInt(row['id_user']),
      nomeTitular: (row['nome_titular'] as String?) ?? '',
      bandeira: row['bandeira'] as String?,
      ultimos4: (row['ultimos4'] as String?)?.trim() ?? '',
      validade: (row['validade'] as String?) ?? '',
    );
  }
}
