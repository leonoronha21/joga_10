import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/pages/local_detalhe_page.dart';
import 'package:joga_10/repositories/estabelecimento_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class MapaLocaisPage extends StatefulWidget {
  const MapaLocaisPage({super.key});

  @override
  State<MapaLocaisPage> createState() => _MapaLocaisPageState();
}

class _MapaLocaisPageState extends State<MapaLocaisPage> {
  final _repo = EstabelecimentoRepository();
  late Future<List<Estabelecimentos>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarComLocalizacao();
  }

  void _abrirLocal(Estabelecimentos e) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.nome,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            if (e.enderecoResumo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(e.enderecoResumo,
                  style: const TextStyle(color: AppColors.inkMuted)),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LocalDetalhePage(estab: e)),
                );
              },
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Ver quadras'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locais no mapa')),
      body: FutureBuilder<List<Estabelecimentos>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final locais = (snap.data ?? [])
              .where((e) => e.temLocalizacao)
              .toList();
          if (locais.isEmpty) {
            return const EmptyState(
              icone: Icons.map_outlined,
              titulo: 'Nenhum local com localização',
              mensagem: 'Os estabelecimentos ainda não têm posição no mapa.',
            );
          }
          // centro = média das coordenadas
          final centro = LatLng(
            locais.map((e) => e.latitude!).reduce((a, b) => a + b) /
                locais.length,
            locais.map((e) => e.longitude!).reduce((a, b) => a + b) /
                locais.length,
          );
          return FlutterMap(
            options: MapOptions(initialCenter: centro, initialZoom: 11.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.joga10.app',
              ),
              MarkerLayer(
                markers: locais
                    .map(
                      (e) => Marker(
                        point: LatLng(e.latitude!, e.longitude!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _abrirLocal(e),
                          child: const Icon(Icons.location_on,
                              color: AppColors.primary, size: 44),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
