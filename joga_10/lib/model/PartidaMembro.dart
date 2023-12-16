class PartidaMembro {
  int id; 
  int idUser; 
  String equipe; 
  String nome; 

  PartidaMembro({
    required this.id,
    required this.idUser,
    required this.equipe,
    required this.nome,
  });

  factory PartidaMembro.fromJson(Map<String, dynamic> json) {
    return PartidaMembro(
      id: json['id'],
      idUser: json['id_user'],
      equipe: json['equipe'],
      nome: json['nome'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'id_user': idUser,
      'equipe': equipe,
      'nome': nome, 
    };
  }
}