import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/pages/local_detalhe_page.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/services/locais_esportivos_catalogo.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class MapaLocaisPage extends StatefulWidget {
  const MapaLocaisPage({super.key});

  @override
  State<MapaLocaisPage> createState() => _MapaLocaisPageState();
}

class _MapaLocaisPageState extends State<MapaLocaisPage> {
  final _repo = EstabelecimentoRepository();
  final _busca = TextEditingController();
  final _focoBusca = FocusNode();

  late Future<List<Estabelecimentos>> _futuro;
  GoogleMapController? _mapController;
  String _termo = '';
  bool _mapaExpandido = false;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarComLocalizacao();
    _busca.addListener(_aoBuscar);
  }

  @override
  void dispose() {
    _busca
      ..removeListener(_aoBuscar)
      ..dispose();
    _focoBusca.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _aoBuscar() {
    if (_termo == _busca.text) return;
    setState(() => _termo = _busca.text);
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

  void _abrirLocal(Estabelecimentos e) {
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
                e.nome,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (e.enderecoResumo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  e.enderecoResumo,
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
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
                        builder: (_) => LocalDetalhePage(estab: e),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Ver quadras'),
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
          : AppBar(title: const Text('Quadras na região')),
      body: FutureBuilder<List<Estabelecimentos>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final locais = snap.data ?? [];
          if (locais.isEmpty) {
            return const EmptyState(
              icone: Icons.map_outlined,
              titulo: 'Nenhum local com localização',
              mensagem: 'Os estabelecimentos ainda não têm posição no mapa.',
            );
          }
          return _MapaComBusca(
            locais: locais,
            encontrados: LocaisEsportivosCatalogo.filtrar(locais, _termo),
            busca: _busca,
            focoBusca: _focoBusca,
            termo: _termo,
            mapaExpandido: _mapaExpandido,
            onMapCreated: (controller) => _mapController = controller,
            onSelecionar: _selecionarLocal,
            onLimparBusca: _busca.clear,
            onAlternarExpansao: () {
              _fecharTeclado();
              setState(() => _mapaExpandido = !_mapaExpandido);
            },
          );
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
    required this.onMapCreated,
    required this.onSelecionar,
    required this.onLimparBusca,
    required this.onAlternarExpansao,
  });

  final List<Estabelecimentos> locais;
  final List<Estabelecimentos> encontrados;
  final TextEditingController busca;
  final FocusNode focoBusca;
  final String termo;
  final bool mapaExpandido;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<Estabelecimentos> onSelecionar;
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
          markers: marcadoresVisiveis
              .map(
                (e) => Marker(
                  markerId: MarkerId(e.id.toString()),
                  position: LatLng(e.latitude!, e.longitude!),
                  infoWindow: InfoWindow(
                    title: e.nome,
                    snippet: e.enderecoResumo,
                  ),
                  onTap: () => onSelecionar(e),
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
                    ? '${locais.length} locais na região'
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
    required this.onSelecionar,
    required this.onLimpar,
  });

  final TextEditingController busca;
  final FocusNode focoBusca;
  final List<Estabelecimentos> encontrados;
  final String termo;
  final ValueChanged<Estabelecimentos> onSelecionar;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    final exibirResultados = termo.trim().isNotEmpty;
    final sugestoes = encontrados.take(5).toList();

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
              hintText: 'Buscar quadra, bairro ou cidade',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: termo.isEmpty
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
          if (exibirResultados && sugestoes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_off_outlined, color: AppColors.inkMuted),
                  SizedBox(width: 10),
                  Expanded(child: Text('Nenhum local encontrado na região.')),
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
                  [local.bairro, local.cidade]
                      .whereType<String>()
                      .where((item) => item.isNotEmpty)
                      .join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSelecionar(local),
              ),
            ),
        ],
      ),
    );
  }
}
