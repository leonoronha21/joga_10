import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/pages/local_detalhe_page.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/services/google_places_service.dart';
import 'package:joga_10/services/locais_esportivos_catalogo.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class MapaLocaisPage extends StatefulWidget {
  const MapaLocaisPage({super.key});

  @override
  State<MapaLocaisPage> createState() => _MapaLocaisPageState();
}

class _MapaLocaisPageState extends State<MapaLocaisPage> {
  static const _centroInicial = LatLng(-29.98, -51.18);

  final _repo = EstabelecimentoRepository();
  final _places = GooglePlacesService();
  final _busca = TextEditingController();
  final _focoBusca = FocusNode();

  GoogleMapController? _mapController;
  Timer? _debounce;
  List<Estabelecimentos> _locais = [];
  List<Estabelecimentos> _resultadosRemotos = [];
  LatLng _centroAtual = _centroInicial;
  String _termo = '';
  bool _carregando = true;
  bool _buscandoPlaces = false;
  bool _mapaExpandido = false;
  bool _mapaMovido = false;
  int _versaoBusca = 0;

  List<Estabelecimentos> get _encontrados {
    if (_termo.trim().isEmpty) return _locais;
    return LocaisEsportivosCatalogo.mesclarSomente([
      ...LocaisEsportivosCatalogo.filtrar(_locais, _termo),
      ..._resultadosRemotos,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _busca.addListener(_aoBuscar);
    _carregarIniciais();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busca
      ..removeListener(_aoBuscar)
      ..dispose();
    _focoBusca.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _carregarIniciais() async {
    final cadastrados = await _repo.listarComLocalizacao();
    final encontrados =
        await _places.buscarProximos(centro: _centroInicial, raioMetros: 50000);
    if (!mounted) return;
    setState(() {
      _locais = LocaisEsportivosCatalogo.mesclarSomente([
        ...cadastrados,
        ...encontrados,
      ]);
      _carregando = false;
    });
  }

  void _aoBuscar() {
    final termo = _busca.text;
    if (_termo == termo) return;
    _debounce?.cancel();
    setState(() {
      _termo = termo;
      if (termo.trim().isEmpty) _resultadosRemotos = [];
    });
    if (termo.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 650), () {
      _buscarTexto(termo);
    });
  }

  Future<void> _buscarTexto(String termo) async {
    final versao = ++_versaoBusca;
    setState(() => _buscandoPlaces = true);
    final resultados = await _places.buscarTexto(
      termo: termo,
      centro: _centroAtual,
      raioMetros: 50000,
    );
    if (!mounted || versao != _versaoBusca || _busca.text != termo) return;
    setState(() {
      _resultadosRemotos = resultados;
      _buscandoPlaces = false;
    });
  }

  Future<void> _buscarNestaArea() async {
    _fecharTeclado();
    setState(() => _buscandoPlaces = true);
    final resultados = await _places.buscarProximos(
      centro: _centroAtual,
      raioMetros: 30000,
    );
    if (!mounted) return;
    setState(() {
      _locais = LocaisEsportivosCatalogo.mesclarSomente([
        ..._locais,
        ...resultados,
      ]);
      _resultadosRemotos = _termo.trim().isEmpty ? [] : resultados;
      _buscandoPlaces = false;
      _mapaMovido = false;
    });
  }

  Future<void> _selecionarLocal(Estabelecimentos local) async {
    _fecharTeclado();
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(local.latitude!, local.longitude!),
          zoom: 15,
        ),
      ),
    );
    if (mounted) _abrirLocal(local);
  }

  void _fecharTeclado() {
    _focoBusca.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _abrirLocal(Estabelecimentos local) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                local.nome,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (local.tipoPrincipal != null) ...[
                const SizedBox(height: 4),
                Text(
                  local.tipoPrincipal!,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
              if (local.enderecoResumo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  local.enderecoResumo,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ],
              if (local.avaliacao != null) ...[
                const SizedBox(height: 8),
                _AvaliacaoLocal(local: local),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocalDetalhePage(estab: local),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Abrir página do estabelecimento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _mapaExpandido
          ? null
          : AppBar(title: const Text('Locais esportivos')),
      body: _carregando
          ? const LoadingView()
          : _locais.isEmpty
              ? const EmptyState(
                  icone: Icons.map_outlined,
                  titulo: 'Nenhum local esportivo encontrado',
                  mensagem: 'Mova o mapa e toque em buscar nesta área.',
                )
              : _MapaComBusca(
                  locais: _locais,
                  encontrados: _encontrados,
                  busca: _busca,
                  focoBusca: _focoBusca,
                  termo: _termo,
                  mapaExpandido: _mapaExpandido,
                  mapaMovido: _mapaMovido,
                  buscandoPlaces: _buscandoPlaces,
                  onMapCreated: (controller) => _mapController = controller,
                  onCameraMove: (position) => _centroAtual = position.target,
                  onCameraIdle: () {
                    if (mounted) setState(() => _mapaMovido = true);
                  },
                  onSelecionar: _selecionarLocal,
                  onBuscarNestaArea: _buscarNestaArea,
                  onLimparBusca: _busca.clear,
                  onAlternarExpansao: () {
                    _fecharTeclado();
                    setState(() => _mapaExpandido = !_mapaExpandido);
                  },
                ),
    );
  }
}

class _MapaComBusca extends StatelessWidget {
  const _MapaComBusca({
    required this.locais,
    required this.encontrados,
    required this.busca,
    required this.focoBusca,
    required this.termo,
    required this.mapaExpandido,
    required this.mapaMovido,
    required this.buscandoPlaces,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onSelecionar,
    required this.onBuscarNestaArea,
    required this.onLimparBusca,
    required this.onAlternarExpansao,
  });

  final List<Estabelecimentos> locais;
  final List<Estabelecimentos> encontrados;
  final TextEditingController busca;
  final FocusNode focoBusca;
  final String termo;
  final bool mapaExpandido;
  final bool mapaMovido;
  final bool buscandoPlaces;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<CameraPosition> onCameraMove;
  final VoidCallback onCameraIdle;
  final ValueChanged<Estabelecimentos> onSelecionar;
  final VoidCallback onBuscarNestaArea;
  final VoidCallback onLimparBusca;
  final VoidCallback onAlternarExpansao;

  @override
  Widget build(BuildContext context) {
    final centro = LatLng(
      locais.map((e) => e.latitude!).reduce((a, b) => a + b) / locais.length,
      locais.map((e) => e.longitude!).reduce((a, b) => a + b) / locais.length,
    );
    final marcadoresVisiveis = termo.trim().isEmpty ? locais : encontrados;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: centro, zoom: 10.2),
          mapType: MapType.normal,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: onMapCreated,
          onCameraMove: onCameraMove,
          onCameraIdle: onCameraIdle,
          markers: marcadoresVisiveis
              .map(
                (local) => Marker(
                  markerId: MarkerId(
                    local.placeId ?? local.id.toString(),
                  ),
                  position: LatLng(local.latitude!, local.longitude!),
                  infoWindow: InfoWindow(
                    title: local.nome,
                    snippet: local.enderecoResumo,
                  ),
                  onTap: () => onSelecionar(local),
                ),
              )
              .toSet(),
        ),
        Positioned(
          top: mapaExpandido ? MediaQuery.paddingOf(context).top + 12 : 12,
          left: 12,
          right: 64,
          child: _PainelBusca(
            busca: busca,
            focoBusca: focoBusca,
            encontrados: encontrados,
            termo: termo,
            buscandoPlaces: buscandoPlaces,
            onSelecionar: onSelecionar,
            onLimpar: onLimparBusca,
          ),
        ),
        Positioned(
          top: mapaExpandido ? MediaQuery.paddingOf(context).top + 12 : 12,
          right: 12,
          child: Material(
            color: AppColors.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: IconButton(
              tooltip: mapaExpandido ? 'Sair da tela cheia' : 'Expandir mapa',
              onPressed: onAlternarExpansao,
              icon: Icon(
                mapaExpandido ? Icons.fullscreen_exit : Icons.fullscreen,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (mapaMovido && termo.trim().isEmpty)
          Positioned(
            top: mapaExpandido ? MediaQuery.paddingOf(context).top + 88 : 88,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: buscandoPlaces ? null : onBuscarNestaArea,
                icon: buscandoPlaces
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Buscar nesta área'),
              ),
            ),
          ),
        Positioned(
          left: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
          child: Material(
            color: AppColors.surface,
            elevation: 3,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                termo.trim().isEmpty
                    ? '${locais.length} locais esportivos'
                    : '${encontrados.length} locais encontrados',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PainelBusca extends StatelessWidget {
  const _PainelBusca({
    required this.busca,
    required this.focoBusca,
    required this.encontrados,
    required this.termo,
    required this.buscandoPlaces,
    required this.onSelecionar,
    required this.onLimpar,
  });

  final TextEditingController busca;
  final FocusNode focoBusca;
  final List<Estabelecimentos> encontrados;
  final String termo;
  final bool buscandoPlaces;
  final ValueChanged<Estabelecimentos> onSelecionar;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    final exibirResultados = termo.trim().isNotEmpty;
    final sugestoes = encontrados.take(6).toList();

    return Material(
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: busca,
            focusNode: focoBusca,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (encontrados.isNotEmpty) onSelecionar(encontrados.first);
            },
            decoration: InputDecoration(
              hintText: 'Buscar local esportivo ou região',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: buscandoPlaces
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : termo.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: onLimpar,
                          icon: const Icon(Icons.close),
                        ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          if (exibirResultados) const Divider(height: 1),
          if (exibirResultados && sugestoes.isEmpty && !buscandoPlaces)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_off_outlined, color: AppColors.inkMuted),
                  SizedBox(width: 10),
                  Expanded(child: Text('Nenhum local esportivo encontrado.')),
                ],
              ),
            ),
          if (exibirResultados)
            ...sugestoes.map(
              (local) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.sports_basketball_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  local.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  local.enderecoResumo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: local.avaliacao == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(local.avaliacao!.toStringAsFixed(1)),
                        ],
                      ),
                onTap: () => onSelecionar(local),
              ),
            ),
          if (exibirResultados &&
              sugestoes.any((local) => local.origemGooglePlaces))
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Resultados esportivos do Google',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvaliacaoLocal extends StatelessWidget {
  const _AvaliacaoLocal({required this.local});

  final Estabelecimentos local;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          local.avaliacao!.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (local.totalAvaliacoes != null)
          Text(
            ' (${local.totalAvaliacoes} avaliações)',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
      ],
    );
  }
}
