import 'package:joga_10/db/row_utils.dart';

/// Equipes possiveis numa partida.
class Equipe {
  static const time1 = 'TIME_1';
  static const time2 = 'TIME_2';
}

class PartidaMembro {
  final int? id;
  final int? partidaId;
  final int? idUser;
  final String? telefone;
  final String equipe;
  final String nome;
  final bool capitao;
  final double? posX; // 0..1 (normalizado no campo)
  final double? posY;
  final int gols;

  PartidaMembro({
    this.id,
    this.partidaId,
    this.idUser,
    this.telefone,
    required this.equipe,
    required this.nome,
    this.capitao = false,
    this.posX,
    this.posY,
    this.gols = 0,
  });

  bool get posicionado => posX != null && posY != null;

  PartidaMembro copyWith({
    String? equipe,
    double? posX,
    double? posY,
    int? gols,
    bool? capitao,
  }) {
    return PartidaMembro(
      id: id,
      partidaId: partidaId,
      idUser: idUser,
      telefone: telefone,
      equipe: equipe ?? this.equipe,
      nome: nome,
      capitao: capitao ?? this.capitao,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      gols: gols ?? this.gols,
    );
  }

  factory PartidaMembro.fromRow(Map<String, dynamic> row) {
    return PartidaMembro(
      id: row['id'] == null ? null : asInt(row['id']),
      partidaId: row['partida_id'] == null ? null : asInt(row['partida_id']),
      idUser: row['id_user'] == null ? null : asInt(row['id_user']),
      telefone: row['telefone'] as String?,
      equipe: (row['equipe'] as String?) ?? Equipe.time1,
      nome: (row['nome'] as String?) ?? '',
      capitao: (row['capitao'] as bool?) ?? false,
      posX: row['pos_x'] == null ? null : asDouble(row['pos_x']),
      posY: row['pos_y'] == null ? null : asDouble(row['pos_y']),
      gols: asInt(row['gols']),
    );
  }
}
