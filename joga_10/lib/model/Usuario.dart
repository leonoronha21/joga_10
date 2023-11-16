class Usuario {
  final int id;
  final String email;
  final String cidade;
  final String complemento;
  final String rua;
  final String bairro;
  final String contato;
  final String password;
  final String segundoNome;
  final String primeiroNome;

  Usuario({
    required this.id,
    required this.email,
    required this.cidade,
    required this.complemento,
    required this.rua,
    required this.bairro,
    required this.contato,
    required this.password,
    required this.segundoNome,
    required this.primeiroNome,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      email: json['email'] as String,
      cidade: json['cidade'] as String,
      complemento: json['complemento'] as String,
      rua: json['rua'] as String,
      bairro: json['bairro'] as String,
      contato: json['contato'] as String,
      password: json['password'] as String,
      segundoNome: json['segundoNome'] as String,
      primeiroNome: json['primeiroNome'] as String,
    );
  }
}
