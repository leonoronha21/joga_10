import 'dart:async';

import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/pages/home_shell.dart';
import 'package:joga_10/pages/login_page.dart';
import 'package:joga_10/pages/partida_detalhe_page.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/theme/app_theme.dart';
import 'package:joga_10/widgets/partida_link_redirect.dart';

class JogaApp extends StatefulWidget {
  final AppDependencies dependencies;

  const JogaApp({super.key, required this.dependencies});

  @override
  State<JogaApp> createState() => _JogaAppState();
}

class _JogaAppState extends State<JogaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<int>? _partidaLinkSub;

  @override
  void initState() {
    super.initState();
    final conviteService = widget.dependencies.convites;
    _partidaLinkSub = conviteService.partidaLinks.listen(_abrirPartidaPorLink);
    conviteService.iniciar();
  }

  @override
  void dispose() {
    _partidaLinkSub?.cancel();
    unawaited(widget.dependencies.convites.dispose());
    super.dispose();
  }

  Future<void> _abrirPartidaPorLink(int partidaId) async {
    final conviteService = widget.dependencies.convites;
    conviteService.guardarPartidaPendente(partidaId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      if (await widget.dependencies.sessao.estaLogado()) {
        conviteService.consumirPartidaPendente();
        nav.push(
          MaterialPageRoute(
            builder: (_) => PartidaDetalhePage(partidaId: partidaId),
          ),
        );
        return;
      }

      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(redirectPartidaId: partidaId),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Joga 10',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<bool>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _futuro ??= AppDependenciesScope.of(context).restaurarSessao.execute();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _futuro!,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final partidaPendente =
            AppDependenciesScope.of(context).convites.consumirPartidaPendente();
        if (snapshot.data == true) {
          if (partidaPendente != null) {
            return PartidaLinkRedirect(
              partidaId: partidaPendente,
              child: const HomeShell(),
            );
          }
          return const HomeShell();
        }
        return LoginPage(redirectPartidaId: partidaPendente);
      },
    );
  }
}
