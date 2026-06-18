/// Usuário do app. NÃO carrega o hash da senha — ele nunca sai do repositório.
class Usuario {
  final int id;
  final String primeiroNome;
  final String? segundoNome;
  final String email;
  final String? cep;
  final String? cidade;
  final String? bairro;
  final String? rua;
  final String? numero;
  final String? complemento;
  final String? contato;
  final String role;

  Usuario({
    required this.id,
    required this.primeiroNome,
    this.segundoNome,
    required this.email,
    this.cep,
    this.cidade,
    this.bairro,
    this.rua,
    this.numero,
    this.complemento,
    this.contato,
    this.role = 'USER',
  });

  String get nomeCompleto => [primeiroNome, segundoNome]
      .where((p) => p != null && p.isNotEmpty)
      .join(' ');
  bool get isAdmin => role == 'ADMIN';

  factory Usuario.fromRow(Map<String, dynamic> row) {
    return Usuario(
      id: row['id'] as int,
      primeiroNome: row['primeiro_nome'] as String,
      segundoNome: row['segundo_nome'] as String?,
      email: row['email'] as String,
      cep: row['cep'] as String?,
      cidade: row['cidade'] as String?,
      bairro: row['bairro'] as String?,
      rua: row['rua'] as String?,
      numero: row['numero'] as String?,
      complemento: row['complemento'] as String?,
      contato: row['contato'] as String?,
      role: (row['role'] as String?) ?? 'USER',
    );
  }
}
