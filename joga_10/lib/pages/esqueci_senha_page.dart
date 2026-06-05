import 'package:flutter/material.dart';

import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/theme/app_colors.dart';

class EsqueciSenhaPage extends StatefulWidget {
  const EsqueciSenhaPage({super.key});

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _novaSenha = TextEditingController();
  final _repo = UsuarioRepository();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _novaSenha.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ok = await _repo.redefinirSenha(_email.text, _novaSenha.text);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida com sucesso!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma conta com esse email.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar ao banco.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Informe seu email e a nova senha.',
              style: TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Email inválido'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _novaSenha,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Mínimo de 4 caracteres' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _redefinir,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('REDEFINIR SENHA'),
            ),
          ],
        ),
      ),
    );
  }
}
