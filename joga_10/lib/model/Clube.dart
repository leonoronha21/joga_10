import 'dart:ui';

import 'package:joga_10/db/row_utils.dart';

class Clube {
  final int id;
  final String nome;
  final String? cidade;
  final String cor; // hex '#RRGGBB'
  final int? donoId;

  Clube({
    required this.id,
    required this.nome,
    this.cidade,
    this.cor = '#1B3A6B',
    this.donoId,
  });

  Color get corValue {
    final hex = cor.replaceAll('#', '').trim();
    final v = int.tryParse(hex, radix: 16) ?? 0x1B3A6B;
    return Color(0xFF000000 | v);
  }

  factory Clube.fromRow(Map<String, dynamic> row) {
    return Clube(
      id: asInt(row['id']),
      nome: (row['nome'] as String?) ?? '',
      cidade: row['cidade'] as String?,
      cor: (row['cor'] as String?) ?? '#1B3A6B',
      donoId: row['dono_id'] == null ? null : asInt(row['dono_id']),
    );
  }
}
