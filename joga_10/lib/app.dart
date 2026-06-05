import 'package:flutter/material.dart';

import 'package:joga_10/pages/home_shell.dart';
import 'package:joga_10/pages/login_page.dart';
import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/theme/app_theme.dart';

class JogaApp extends StatelessWidget {
  const JogaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joga 10',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Decide a tela inicial: restaura a sessão se existir, senão vai para o login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _restaurarSessao();
  }

  Future<bool> _restaurarSessao() async {
    if (!await Sessao.instance.estaLogado()) return false;
    try {
      final id = await Sessao.instance.usuarioId;
      if (id == null) return false;
      final usuario = await UsuarioRepository().buscarPorId(id);
      if (usuario == null) return false;
      await Sessao.instance.salvar(usuario);
      return true;
    } catch (_) {
      // Banco indisponível: cai para o login.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return snapshot.data == true ? const HomeShell() : const LoginPage();
      },
    );
  }
}
