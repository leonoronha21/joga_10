import 'package:joga_10/db/row_utils.dart';

class ClubeJogador {
  final int id;
  final int clubeId;
  final String nome;
  final String? posicao;
  final int? numero;
  final double? posX; // escalação do clube (0..1)
  final double? posY;

  ClubeJogador({
    required this.id,
    required this.clubeId,
    required this.nome,
    this.posicao,
    this.numero,
    this.posX,
    this.posY,
  });

  bool get posicionado => posX != null && posY != null;

  factory ClubeJogador.fromRow(Map<String, dynamic> row) {
    return ClubeJogador(
      id: asInt(row['id']),
      clubeId: asInt(row['clube_id']),
      nome: (row['nome'] as String?) ?? '',
      posicao: row['posicao'] as String?,
      numero: row['numero'] == null ? null : asInt(row['numero']),
      posX: row['pos_x'] == null ? null : asDouble(row['pos_x']),
      posY: row['pos_y'] == null ? null : asDouble(row['pos_y']),
    );
  }
}
