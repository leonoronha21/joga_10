import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/domain/contracts/usuario_repository_contract.dart';

class CadastrarUsuarioCommand {
  final String primeiroNome;
  final String? segundoNome;
  final String email;
  final String senha;
  final String? cidade;
  final String? bairro;
  final String? rua;
  final String? complemento;
  final String? contato;

  const CadastrarUsuarioCommand({
    required this.primeiroNome,
    this.segundoNome,
    required this.email,
    required this.senha,
    this.cidade,
    this.bairro,
    this.rua,
    this.complemento,
    this.contato,
  });
}

class CadastrarUsuario {
  final UsuarioRepositoryContract usuarios;
  final SessaoContract sessao;

  const CadastrarUsuario({
    required this.usuarios,
    required this.sessao,
  });

  Future<ResultadoCadastro> execute(CadastrarUsuarioCommand command) async {
    final resultado = await usuarios.cadastrar(
      primeiroNome: command.primeiroNome,
      segundoNome: command.segundoNome,
      email: command.email,
      senha: command.senha,
      cidade: command.cidade,
      bairro: command.bairro,
      rua: command.rua,
      complemento: command.complemento,
      contato: command.contato,
    );
    if (resultado != ResultadoCadastro.sucesso) return resultado;

    final usuario = await usuarios.login(command.email, command.senha);
    if (usuario == null) return ResultadoCadastro.erro;
    await sessao.salvar(usuario);
    return ResultadoCadastro.sucesso;
  }
}
