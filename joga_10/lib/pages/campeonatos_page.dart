import 'package:flutter/material.dart';

import 'package:joga_10/model/Liga.dart';
import 'package:joga_10/pages/liga_detalhe_page.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class CampeonatosPage extends StatefulWidget {
  const CampeonatosPage({super.key});

  @override
  State<CampeonatosPage> createState() => _CampeonatosPageState();
}

class _CampeonatosPageState extends State<CampeonatosPage> {
  final _repo = CampeonatoRepository();
  late Future<List<Liga>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarLigas();
  }

  void _recarregar() => setState(() => _futuro = _repo.listarLigas());

  Future<void> _novaLiga() async {
    final nome = TextEditingController();
    final cidade = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova liga'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome da liga'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cidade,
                decoration: const InputDecoration(labelText: 'Cidade'),
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
              child: const Text('Criar')),
        ],
      ),
    );
    if (ok == true && nome.text.trim().isNotEmpty) {
      await _repo.criarLiga(nome: nome.text, cidade: cidade.text);
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaLiga,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova liga'),
      ),
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Ligas',
            subtitulo: 'Campeonatos com times e classificação',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _recarregar(),
              child: FutureBuilder<List<Liga>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const LoadingView();
                  }
                  if (snap.hasError) {
                    return ListView(children: const [
                      SizedBox(height: 80),
                      EmptyState(
                          icone: Icons.cloud_off,
                          titulo: 'Erro ao carregar',
                          mensagem: 'Não foi possível conectar ao banco.'),
                    ]);
                  }
                  final ligas = snap.data ?? [];
                  if (ligas.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icone: Icons.emoji_events_outlined,
                        titulo: 'Nenhuma liga',
                        mensagem: 'Crie uma liga e adicione os times.',
                        acao: ElevatedButton(
                            onPressed: _novaLiga,
                            child: const Text('Criar liga')),
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: ligas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _LigaCard(
                      liga: ligas[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  LigaDetalhePage(liga: ligas[i])),
                        );
                        _recarregar();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigaCard extends StatelessWidget {
  final Liga liga;
  final VoidCallback onTap;
  const _LigaCard({required this.liga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(liga.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  '${liga.cidade ?? ''}${liga.cidade != null ? ' · ' : ''}${liga.totalTimes} time(s)',
                  style:
                      const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
