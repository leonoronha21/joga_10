

class PartidaData {
  int idEstabelecimento;
  int idQuadra;
  int userId;
  String duracao;
  String dataHora;
  String status;
  double preco;
  List<Map<String, dynamic>> time1Members;
  List<Map<String, dynamic>> time2Members;

  PartidaData({
    required this.idEstabelecimento,
    required this.idQuadra,
    required this.userId,
    required this.duracao,
    required this.dataHora,
    required this.status,
    required this.preco,
    required this.time1Members,
    required this.time2Members,
  });

 Map<String, dynamic> toJson() {
  return {
    'partidas': {
      'id_estabelecimento': idEstabelecimento,
      'id_quadra': idQuadra,
      'user_id': userId,
      'duracao': duracao,
      'data_hora': dataHora,
      'status': status,
      'preco': preco,
    },
    'time1Members': time1Members,
    'time2Members': time2Members,
    };
  }
}