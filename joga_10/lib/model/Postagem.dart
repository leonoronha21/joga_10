import 'dart:typed_data';

import 'package:joga_10/db/row_utils.dart';

/// Postagem do feed ("lance"). Pode ter texto e/ou foto.
class Postagem {
  final int id;
  final int autorId;
  final String autorNome;
  final String? texto;
  final Uint8List? foto;
  final String? fotoUrl; // imagem em storage externo (Firestore)
  final int? partidaId;
  final DateTime criadoEm;
  final int curtidas;
  final bool curtiuEu;
  final int comentarios;

  Postagem({
    required this.id,
    required this.autorId,
    required this.autorNome,
    this.texto,
    this.foto,
    this.fotoUrl,
    this.partidaId,
    required this.criadoEm,
    this.curtidas = 0,
    this.curtiuEu = false,
    this.comentarios = 0,
  });

  Postagem copyWith({int? curtidas, bool? curtiuEu, int? comentarios}) {
    return Postagem(
      id: id,
      autorId: autorId,
      autorNome: autorNome,
      texto: texto,
      foto: foto,
      fotoUrl: fotoUrl,
      partidaId: partidaId,
      criadoEm: criadoEm,
      curtidas: curtidas ?? this.curtidas,
      curtiuEu: curtiuEu ?? this.curtiuEu,
      comentarios: comentarios ?? this.comentarios,
    );
  }

  factory Postagem.fromRow(Map<String, dynamic> row) {
    final foto = row['foto'];
    return Postagem(
      id: asInt(row['id']),
      autorId: asInt(row['autor_id']),
      autorNome: (row['autor_nome'] as String?) ?? 'Usuário',
      texto: row['texto'] as String?,
      foto: foto == null
          ? null
          : (foto is Uint8List ? foto : Uint8List.fromList(List<int>.from(foto))),
      fotoUrl: row['foto_url'] as String?,
      partidaId: row['partida_id'] == null ? null : asInt(row['partida_id']),
      criadoEm: row['criado_em'] as DateTime,
      curtidas: asInt(row['curtidas']),
      curtiuEu: (row['curtiu_eu'] as bool?) ?? false,
      comentarios: asInt(row['comentarios']),
    );
  }
}
