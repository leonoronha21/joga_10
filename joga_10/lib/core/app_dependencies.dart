import 'package:flutter/widgets.dart';

import 'package:joga_10/application/authentication/autenticador_admin_local.dart';
import 'package:joga_10/application/authentication/autenticador_repositorio.dart';
import 'package:joga_10/application/use_cases/autenticar_usuario.dart';
import 'package:joga_10/application/use_cases/cadastrar_usuario.dart';
import 'package:joga_10/application/use_cases/participar_da_partida.dart';
import 'package:joga_10/application/use_cases/restaurar_sessao.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/partida_convite_contract.dart';
import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/domain/contracts/usuario_repository_contract.dart';
import 'package:joga_10/repositories/monetizacao_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/partida_convite_service.dart';
import 'package:joga_10/services/sessao.dart';

class AppDependencies {
  final UsuarioRepositoryContract usuarios;
  final PartidaRepositoryContract partidas;
  final MonetizacaoRepositoryContract monetizacao;
  final SessaoContract sessao;
  final PartidaConviteContract convites;
  final AutenticarUsuario autenticarUsuario;
  final CadastrarUsuario cadastrarUsuario;
  final RestaurarSessao restaurarSessao;
  final ParticiparDaPartida participarDaPartida;

  const AppDependencies({
    required this.usuarios,
    required this.partidas,
    required this.monetizacao,
    required this.sessao,
    required this.convites,
    required this.autenticarUsuario,
    required this.cadastrarUsuario,
    required this.restaurarSessao,
    required this.participarDaPartida,
  });

  factory AppDependencies.local() {
    final usuarios = UsuarioRepository();
    final partidas = PartidaRepository();
    final monetizacao = MonetizacaoRepository();
    final sessao = Sessao();
    final convites = PartidaConviteService();

    return AppDependencies(
      usuarios: usuarios,
      partidas: partidas,
      monetizacao: monetizacao,
      sessao: sessao,
      convites: convites,
      autenticarUsuario: AutenticarUsuario(
        autenticadores: [
          const AutenticadorAdminLocal(),
          AutenticadorRepositorio(usuarios),
        ],
        sessao: sessao,
      ),
      cadastrarUsuario: CadastrarUsuario(
        usuarios: usuarios,
        sessao: sessao,
      ),
      restaurarSessao: RestaurarSessao(
        sessao: sessao,
        usuarios: usuarios,
      ),
      participarDaPartida: ParticiparDaPartida(
        partidas: partidas,
        sessao: sessao,
      ),
    );
  }
}

class AppDependenciesScope extends InheritedWidget {
  final AppDependencies dependencies;

  const AppDependenciesScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  static AppDependencies of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'AppDependenciesScope nao encontrado.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}
