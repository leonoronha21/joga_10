import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/pages/local_detalhe_page.dart';
import 'package:joga_10/pages/mapa_locais_page.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/services/google_places_service.dart';
import 'package:joga_10/services/locais_esportivos_catalogo.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class LocaisPage extends StatefulWidget {
  const LocaisPage({super.key});

  @override
  State<LocaisPage> createState() => _LocaisPageState();
}

class _LocaisPageState extends State<LocaisPage> {
  static const _centroRegiao = LatLng(-29.98, -51.18);

  final _repo = EstabelecimentoRepository();
  final _places = GooglePlacesService();
  final _busca = TextEditingController();

  Timer? _debounce;
  List<Estabelecimentos> _quadras = [];
  List<Estabelecimentos> _resultadosRemotos = [];
  bool _carregando = true;
  bool _buscando = false;
  bool _erro = false;
  String _termo = '';
  int _versaoBusca = 0;

  List<Estabelecimentos> get _resultados {
    if (_termo.trim().isEmpty) return _quadras;
    return LocaisEsportivosCatalogo.mesclarSomente([
      ...LocaisEsportivosCatalogo.filtrar(_quadras, _termo),
      ..._resultadosRemotos,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _busca.addListener(_aoBuscar);
    _carregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busca
      ..removeListener(_aoBuscar)
      ..dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final cadastrados = await _repo.listarComLocalizacao();
      if (!mounted) return;
      setState(() {
        _quadras = LocaisEsportivosCatalogo.mesclarSomente(cadastrados);
        _carregando = false;
      });
      unawaited(_carregarRemotosIniciais());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  Future<void> _carregarRemotosIniciais() async {
    setState(() => _buscando = true);
    final encontrados = await _places.buscarQuadrasRegiao(
      centro: _centroRegiao,
      raioMetros: 50000,
    );
    if (!mounted) return;
    if (_termo.trim().isNotEmpty) {
      setState(() => _buscando = false);
      return;
    }
    setState(() {
      _quadras = LocaisEsportivosCatalogo.mesclarSomente([
        ..._quadras,
        ...encontrados,
      ]);
      _buscando = false;
    });
  }

  void _aoBuscar() {
    final termo = _busca.text;
    if (_termo == termo) return;
    _debounce?.cancel();
    setState(() {
      _termo = termo;
      if (termo.trim().isEmpty) {
        _versaoBusca++;
        _resultadosRemotos = [];
        _buscando = false;
      }
    });
    if (termo.trim().length < 2) return;
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _buscarRemoto(termo),
    );
  }

  Future<void> _buscarRemoto(String termo) async {
    final versao = ++_versaoBusca;
    setState(() => _buscando = true);
    final encontrados = await _places.buscarTextoEsportivo(
      termo: termo,
      centro: _centroRegiao,
      raioMetros: 50000,
    );
    if (!mounted || versao != _versaoBusca || _busca.text != termo) return;
    setState(() {
      _resultadosRemotos = encontrados;
      _buscando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientHeader(
          titulo: 'Quadras',
          subtitulo: 'Encontre quadras em Porto Alegre e região',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _busca,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar quadra, bairro ou cidade',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _termo.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _busca.clear,
                          icon: const Icon(Icons.close),
                          tooltip: 'Limpar busca',
                        ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_resultados.length} quadras e complexos encontrados',
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _carregar,
            child: _conteudo(),
          ),
        ),
      ],
    );
  }

  Widget _conteudo() {
    if (_carregando) return const LoadingView();
    if (_erro && _quadras.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icone: Icons.cloud_off,
            titulo: 'Erro ao carregar as quadras',
            mensagem: 'Puxe para baixo para tentar novamente.',
          ),
        ],
      );
    }
    final locais = _resultados;
    if (locais.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icone: Icons.search_off,
            titulo: 'Nenhuma quadra encontrada',
            mensagem: 'Tente buscar por outro nome, bairro ou cidade.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            child: const Icon(Icons.sports_soccer, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estab.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (estab.enderecoResumo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    estab.enderecoResumo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (estab.avaliacao != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        estab.avaliacao!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (estab.origemGooglePlaces)
                        const Text(
                          ' · Google',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
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
