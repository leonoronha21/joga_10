import 'package:flutter/material.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/pages/local_detalhe_page.dart';
import 'package:joga_10/pages/mapa_locais_page.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class LocaisPage extends StatefulWidget {
  const LocaisPage({super.key});

  @override
  State<LocaisPage> createState() => _LocaisPageState();
}

class _LocaisPageState extends State<LocaisPage> {
  final _repo = EstabelecimentoRepository();
  late Future<List<Estabelecimentos>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarTodos();
  }

  void _recarregar() => setState(() {
        _futuro = _repo.listarTodos();
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientHeader(
          titulo: 'Locais',
          subtitulo: 'Encontre quadras perto de você',
          trailing: IconButton.filledTonal(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapaLocaisPage()),
            ),
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
            tooltip: 'Ver no mapa',
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _recarregar(),
            child: FutureBuilder<List<Estabelecimentos>>(
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
                      mensagem: 'Não foi possível conectar ao banco.',
                    ),
                  ]);
                }
                final locais = snap.data ?? [];
                if (locais.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      icone: Icons.stadium_outlined,
                      titulo: 'Nenhum local cadastrado',
                    ),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: locais.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _LocalCard(
                    estab: locais[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocalDetalhePage(estab: locais[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalCard extends StatelessWidget {
  final Estabelecimentos estab;
  final VoidCallback onTap;
  const _LocalCard({required this.estab, required this.onTap});

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
            child: const Icon(Icons.stadium, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estab.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                if (estab.enderecoResumo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(estab.enderecoResumo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 13)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
