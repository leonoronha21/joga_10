import 'package:flutter/material.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/pages/escalacao_page.dart';
import 'package:joga_10/pages/finalizar_partida_page.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/contatos.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class PartidaDetalhePage extends StatefulWidget {
  final int partidaId;
  const PartidaDetalhePage({super.key, required this.partidaId});

  @override
  State<PartidaDetalhePage> createState() => _PartidaDetalhePageState();
}

class _PartidaDetalhePageState extends State<PartidaDetalhePage> {
  final _repo = PartidaRepository();
  late Future<Partida?> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.buscarPorId(widget.partidaId);
  }

  void _recarregar() => setState(() {
        _futuro = _repo.buscarPorId(widget.partidaId);
      });

  Future<void> _adicionarMembro(String equipe) async {
    final nome = await _perguntarNome();
    if (nome == null || nome.trim().isEmpty) return;
    try {
      await _repo.adicionarMembro(
        partidaId: widget.partidaId,
        equipe: equipe,
        nome: nome.trim(),
      );
      _recarregar();
    } catch (_) {
      _msg('Não foi possível adicionar o jogador.');
    }
  }

  Future<String?> _perguntarNome() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar jogador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'Nome do jogador'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final nome = await escolherNomeDeContato();
                    if (nome != null) c.text = nome;
                  },
                  icon: const Icon(Icons.contacts_outlined, size: 18),
                  label: const Text('Importar dos contatos'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizar(Partida p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FinalizarPartidaPage(partida: p)),
    );
    if (ok == true) _recarregar();
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da partida')),
      body: FutureBuilder<Partida?>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final p = snap.data;
          if (p == null) {
            return const EmptyState(
              icone: Icons.error_outline,
              titulo: 'Partida não encontrada',
            );
          }
          final podeFinalizar = p.status == PartidaStatus.agendada ||
              p.status == PartidaStatus.emAndamento;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.quadraNome ?? 'Partida #${p.id}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusBadge(p.status),
                      ],
                    ),
                    if (p.estabelecimentoNome != null) ...[
                      const SizedBox(height: 4),
                      Text(p.estabelecimentoNome!,
                          style: const TextStyle(color: AppColors.inkMuted)),
                    ],
                    const SizedBox(height: 16),
                    _info(Icons.event, formatarDataHora(p.dataHora)),
                    if (p.duracao != null && p.duracao!.isNotEmpty)
                      _info(Icons.timer_outlined, 'Duração: ${p.duracao}'),
                    if (p.preco > 0)
                      _info(Icons.payments_outlined,
                          formatarMoeda(p.preco)),
                    if (p.temPlacar) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            const Text('PLACAR FINAL',
                                style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Time 1  ',
                                    style: TextStyle(color: AppColors.inkMuted)),
                                Text('${p.placarTime1}  x  ${p.placarTime2}',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const Text('  Time 2',
                                    style: TextStyle(color: AppColors.inkMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Time(
                titulo: 'Time 1',
                cor: AppColors.info,
                membros: p.time1,
                onAdd: () => _adicionarMembro(Equipe.time1),
              ),
              const SizedBox(height: 16),
              _Time(
                titulo: 'Time 2',
                cor: AppColors.accent,
                membros: p.time2,
                onAdd: () => _adicionarMembro(Equipe.time2),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final mudou = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EscalacaoPage(partida: p, readOnly: !podeFinalizar),
                    ),
                  );
                  if (mudou == true) _recarregar();
                },
                icon: Icon(podeFinalizar
                    ? Icons.grid_view_rounded
                    : Icons.visibility_outlined),
                label: Text(podeFinalizar
                    ? 'Escalar time (${p.formato})'
                    : 'Ver escalação (${p.formato})'),
              ),
              const SizedBox(height: 12),
              if (podeFinalizar)
                OutlinedButton.icon(
                  onPressed: () => _finalizar(p),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Finalizar e cadastrar placar'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.inkMuted),
            const SizedBox(width: 8),
            Text(texto, style: const TextStyle(color: AppColors.ink)),
          ],
        ),
      );
}

class _Time extends StatelessWidget {
  final String titulo;
  final Color cor;
  final List<PartidaMembro> membros;
  final VoidCallback onAdd;

  const _Time({
    required this.titulo,
    required this.cor,
    required this.membros,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text('${membros.length} jogador(es)',
                  style: const TextStyle(color: AppColors.inkMuted)),
            ],
          ),
          const SizedBox(height: 12),
          if (membros.isEmpty)
            const Text('Sem jogadores ainda.',
                style: TextStyle(color: AppColors.inkMuted))
          else
            ...membros.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cor.withValues(alpha: 0.15),
                      child: Text(
                        m.nome.isNotEmpty ? m.nome[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: cor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(m.nome)),
                    if (m.gols > 0) ...[
                      const Icon(Icons.sports_soccer,
                          size: 15, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text('${m.gols}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Adicionar jogador'),
          ),
        ],
      ),
    );
  }
}
