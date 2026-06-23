import 'dart:async';

import 'package:flutter/material.dart';

import 'package:joga_10/model/Amizade.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/repositories/amizade_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class AmigosPage extends StatefulWidget {
  const AmigosPage({super.key});

  @override
  State<AmigosPage> createState() => _AmigosPageState();
}

class _AmigosPageState extends State<AmigosPage> {
  final _repo = AmizadeRepository();
  final _busca = TextEditingController();
  Timer? _debounce;

  int? _meuId;
  List<PedidoAmizade> _pedidos = [];
  List<Usuario> _amigos = [];
  List<UsuarioBusca> _resultados = [];
  bool _carregando = true;
  bool _buscando = false;
  bool _encontrarPessoas = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _meuId = await Sessao.instance.usuarioId;
    await _recarregar();
  }

  Future<void> _recarregar() async {
    if (_meuId == null) return;
    setState(() => _carregando = true);
    try {
      final pedidos = await _repo.listarPedidosRecebidos(_meuId!);
      final amigos = await _repo.listarAmigos(_meuId!);
      if (mounted) {
        setState(() {
          _pedidos = pedidos;
          _amigos = amigos;
          _carregando = false;
        });
      }
      if (_encontrarPessoas) await _buscar(_busca.text);
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _buscar(String termo) async {
    if (_meuId == null) return;
    setState(() => _buscando = true);
    try {
      final res = await _repo.buscarUsuarios(_meuId!, termo.trim());
      if (mounted) setState(() => _resultados = res);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _enviar(int outroId) async {
    final meuId = _meuId;
    if (meuId == null) {
      _msg('Entre na sua conta para adicionar amigos.');
      return;
    }
    try {
      await _repo.enviarPedido(meuId, outroId);
      if (!mounted) return;
      _msg('Solicitacao de amizade enviada.');
      await _recarregar();
    } on StateError catch (erro) {
      _msg(erro.message);
    } catch (_) {
      _msg('Nao foi possivel enviar a solicitacao.');
    }
  }

  Future<void> _responder(int amizadeId, bool aceitar) async {
    await _repo.responder(amizadeId, aceitar);
    await _recarregar();
  }

  bool get _pesquisando => _busca.text.trim().isNotEmpty;

  void _alterarModo(bool encontrar) {
    setState(() => _encontrarPessoas = encontrar);
    if (encontrar) {
      _buscar(_busca.text);
    } else {
      _busca.clear();
      setState(() => _resultados = []);
    }
  }

  void _agendarBusca(String termo) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _buscar(termo),
    );
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.people_outline),
                    label: Text('Meus amigos'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.person_search_outlined),
                    label: Text('Encontrar pessoas'),
                  ),
                ],
                selected: {_encontrarPessoas},
                onSelectionChanged: (selecao) => _alterarModo(selecao.first),
              ),
            ),
          ),
          if (_encontrarPessoas)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _busca,
                onChanged: _agendarBusca,
                decoration: InputDecoration(
                  hintText: 'Buscar perfis existentes no Joga10',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _pesquisando
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _busca.clear();
                            _buscar('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          Expanded(
            child: _carregando
                ? const LoadingView()
                : _encontrarPessoas
                    ? _listaBusca()
                    : _listaPrincipal(),
          ),
        ],
      ),
    );
  }

  Widget _listaBusca() {
    if (_buscando) return const LoadingView();
    if (_resultados.isEmpty) {
      return EmptyState(
        icone: Icons.person_search_outlined,
        titulo: _pesquisando
            ? 'Nenhum perfil encontrado'
            : 'Nenhum outro perfil disponível',
        mensagem: _pesquisando
            ? 'Tente buscar usando outro nome.'
            : 'Novos usuários do app aparecerão aqui.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _itemBusca(_resultados[i]),
    );
  }

  Widget _listaPrincipal() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _recarregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_pedidos.isNotEmpty) ...[
            const Text('Solicitações',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            ..._pedidos.map(_itemPedido),
            const SizedBox(height: 16),
          ],
          Text('Amigos (${_amigos.length})',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (_amigos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text(
                    'Você ainda não tem amigos.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _alterarModo(true),
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Encontrar pessoas'),
                  ),
                ],
              ),
            )
          else
            ..._amigos.map(_itemAmigo),
        ],
      ),
    );
  }

  Widget _avatar(String nome) => CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          nome.isNotEmpty ? nome[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      );

  Widget _itemPedido(PedidoAmizade p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            _avatar(p.nome),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (p.email.isNotEmpty)
                    Text(p.email,
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _responder(p.amizadeId, true),
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              tooltip: 'Aceitar',
            ),
            IconButton(
              onPressed: () => _responder(p.amizadeId, false),
              icon: const Icon(Icons.cancel, color: AppColors.danger),
              tooltip: 'Recusar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemAmigo(Usuario u) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            _avatar(u.primeiroNome),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.nomeCompleto,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if ((u.cidade ?? '').isNotEmpty)
                    Text(u.cidade!,
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.people, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _itemBusca(UsuarioBusca u) {
    Widget acao;
    switch (u.status) {
      case StatusAmizade.amigos:
        acao = const Chip(label: Text('Amigos'));
        break;
      case StatusAmizade.pendenteEnviado:
        acao = const Chip(label: Text('Pendente'));
        break;
      case StatusAmizade.pendenteRecebido:
        acao = ElevatedButton(
          onPressed: () =>
              u.amizadeId != null ? _responder(u.amizadeId!, true) : null,
          child: const Text('Aceitar'),
        );
        break;
      case StatusAmizade.nenhuma:
        acao = OutlinedButton.icon(
          onPressed: () => _enviar(u.id),
          icon: const Icon(Icons.person_add_alt, size: 18),
          label: const Text('Adicionar'),
        );
        break;
    }
    return AppCard(
      child: Row(
        children: [
          _avatar(u.nome),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nome,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (u.email.isNotEmpty)
                  Text(u.email,
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 122, child: acao),
        ],
      ),
    );
  }
}
