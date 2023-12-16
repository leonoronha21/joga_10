import 'package:joga_10/model/PartidaMembro.dart';

class Partida {
  final int id;
  final int idEstabelecimento;
  final int idQuadra;
  final int userId; 
  final String duracao;
  final String dataHora; 
  final String status;
  final double preco;
  final List<PartidaMembro> membros;

  Partida({
    required this.id,
    required this.idEstabelecimento,
    required this.idQuadra,
    required this.userId,
    required this.duracao,
    required this.dataHora,
    required this.status,
    required this.preco,
    required this.membros,
  });

  factory Partida.fromJson(Map<String, dynamic> json) {
    
    List<PartidaMembro> membros = List<PartidaMembro>.from(
      json['membros'].map((membro) => PartidaMembro.fromJson(membro)),
    );
    return Partida(
    
      id: json['id'] as int,
      idEstabelecimento: json['id_estabelecimento'] as int,
      idQuadra: json['id_quadra'] as int,
      userId: json['user_id'] as int,
      duracao: json['duracao'] as String,
      dataHora: json['data_hora'] as String,
      status: json['status'] as String,
      preco: json['preco'] as double,
      membros: membros,
    );
  }
}
