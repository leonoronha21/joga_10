import 'package:flutter/material.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/repositories/quadra_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class LocalDetalhePage extends StatefulWidget {
  final Estabelecimentos estab;
  const LocalDetalhePage({super.key, required this.estab});

  @override
  State<LocalDetalhePage> createState() => _LocalDetalhePageState();
}

class _LocalDetalhePageState extends State<LocalDetalhePage> {
  final _repo = QuadraRepository();
  late Future<List<Quadras>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarPorEstabelecimento(widget.estab.id);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.estab;
    return Scaffold(
      appBar: AppBar(title: Text(e.nome)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nome,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (e.enderecoResumo.isNotEmpty)
                  _linha(Icons.location_on_outlined, e.enderecoResumo),
                if (e.telefone != null && e.telefone!.isNotEmpty)
                  _linha(Icons.phone_outlined, e.telefone!),
                if (e.horaAbertura != null && e.horaFechamento != null)
                  _linha(Icons.schedule,
                      '${e.horaAbertura} às ${e.horaFechamento}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quadras',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          FutureBuilder<List<Quadras>>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingView(),
                );
              }
              final quadras = snap.data ?? [];
              if (quadras.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Nenhuma quadra cadastrada.',
                      style: TextStyle(color: AppColors.inkMuted)),
                );
              }
              return Column(
                children: quadras
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuadraCard(quadra: q),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _linha(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.inkMuted),
            const SizedBox(width: 8),
            Expanded(
                child: Text(texto,
                    style: const TextStyle(color: AppColors.ink))),
          ],
        ),
      );
}

class _QuadraCard extends StatelessWidget {
  final Quadras quadra;
  const _QuadraCard({required this.quadra});

  @override
  Widget build(BuildContext context) {
    final esporte = Esporte.porTipo(quadra.tipoQuadra);
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: esporte.cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(esporte.icone, color: esporte.cor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quadra.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(quadra.tipoQuadra,
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 13)),
              ],
            ),
          ),
          Text(
            formatarMoeda(quadra.preco),
            style: const TextStyle(
                color: AppColors.primaryDark, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
