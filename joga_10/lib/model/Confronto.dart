import 'dart:ui';

import 'package:joga_10/db/row_utils.dart';

class ConfrontoStatus {
  static const agendado = 'AGENDADO';
  static const realizado = 'REALIZADO';
  static const cancelado = 'CANCELADO';

  static String label(String s) {
    switch (s) {
      case agendado:
        return 'Agendado';
      case realizado:
        return 'Realizado';
      case cancelado:
        return 'Cancelado';
      default:
        return s;
    }
  }
}

class Confronto {
  final int id;
  final int clubeCasaId;
  final String clubeCasaNome;
  final String clubeCasaCor;
  final int clubeVisitanteId;
  final String clubeVisitanteNome;
  final String clubeVisitanteCor;
  final DateTime dataHora;
  final String tipo; // AMISTOSO / OFICIAL
  final String? local;
  final String status;
  final int? placarCasa;
  final int? placarVisitante;

  Confronto({
    required this.id,
    required this.clubeCasaId,
    required this.clubeCasaNome,
    required this.clubeCasaCor,
    required this.clubeVisitanteId,
    required this.clubeVisitanteNome,
    required this.clubeVisitanteCor,
    required this.dataHora,
    required this.tipo,
    this.local,
    required this.status,
    this.placarCasa,
    this.placarVisitante,
  });

  bool get temPlacar => placarCasa != null && placarVisitante != null;

  Color _cor(String hex) {
    final h = hex.replaceAll('#', '').trim();
    final v = int.tryParse(h, radix: 16) ?? 0x1B3A6B;
    return Color(0xFF000000 | v);
  }

  Color get corCasa => _cor(clubeCasaCor);
  Color get corVisitante => _cor(clubeVisitanteCor);

  factory Confronto.fromRow(Map<String, dynamic> row) {
    return Confronto(
      id: asInt(row['id']),
      clubeCasaId: asInt(row['clube_casa_id']),
      clubeCasaNome: (row['casa_nome'] as String?) ?? '',
      clubeCasaCor: (row['casa_cor'] as String?) ?? '#1B3A6B',
      clubeVisitanteId: asInt(row['clube_visitante_id']),
      clubeVisitanteNome: (row['visitante_nome'] as String?) ?? '',
      clubeVisitanteCor: (row['visitante_cor'] as String?) ?? '#C0392B',
      dataHora: row['data_hora'] as DateTime,
      tipo: (row['tipo'] as String?) ?? 'AMISTOSO',
      local: row['local'] as String?,
      status: (row['status'] as String?) ?? ConfrontoStatus.agendado,
      placarCasa: row['placar_casa'] == null ? null : asInt(row['placar_casa']),
      placarVisitante:
          row['placar_visitante'] == null ? null : asInt(row['placar_visitante']),
    );
  }
}
