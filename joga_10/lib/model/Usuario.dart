/// Usuário do app. NÃO carrega o hash da senha — ele nunca sai do repositório.
class Usuario {
  final int id;
  final String primeiroNome;
  final String? segundoNome;
  final String email;
  final String? cidade;
  final String? complemento;
  final String? rua;
  final String? bairro;
  final String? contato;
  final String role;

  Usuario({
    required this.id,
    required this.primeiroNome,
    this.segundoNome,
    required this.email,
    this.cidade,
    this.complemento,
    this.rua,
    this.bairro,
    this.contato,
    this.role = 'USER',
  });

  String get nomeCompleto =>
      [primeiroNome, segundoNome].where((p) => p != null && p.isNotEmpty).join(' ');

  factory Usuario.fromRow(Map<String, dynamic> row) {
    return Usuario(
      id: row['id'] as int,
      primeiroNome: row['primeiro_nome'] as String,
      segundoNome: row['segundo_nome'] as String?,
      email: row['email'] as String,
      cidade: row['cidade'] as String?,
      complemento: row['complemento'] as String?,
      rua: row['rua'] as String?,
      bairro: row['bairro'] as String?,
      contato: row['contato'] as String?,
      role: (row['role'] as String?) ?? 'USER',
    );
  }
}
