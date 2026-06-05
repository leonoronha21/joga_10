import 'package:joga_10/db/row_utils.dart';

class Quadras {
  final int id;
  final int idEstabelecimento;
  final String nome;
  final String tipoQuadra;
  final double preco;

  Quadras({
    required this.id,
    required this.idEstabelecimento,
    required this.nome,
    required this.tipoQuadra,
    required this.preco,
  });

  factory Quadras.fromRow(Map<String, dynamic> row) {
    return Quadras(
      id: asInt(row['id']),
      idEstabelecimento: asInt(row['id_estabelecimento']),
      nome: (row['nome'] as String?) ?? '',
      tipoQuadra: (row['tipo_quadra'] as String?) ?? '',
      preco: asDouble(row['preco']),
    );
  }
}
