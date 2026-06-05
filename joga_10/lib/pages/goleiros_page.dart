import 'package:flutter/material.dart';

import 'package:joga_10/model/Goleiro.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/repositories/goleiro_repository.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class GoleirosPage extends StatefulWidget {
  const GoleirosPage({super.key});

  @override
  State<GoleirosPage> createState() => _GoleirosPageState();
}

class _GoleirosPageState extends State<GoleirosPage> {
  final _repo = GoleiroRepository();
  final _partidaRepo = PartidaRepository();
  late Future<List<Goleiro>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Goleiro>> _carregar() async {
    final id = await Sessao.instance.usuarioId;
    if (id == null) return [];
    return _repo.listarDisponiveis(id);
  }

  Future<void> _contratar(Goleiro g) async {
    final id = Sessao.instance.atual?.id;
    if (id == null) return;
    final partidas = await _partidaRepo.listarPorUsuario(id);
    if (!mounted) return;

    Partida? escolhida;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contratar ${g.nome}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Valor: ${formatarMoeda(g.precoJogo)}',
                  style: const TextStyle(color: AppColors.primaryDark)),
              const SizedBox(height: 16),
              const Text('Para qual partida?',
                  style: TextStyle(
                      color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Partida?>(
                initialValue: escolhida,
                isExpanded: true,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.sports_soccer)),
                hint: const Text('Sem partida específica'),
                items: [
                  const DropdownMenuItem<Partida?>(
                      value: null, child: Text('Sem partida específica')),
                  ...partidas.map((p) => DropdownMenuItem<Partida?>(
                        value: p,
                        child: Text(
                          '${p.quadraNome ?? "Partida #${p.id}"} · ${formatarData(p.dataHora)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (p) => setLocal(() => escolhida = p),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('CONFIRMAR CONTRATAÇÃO'),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      try {
        await _repo.contratar(
          goleiroId: g.id,
          partidaId: escolhida?.id,
          solicitanteId: id,
          valor: g.precoJogo,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Convite enviado para ${g.nome}!')),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao contratar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contratar goleiro')),
      body: FutureBuilder<List<Goleiro>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final goleiros = snap.data ?? [];
          if (goleiros.isEmpty) {
            return const EmptyState(
              icone: Icons.sports_handball,
              titulo: 'Nenhum goleiro disponível',
              mensagem: 'Ainda não há goleiros disponíveis na sua região.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: goleiros.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GoleiroCard(
              goleiro: goleiros[i],
              onContratar: () => _contratar(goleiros[i]),
            ),
          );
        },
      ),
    );
  }
}

class _GoleiroCard extends StatelessWidget {
  final Goleiro goleiro;
  final VoidCallback onContratar;
  const _GoleiroCard({required this.goleiro, required this.onContratar});

  @override
  Widget build(BuildContext context) {
    final g = goleiro;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.sports_handball,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    if (g.cidade != null && g.cidade!.isNotEmpty)
                      Text(g.cidade!,
                          style: const TextStyle(
                              color: AppColors.inkMuted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < g.nivel ? Icons.star : Icons.star_border,
                          size: 16,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(formatarMoeda(g.precoJogo),
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          if (g.observacao != null && g.observacao!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(g.observacao!,
                style: const TextStyle(color: AppColors.ink, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onContratar,
              icon: const Icon(Icons.handshake_outlined, size: 18),
              label: const Text('Contratar'),
            ),
          ),
        ],
      ),
    );
  }
}
