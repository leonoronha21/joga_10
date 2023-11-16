class PartidaMembro {
  int id; // ajuste aqui
  int idUser; // ajuste aqui
  String equipe; // ajuste aqui
  String nome; // ajuste aqui

  PartidaMembro({
    required this.id,
    required this.idUser,
    required this.equipe,
    required this.nome,
  });

  factory PartidaMembro.fromJson(Map<String, dynamic> json) {
    return PartidaMembro(
      id: json['id'], // ajuste aqui
      idUser: json['id_user'],
      equipe: json['equipe'],
      nome: json['nome'], // ajuste aqui
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // ajuste aqui
      'id_user': idUser,
      'equipe': equipe,
      'nome': nome, // ajuste aqui
    };
  }
}