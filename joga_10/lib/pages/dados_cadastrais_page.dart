import 'package:flutter/material.dart';

import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/sessao.dart';

class DadosCadastraisPage extends StatefulWidget {
  const DadosCadastraisPage({super.key});

  @override
  State<DadosCadastraisPage> createState() => _DadosCadastraisPageState();
}

class _DadosCadastraisPageState extends State<DadosCadastraisPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UsuarioRepository();

  late final TextEditingController _primeiroNome;
  late final TextEditingController _segundoNome;
  late final TextEditingController _contato;
  late final TextEditingController _cidade;
  late final TextEditingController _bairro;
  late final TextEditingController _rua;
  late final TextEditingController _complemento;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final u = Sessao.instance.atual;
    _primeiroNome = TextEditingController(text: u?.primeiroNome ?? '');
    _segundoNome = TextEditingController(text: u?.segundoNome ?? '');
    _contato = TextEditingController(text: u?.contato ?? '');
    _cidade = TextEditingController(text: u?.cidade ?? '');
    _bairro = TextEditingController(text: u?.bairro ?? '');
    _rua = TextEditingController(text: u?.rua ?? '');
    _complemento = TextEditingController(text: u?.complemento ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _primeiroNome,
      _segundoNome,
      _contato,
      _cidade,
      _bairro,
      _rua,
      _complemento,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    setState(() => _salvando = true);
    try {
      await _repo.atualizar(
        id: id,
        primeiroNome: _primeiroNome.text,
        segundoNome: _segundoNome.text,
        contato: _contato.text,
        cidade: _cidade.text,
        bairro: _bairro.text,
        rua: _rua.text,
        complemento: _complemento.text,
      );
      final atualizado = await _repo.buscarPorId(id);
      if (atualizado != null) await Sessao.instance.salvar(atualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados cadastrais')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _campo(_primeiroNome, 'Primeiro nome',
                icon: Icons.person_outline, obrigatorio: true),
            _campo(_segundoNome, 'Sobrenome', icon: Icons.person_outline),
            _campo(_contato, 'Contato', icon: Icons.phone_outlined),
            _campo(_cidade, 'Cidade', icon: Icons.location_city_outlined),
            _campo(_bairro, 'Bairro', icon: Icons.map_outlined),
            _campo(_rua, 'Rua', icon: Icons.signpost_outlined),
            _campo(_complemento, 'Complemento', icon: Icons.home_outlined),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label,
      {IconData? icon, bool obrigatorio = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator: obrigatorio
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }
}
