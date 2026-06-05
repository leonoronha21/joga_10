import 'package:joga_10/db/row_utils.dart';

class Comentario {
  final int id;
  final int autorId;
  final String autorNome;
  final String texto;
  final DateTime criadoEm;

  Comentario({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.criadoEm,
  });

  factory Comentario.fromRow(Map<String, dynamic> row) {
    return Comentario(
      id: asInt(row['id']),
      autorId: asInt(row['autor_id']),
      autorNome: (row['autor_nome'] as String?) ?? 'Usuário',
      texto: (row['texto'] as String?) ?? '',
      criadoEm: row['criado_em'] as DateTime,
    );
  }
}
