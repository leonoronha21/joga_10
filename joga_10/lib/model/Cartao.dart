class Cartao {
  
  late String cpf;
  late String cvc;
  late String bandeira;
  late String numeroCartao;
  late String nomeTitular;
  late int idUser;
  late String validade;


  Cartao({
   
    required this.cpf,
    required this.cvc,
    required this.bandeira,
    required this.numeroCartao,
    required this.nomeTitular,
    required this.idUser,
    required this.validade,
  });


  factory Cartao.fromJson(Map<String, dynamic> json) {
    return Cartao(
      
      cpf: json['cpf'] as String,
      cvc: json['cvc'] as String,
      bandeira: json['bandeira'] as String,
      numeroCartao: json['numero_cartao'] as String,
      nomeTitular: json['nome_titular'] as String,
      idUser: json['id_user'] as int,
      validade: json['validade'] as String,
    );
  }


  Map<String, dynamic> toJson() {
    return {
  
      'cpf': cpf,
      'cvc': cvc,
      'bandeira': bandeira,
      'numero_cartao': numeroCartao,
      'nome_titular': nomeTitular,
      'id_user': idUser,
      'validade': validade,
    };
  }
   @override
  String toString() {
   
    String ultimosDigitos = numeroCartao.length >= 4
        ? '**** **** **** ' + numeroCartao.substring(numeroCartao.length - 4)
        : numeroCartao;

    return ultimosDigitos;
  }
}
