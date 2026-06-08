import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/domain/contracts/usuario_repository_contract.dart';

class RestaurarSessao {
  final SessaoContract sessao;
  final UsuarioRepositoryContract usuarios;

  const RestaurarSessao({
    required this.sessao,
    required this.usuarios,
  });

  Future<bool> execute() async {
    if (!await sessao.estaLogado()) return false;

    final usuarioLocal = await sessao.restaurarLocal();
    try {
      final id = await sessao.usuarioId;
      if (id == null) return false;
      if (id <= 0) return usuarioLocal != null;

      final usuario = await usuarios.buscarPorId(id);
      if (usuario == null) return usuarioLocal != null;

      await sessao.salvar(usuario);
      return true;
    } catch (_) {
      return usuarioLocal != null;
    }
  }
}
