import 'package:joga_10/db/row_utils.dart';

class Liga {
  final int id;
  final String nome;
  final String? cidade;
  final int totalTimes;

  Liga({
    required this.id,
    required this.nome,
    this.cidade,
    this.totalTimes = 0,
  });

  factory Liga.fromRow(Map<String, dynamic> row) {
    return Liga(
      id: asInt(row['id']),
      nome: (row['nome'] as String?) ?? '',
      cidade: row['cidade'] as String?,
      totalTimes: asInt(row['total_times']),
    );
  }
}
