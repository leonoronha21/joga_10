import 'dart:typed_data';

import 'package:joga_10/db/row_utils.dart';
import 'package:joga_10/model/Partida.dart';

class TipoPostagem {
  static const publicacao = 'PUBLICACAO';
  static const atividade = 'ATIVIDADE';
}

class VisibilidadePostagem {
  static const amigos = 'AMIGOS';
  static const publico = 'PUBLICO';
}

/// Postagem do feed ("lance"). Pode ter texto e/ou foto.
class Postagem {
  final int id;
  final int autorId;
  final String autorNome;
  final String? texto;
  final Uint8List? foto;
  final String? fotoUrl; // imagem em storage externo (Firestore)
  final int? partidaId;
  final String tipo;
  final String visibilidade;
  final String? atividadeModalidade;
  final String? atividadeLocal;
  final DateTime? atividadeDataHora;
  final String? atividadeDuracao;
  final int? atividadePlacarEquipeA;
  final int? atividadePlacarEquipeB;
  final int? atividadeParticipantes;
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
    this.tipo = TipoPostagem.publicacao,
    this.visibilidade = VisibilidadePostagem.publico,
    this.atividadeModalidade,
    this.atividadeLocal,
    this.atividadeDataHora,
    this.atividadeDuracao,
    this.atividadePlacarEquipeA,
    this.atividadePlacarEquipeB,
    this.atividadeParticipantes,
    required this.criadoEm,
    this.curtidas = 0,
    this.curtiuEu = false,
    this.comentarios = 0,
  });

  bool get isAtividade => tipo == TipoPostagem.atividade;
  bool get publica => visibilidade == VisibilidadePostagem.publico;
  String get modalidadeLabel =>
      ModalidadePartida.label(atividadeModalidade ?? ModalidadePartida.futebol);

  Postagem copyWith({int? curtidas, bool? curtiuEu, int? comentarios}) {
    return Postagem(
      id: id,
      autorId: autorId,
      autorNome: autorNome,
      texto: texto,
      foto: foto,
      fotoUrl: fotoUrl,
      partidaId: partidaId,
      tipo: tipo,
      visibilidade: visibilidade,
      atividadeModalidade: atividadeModalidade,
      atividadeLocal: atividadeLocal,
      atividadeDataHora: atividadeDataHora,
      atividadeDuracao: atividadeDuracao,
      atividadePlacarEquipeA: atividadePlacarEquipeA,
      atividadePlacarEquipeB: atividadePlacarEquipeB,
      atividadeParticipantes: atividadeParticipantes,
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
          : (foto is Uint8List
              ? foto
              : Uint8List.fromList(List<int>.from(foto))),
      fotoUrl: row['foto_url'] as String?,
      partidaId: row['partida_id'] == null ? null : asInt(row['partida_id']),
      tipo: (row['tipo'] as String?) ?? TipoPostagem.publicacao,
      visibilidade:
          (row['visibilidade'] as String?) ?? VisibilidadePostagem.publico,
      atividadeModalidade: row['atividade_modalidade'] as String?,
      atividadeLocal: row['atividade_local'] as String?,
      atividadeDataHora: row['atividade_data_hora'] as DateTime?,
      atividadeDuracao: row['atividade_duracao'] as String?,
      atividadePlacarEquipeA: row['atividade_placar_equipe_a'] == null
          ? null
          : asInt(row['atividade_placar_equipe_a']),
      atividadePlacarEquipeB: row['atividade_placar_equipe_b'] == null
          ? null
          : asInt(row['atividade_placar_equipe_b']),
      atividadeParticipantes: row['atividade_participantes'] == null
          ? null
          : asInt(row['atividade_participantes']),
      criadoEm: row['criado_em'] as DateTime,
      curtidas: asInt(row['curtidas']),
      curtiuEu: (row['curtiu_eu'] as bool?) ?? false,
      comentarios: asInt(row['comentarios']),
    );
  }
}
