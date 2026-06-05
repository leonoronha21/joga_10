import 'package:flutter/material.dart';

import 'package:joga_10/pages/home_shell.dart';
import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UsuarioRepository();

  final _primeiroNome = TextEditingController();
  final _segundoNome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  final _cidade = TextEditingController();
  final _bairro = TextEditingController();
  final _rua = TextEditingController();
  final _complemento = TextEditingController();
  final _contato = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _primeiroNome,
      _segundoNome,
      _email,
      _senha,
      _confirma,
      _cidade,
      _bairro,
      _rua,
      _complemento,
      _contato,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final resultado = await _repo.cadastrar(
        primeiroNome: _primeiroNome.text,
        segundoNome: _segundoNome.text,
        email: _email.text,
        senha: _senha.text,
        cidade: _cidade.text,
        bairro: _bairro.text,
        rua: _rua.text,
        complemento: _complemento.text,
        contato: _contato.text,
      );
      if (!mounted) return;
      switch (resultado) {
        case ResultadoCadastro.emailJaExiste:
          _msg('Já existe uma conta com esse email.');
          break;
        case ResultadoCadastro.erro:
          _msg('Erro ao cadastrar. Tente novamente.');
          break;
        case ResultadoCadastro.sucesso:
          final usuario = await _repo.login(_email.text, _senha.text);
          if (!mounted) return;
          if (usuario != null) {
            await Sessao.instance.salvar(usuario);
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
          break;
      }
    } catch (e) {
      _msg('Não foi possível conectar ao banco.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _SecaoTitulo('Seus dados'),
            _campo(_primeiroNome, 'Primeiro nome',
                icon: Icons.person_outline, obrigatorio: true),
            _campo(_segundoNome, 'Sobrenome', icon: Icons.person_outline),
            _campo(
              _email,
              'Email',
              icon: Icons.mail_outline,
              tipo: TextInputType.emailAddress,
              validador: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o email';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            _campo(_contato, 'Contato (telefone)',
                icon: Icons.phone_outlined, tipo: TextInputType.phone),
            const SizedBox(height: 8),
            const _SecaoTitulo('Senha'),
            TextFormField(
              controller: _senha,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Mínimo de 4 caracteres' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirma,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  v != _senha.text ? 'As senhas não conferem' : null,
            ),
            const SizedBox(height: 8),
            const _SecaoTitulo('Endereço'),
            _campo(_cidade, 'Cidade', icon: Icons.location_city_outlined),
            _campo(_bairro, 'Bairro', icon: Icons.map_outlined),
            _campo(_rua, 'Rua', icon: Icons.signpost_outlined),
            _campo(_complemento, 'Complemento', icon: Icons.home_outlined),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _cadastrar,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('CADASTRAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    IconData? icon,
    TextInputType? tipo,
    bool obrigatorio = false,
    String? Function(String?)? validador,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator: validador ??
            (obrigatorio
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
                : null),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String texto;
  const _SecaoTitulo(this.texto);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          texto,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
}
