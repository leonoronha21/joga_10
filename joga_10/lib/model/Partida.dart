class Partida {
  final int id;
  final int idEstabelecimento;
  final int idQuadra;
  final int userId; // Alterado para dynamic
  final String duracao;
  final String dataHora; // Alterado para dynamic
  final String status;
  final String preco;

  Partida({
    required this.id,
    required this.idEstabelecimento,
    required this.idQuadra,
    required this.userId,
    required this.duracao,
    required this.dataHora,
    required this.status,
    required this.preco,
  });

  factory Partida.fromJson(Map<String, dynamic> json) {
    return Partida(
      id: json['id'] as int,
      idEstabelecimento: json['id_estabelecimento'] as int,
      idQuadra: json['id_quadra'] as int,
      userId: json['user_id'] as int,
      duracao: json['duracao'] as String,
      dataHora: json['data_hora'] as String,
      status: json['status'] as String,
      preco: json['preco'] as String,
    );
  }
}
