import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/services/via_cep_service.dart';
import 'package:joga_10/theme/app_colors.dart';

class DadosCadastraisPage extends StatefulWidget {
  const DadosCadastraisPage({super.key});

  @override
  State<DadosCadastraisPage> createState() => _DadosCadastraisPageState();
}

class _DadosCadastraisPageState extends State<DadosCadastraisPage> {
  static const String _cidadeFixa = 'Porto Alegre';

  final _formKey = GlobalKey<FormState>();
  final _repo = UsuarioRepository();
  final _viaCep = ViaCepService();

  late final TextEditingController _primeiroNome;
  late final TextEditingController _segundoNome;
  late final TextEditingController _contato;
  final _cep = MaskedTextController(mask: '00000-000');
  late final TextEditingController _bairro;
  late final TextEditingController _rua;
  late final TextEditingController _numero;
  late final TextEditingController _complemento;

  bool _salvando = false;
  bool _buscandoCep = false;

  @override
  void initState() {
    super.initState();
    final u = Sessao.instance.atual;
    _primeiroNome = TextEditingController(text: u?.primeiroNome ?? '');
    _segundoNome = TextEditingController(text: u?.segundoNome ?? '');
    _contato = TextEditingController(text: u?.contato ?? '');
    _bairro = TextEditingController(text: u?.bairro ?? '');
    _rua = TextEditingController(text: u?.rua ?? '');
    _numero = TextEditingController(text: u?.numero ?? '');
    _complemento = TextEditingController(text: u?.complemento ?? '');
    if ((u?.cep ?? '').isNotEmpty) _cep.text = u!.cep!;
    _carregarPerfil();
  }

  /// Na sessão Google a sessão local não traz o endereço — carregamos do
  /// Firestore para pré-preencher.
  Future<void> _carregarPerfil() async {
    try {
      final perfil = await _repo.perfilFirestore();
      if (perfil == null || !mounted) return;
      setState(() {
        if (perfil.primeiroNome.isNotEmpty) {
          _primeiroNome.text = perfil.primeiroNome;
        }
        _segundoNome.text = perfil.segundoNome ?? _segundoNome.text;
        _contato.text = perfil.contato ?? _contato.text;
        if ((perfil.cep ?? '').isNotEmpty) _cep.text = perfil.cep!;
        _bairro.text = perfil.bairro ?? _bairro.text;
        _rua.text = perfil.rua ?? _rua.text;
        _numero.text = perfil.numero ?? _numero.text;
        _complemento.text = perfil.complemento ?? _complemento.text;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [
      _primeiroNome,
      _segundoNome,
      _contato,
      _cep,
      _bairro,
      _rua,
      _numero,
      _complemento,
    ]) {
      c.dispose();
    }
    _viaCep.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    if (_buscandoCep) return;
    setState(() => _buscandoCep = true);
    try {
      final endereco = await _viaCep.buscar(_cep.text);
      if (!mounted) return;
      if (endereco == null) {
        _mostrarMensagem('CEP não encontrado.');
        return;
      }
      if (endereco.cidade.toLowerCase() != _cidadeFixa.toLowerCase()) {
        _mostrarMensagem('No momento, o Joga10 atende Porto Alegre-RS.');
        return;
      }
      setState(() {
        _cep.text = endereco.cep;
        if (endereco.bairro.isNotEmpty) _bairro.text = endereco.bairro;
        if (endereco.logradouro.isNotEmpty) _rua.text = endereco.logradouro;
      });
    } catch (_) {
      if (mounted) _mostrarMensagem('Não foi possível consultar o CEP.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final atual = Sessao.instance.atual;
    if (atual == null) return;
    setState(() => _salvando = true);
    try {
      await _repo.atualizar(
        id: atual.id,
        primeiroNome: _primeiroNome.text,
        segundoNome: _segundoNome.text,
        contato: _contato.text,
        cep: _cep.text,
        cidade: _cidadeFixa,
        bairro: _bairro.text,
        rua: _rua.text,
        numero: _numero.text,
        complemento: _complemento.text,
      );
      // Atualiza a sessão sem sobrescrever id/email/role (não usa buscarPorId,
      // que na sessão Google retornaria o usuário demo).
      final atualizado = Usuario(
        id: atual.id,
        email: atual.email,
        role: atual.role,
        primeiroNome: _primeiroNome.text.trim(),
        segundoNome:
            _segundoNome.text.trim().isEmpty ? null : _segundoNome.text.trim(),
        contato: _contato.text.trim(),
        cep: _cep.text.trim(),
        cidade: _cidadeFixa,
        bairro: _bairro.text.trim(),
        rua: _rua.text.trim(),
        numero: _numero.text.trim(),
        complemento: _complemento.text.trim(),
      );
      await Sessao.instance.salvar(atualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados!')),
      );
      Navigator.pop(context);
    } catch (_) {
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
            const _Secao('Seus dados'),
            _campo(_primeiroNome, 'Primeiro nome',
                icon: Icons.person_outline, obrigatorio: true),
            _campo(_segundoNome, 'Sobrenome', icon: Icons.person_outline),
            _campo(_contato, 'Telefone',
                icon: Icons.phone_outlined, tipo: TextInputType.phone),
            const SizedBox(height: 8),
            const _Secao('Endereço'),
            _campo(
              _cep,
              'CEP',
              icon: Icons.local_post_office_outlined,
              tipo: TextInputType.number,
              helper: 'Digite o CEP e toque na lupa para preencher o endereço.',
              onEditingComplete: _buscarCep,
              suffixIcon: IconButton(
                onPressed: _buscandoCep ? null : _buscarCep,
                icon: _buscandoCep
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                tooltip: 'Buscar CEP',
              ),
            ),
            _campoCidadeFixa(),
            _campo(_bairro, 'Bairro', icon: Icons.map_outlined),
            _campo(_rua, 'Rua', icon: Icons.signpost_outlined),
            _campo(_numero, 'Número',
                icon: Icons.numbers_outlined, tipo: TextInputType.number),
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

  Widget _campoCidadeFixa() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        initialValue: _cidadeFixa,
        decoration: const InputDecoration(
          labelText: 'Cidade',
          prefixIcon: Icon(Icons.location_city_outlined),
          helperText: 'Disponível em Porto Alegre-RS no momento.',
          suffixIcon: Icon(Icons.lock_outline, size: 18),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    IconData? icon,
    bool obrigatorio = false,
    TextInputType? tipo,
    String? helper,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          helperText: helper,
          suffixIcon: suffixIcon,
        ),
        validator: obrigatorio
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String texto;
  const _Secao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
