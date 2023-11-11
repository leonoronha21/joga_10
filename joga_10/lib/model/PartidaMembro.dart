class PartidaMembro {
  int idMembro;
  int partidaID;
  int idUser;
  int equipe;

  PartidaMembro({
    required this.idMembro,
    required this.partidaID,
    required this.idUser,
    required this.equipe,
  });

  factory PartidaMembro.fromJson(Map<String, dynamic> json) {
    return PartidaMembro(
      idMembro: json['idMembro'],
      partidaID: json['partidaID'],
      idUser: json['id_user'],
      equipe: json['equipe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMembro': idMembro,
      'partidaID': partidaID,
      'id_user': idUser,
      'equipe': equipe,
    };
  }
  
}
