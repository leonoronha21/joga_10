import 'package:flutter/material.dart';

import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/ClubeJogador.dart';
import 'package:joga_10/pages/clube_escalacao_page.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class ClubeDetalhePage extends StatefulWidget {
  final Clube clube;
  const ClubeDetalhePage({super.key, required this.clube});

  @override
  State<ClubeDetalhePage> createState() => _ClubeDetalhePageState();
}

class _ClubeDetalhePageState extends State<ClubeDetalhePage> {
  final _repo = CampeonatoRepository();
  late Future<List<ClubeJogador>> _futuro;

  static const _posicoes = ['Goleiro', 'Zagueiro', 'Lateral', 'Meia', 'Atacante'];

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarElenco(widget.clube.id);
  }

  void _recarregar() =>
      setState(() => _futuro = _repo.listarElenco(widget.clube.id));

  Future<void> _adicionar() async {
    final nome = TextEditingController();
    final numero = TextEditingController();
    String posicao = _posicoes.last;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Adicionar ao elenco'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: posicao,
                  decoration: const InputDecoration(labelText: 'Posição'),
                  items: _posicoes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setLocal(() => posicao = v ?? posicao),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numero,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Adicionar')),
          ],
        ),
      ),
    );
    if (ok == true && nome.text.trim().isNotEmpty) {
      await _repo.adicionarJogadorClube(
        clubeId: widget.clube.id,
        nome: nome.text,
        posicao: posicao,
        numero: int.tryParse(numero.text),
      );
      _recarregar();
    }
  }

  Future<void> _remover(ClubeJogador j) async {
    await _repo.removerJogadorClube(j.id);
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.clube;
    return Scaffold(
      appBar: AppBar(title: Text(c.nome)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionar,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Jogador'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: c.corValue,
                  child: Text(
                    c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nome,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      if (c.cidade != null && c.cidade!.isNotEmpty)
                        Text(c.cidade!,
                            style:
                                const TextStyle(color: AppColors.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<ClubeJogador>>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                    padding: EdgeInsets.all(24), child: LoadingView());
              }
              final elenco = snap.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Elenco (${elenco.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      const Spacer(),
                      if (elenco.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ClubeEscalacaoPage(clube: c)),
                          ),
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          label: const Text('Escalação'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (elenco.isEmpty)
                    const Text(
                      'Nenhum jogador no elenco. Toque em "Jogador" para adicionar.',
                      style: TextStyle(color: AppColors.inkMuted),
                    )
                  else
                    ...elenco.map((j) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      c.corValue.withValues(alpha: 0.15),
                                  child: Text(
                                    j.numero?.toString() ??
                                        (j.nome.isNotEmpty
                                            ? j.nome[0].toUpperCase()
                                            : '?'),
                                    style: TextStyle(
                                        color: c.corValue,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(j.nome,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      if (j.posicao != null)
                                        Text(j.posicao!,
                                            style: const TextStyle(
                                                color: AppColors.inkMuted,
                                                fontSize: 13)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _remover(j),
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
