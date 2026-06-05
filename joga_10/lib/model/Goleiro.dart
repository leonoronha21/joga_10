import 'package:joga_10/db/row_utils.dart';

class Goleiro {
  final int id;
  final int usuarioId;
  final String nome;
  final String? cidade;
  final double precoJogo;
  final int nivel; // 1..5
  final bool disponivel;
  final String? observacao;
  final String? contato;

  Goleiro({
    required this.id,
    required this.usuarioId,
    required this.nome,
    this.cidade,
    this.precoJogo = 0,
    this.nivel = 3,
    this.disponivel = true,
    this.observacao,
    this.contato,
  });

  factory Goleiro.fromRow(Map<String, dynamic> row) {
    return Goleiro(
      id: asInt(row['id']),
      usuarioId: asInt(row['usuario_id']),
      nome: (row['nome'] as String?)?.trim() ?? 'Goleiro',
      cidade: row['cidade'] as String?,
      precoJogo: asDouble(row['preco_jogo']),
      nivel: asInt(row['nivel'], fallback: 3),
      disponivel: (row['disponivel'] as bool?) ?? true,
      observacao: row['observacao'] as String?,
      contato: row['contato'] as String?,
    );
  }
}
