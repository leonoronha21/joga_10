import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/repositories/quadra_repository.dart';
import 'package:joga_10/services/google_places_service.dart';
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
  final _places = GooglePlacesService();

  late Future<List<Quadras>> _quadras;
  late Future<Estabelecimentos> _detalhes;

  @override
  void initState() {
    super.initState();
    _quadras = _repo.listarPorEstabelecimento(widget.estab.id);
    _detalhes = _carregarDetalhes();
  }

  Future<Estabelecimentos> _carregarDetalhes() async {
    return await _places.buscarDetalhes(widget.estab) ?? widget.estab;
  }

  Future<void> _abrirUri(Uri uri) async {
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir este endereço.')),
      );
    }
  }

  Future<void> _abrirNoMapa(Estabelecimentos local) {
    final uri = local.googleMapsUrl == null
        ? Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '${local.latitude},${local.longitude}',
          })
        : Uri.parse(local.googleMapsUrl!);
    return _abrirUri(uri);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Estabelecimentos>(
      future: _detalhes,
      initialData: widget.estab,
      builder: (context, snap) {
        final local = snap.data ?? widget.estab;
        return Scaffold(
          appBar: AppBar(title: Text(local.nome)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CabecalhoLocal(
                local: local,
                carregando: snap.connectionState != ConnectionState.done,
              ),
              const SizedBox(height: 14),
              _AcoesLocal(
                local: local,
                onMapa: () => _abrirNoMapa(local),
                onTelefone: local.telefone == null
                    ? null
                    : () => _abrirUri(Uri(scheme: 'tel', path: local.telefone)),
                onSite: local.siteUrl == null
                    ? null
                    : () => _abrirUri(Uri.parse(local.siteUrl!)),
              ),
              if (local.horariosFuncionamento.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Horários',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: local.horariosFuncionamento
                        .map(
                          (horario) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 17,
                                  color: AppColors.inkMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(horario)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                local.origemGooglePlaces
                    ? 'Quadras no Joga10'
                    : 'Quadras disponíveis',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Quadras>>(
                future: _quadras,
                builder: (context, quadrasSnap) {
                  if (quadrasSnap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: LoadingView(),
                    );
                  }
                  final quadras = quadrasSnap.data ?? [];
                  if (quadras.isEmpty) {
                    return AppCard(
                      child: Text(
                        local.origemGooglePlaces
                            ? 'Este estabelecimento foi encontrado no Google. '
                                'As quadras e reservas ainda não foram integradas ao Joga10.'
                            : 'Nenhuma quadra cadastrada.',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    );
                  }
                  return Column(
                    children: quadras
                        .map(
                          (quadra) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuadraCard(quadra: quadra),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CabecalhoLocal extends StatelessWidget {
  const _CabecalhoLocal({required this.local, required this.carregando});

  final Estabelecimentos local;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.stadium, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (local.tipoPrincipal != null)
                      Text(
                        local.tipoPrincipal!,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                  ],
                ),
              ),
              if (carregando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (local.enderecoResumo.isNotEmpty)
            _linha(Icons.location_on_outlined, local.enderecoResumo),
          if (local.telefone != null && local.telefone!.isNotEmpty)
            _linha(Icons.phone_outlined, local.telefone!),
          if (local.horaAbertura != null && local.horaFechamento != null)
            _linha(
              Icons.schedule,
              '${local.horaAbertura} às ${local.horaFechamento}',
            ),
          if (local.avaliacao != null)
            _linha(
              Icons.star,
              '${local.avaliacao!.toStringAsFixed(1)}'
              '${local.totalAvaliacoes == null ? '' : ' (${local.totalAvaliacoes} avaliações)'}',
              iconColor: Colors.amber,
            ),
        ],
      ),
    );
  }

  Widget _linha(IconData icon, String texto, {Color? iconColor}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor ?? AppColors.inkMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}

class _AcoesLocal extends StatelessWidget {
  const _AcoesLocal({
    required this.local,
    required this.onMapa,
    required this.onTelefone,
    required this.onSite,
  });

  final Estabelecimentos local;
  final VoidCallback onMapa;
  final VoidCallback? onTelefone;
  final VoidCallback? onSite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: local.temLocalizacao ? onMapa : null,
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Como chegar'),
          ),
        ),
        if (onTelefone != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Ligar',
            onPressed: onTelefone,
            icon: const Icon(Icons.phone_outlined),
          ),
        ],
        if (onSite != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Abrir site',
            onPressed: onSite,
            icon: const Icon(Icons.language),
          ),
        ],
      ],
    );
  }
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
                Text(
                  quadra.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  quadra.tipoQuadra,
                  style:
                      const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            formatarMoeda(quadra.preco),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
