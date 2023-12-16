class Estabelecimentos {
  final int id;
  final String cnpj;
  final String nome;
  final String razaoSocial; 
  final String cidade;
  final String cep;
  final String rua;
  final String bairro;
  final String numero;
  final String horaAbertura; 
  final String horaFechamento; 
  final String telefone;
  final String email;

  Estabelecimentos({
    required this.id,
    required this.cnpj,
    required this.nome,
    required this.razaoSocial,
    required this.cidade,
    required this.cep,
    required this.rua,
    required this.bairro,
    required this.numero,
    required this.horaAbertura,
    required this.horaFechamento,
    required this.telefone,
    required this.email,
  });

  factory Estabelecimentos.fromJson(Map<String, dynamic> json) {
    return Estabelecimentos(
      id: json['id'],
      cnpj: json['cnpj'],
      nome: json['nome'],
      razaoSocial: json['razao_social'],
      cidade: json['cidade'],
      cep: json['cep'],
      rua: json['rua'],
      bairro: json['bairro'],
      numero: json['numero'],
      horaAbertura: json['hora_abertura'],
      horaFechamento: json['hora_fechamento'],
      telefone: json['telefone'],
      email: json['email'],
    );
  }
}