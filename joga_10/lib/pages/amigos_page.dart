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

  int? _meuId;
  List<PedidoAmizade> _pedidos = [];
  List<Usuario> _amigos = [];
  List<UsuarioBusca> _resultados = [];
  bool _carregando = true;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
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
      if (_busca.text.trim().isNotEmpty) await _buscar(_busca.text);
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _buscar(String termo) async {
    if (_meuId == null) return;
    if (termo.trim().isEmpty) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _buscando = true);
    try {
      final res = await _repo.buscarUsuarios(_meuId!, termo.trim());
      if (mounted) setState(() => _resultados = res);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _enviar(int outroId) async {
    await _repo.enviarPedido(_meuId!, outroId);
    await _recarregar();
  }

  Future<void> _responder(int amizadeId, bool aceitar) async {
    await _repo.responder(amizadeId, aceitar);
    await _recarregar();
  }

  bool get _pesquisando => _busca.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _busca,
              onChanged: _buscar,
              decoration: InputDecoration(
                hintText: 'Buscar pessoas por nome ou email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _pesquisando
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busca.clear();
                          setState(() => _resultados = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _carregando
                ? const LoadingView()
                : _pesquisando
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
      return const EmptyState(
        icone: Icons.search_off,
        titulo: 'Ninguém encontrado',
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Você ainda não tem amigos. Busque pessoas acima para adicionar.',
                style: TextStyle(color: AppColors.inkMuted),
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
                  Text(u.email,
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
                Text(u.email,
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 12)),
              ],
            ),
          ),
          acao,
        ],
      ),
    );
  }
}
