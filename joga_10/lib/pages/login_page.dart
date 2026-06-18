import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/pages/cadastro_page.dart';
import 'package:joga_10/pages/esqueci_senha_page.dart';
import 'package:joga_10/pages/home_shell.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/partida_link_redirect.dart';

class LoginPage extends StatefulWidget {
  final int? redirectPartidaId;

  const LoginPage({super.key, this.redirectPartidaId});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final login = _email.text.trim().toLowerCase();
    final senha = _senha.text;

    if (login.isEmpty || senha.isEmpty) {
      _msg('Preencha usuario e senha.');
      return;
    }

    setState(() => _loading = true);
    try {
      final dependencies = AppDependenciesScope.of(context);
      final usuario =
          await dependencies.autenticarUsuario.execute(login, senha);
      if (!mounted) return;
      if (usuario == null) {
        _msg('Usuario ou senha invalidos.');
        return;
      }
      _concluirLogin();
    } catch (_) {
      _msg('Nao foi possivel conectar ao banco. Verifique a conexao.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() => _loading = true);
    try {
      final dependencies = AppDependenciesScope.of(context);
      final usuario = await dependencies.autenticacaoFirebase.entrarComGoogle();
      if (usuario == null || !mounted) return;
      await dependencies.sessao.salvar(usuario);
      if (!mounted) return;
      _concluirLogin();
    } catch (erro) {
      _msg(_mensagemErroGoogle(erro));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mensagemErroGoogle(Object erro) {
    final texto = erro.toString();
    if (texto.contains('sign_in_failed') ||
        texto.contains('ApiException: 10')) {
      return 'Login Google ainda não está habilitado para este app.';
    }
    if (texto.contains('permission-denied')) {
      return 'Login concluído, mas não foi possível sincronizar o perfil.';
    }
    return 'Nao foi possivel entrar com Google.';
  }

  void _concluirLogin() {
    final partidaPendente =
        AppDependenciesScope.of(context).convites.consumirPartidaPendente();
    final redirectId = widget.redirectPartidaId ?? partidaPendente;
    final destino = redirectId == null
        ? const HomeShell()
        : PartidaLinkRedirect(
            partidaId: redirectId,
            child: const HomeShell(),
          );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destino),
      (route) => false,
    );
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final redirectId = widget.redirectPartidaId;
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/img/Joga_transparente.png',
                      height: 110,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bora marcar a proxima pelada?',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Entrar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    redirectId == null
                        ? 'Acesse sua conta para jogar com a gente.'
                        : 'Entre para acessar a partida #$redirectId.',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email ou usuario',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _senha,
                    obscureText: _obscure,
                    onSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EsqueciSenhaPage(),
                        ),
                      ),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _entrar,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text('ENTRAR'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CadastroPage(
                                  redirectPartidaId: redirectId,
                                ),
                              ),
                            ),
                    child: const Text('Criar conta'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _entrarComGoogle,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continuar com Google'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
