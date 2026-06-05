import 'dart:ui';

import 'package:joga_10/db/row_utils.dart';

/// Uma linha da tabela de classificação de uma liga.
class LinhaClassificacao {
  final int clubeId;
  final String nome;
  final String cor;
  final int jogos;
  final int vitorias;
  final int empates;
  final int derrotas;
  final int golsPro;
  final int golsContra;
  final int saldo;
  final int pontos;

  LinhaClassificacao({
    required this.clubeId,
    required this.nome,
    required this.cor,
    required this.jogos,
    required this.vitorias,
    required this.empates,
    required this.derrotas,
    required this.golsPro,
    required this.golsContra,
    required this.saldo,
    required this.pontos,
  });

  Color get corValue {
    final hex = cor.replaceAll('#', '').trim();
    final v = int.tryParse(hex, radix: 16) ?? 0x1B3A6B;
    return Color(0xFF000000 | v);
  }

  factory LinhaClassificacao.fromRow(Map<String, dynamic> row) {
    return LinhaClassificacao(
      clubeId: asInt(row['clube_id']),
      nome: (row['nome'] as String?) ?? '',
      cor: (row['cor'] as String?) ?? '#1B3A6B',
      jogos: asInt(row['j']),
      vitorias: asInt(row['v']),
      empates: asInt(row['e']),
      derrotas: asInt(row['d']),
      golsPro: asInt(row['gp']),
      golsContra: asInt(row['gc']),
      saldo: asInt(row['sg']),
      pontos: asInt(row['pts']),
    );
  }
}
