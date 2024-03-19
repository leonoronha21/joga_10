import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:joga_10/ControllerMaps/MapsController.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/service/QuadraService.dart';
import 'package:collection/collection.dart';

final appKey = GlobalKey();

class Pagina2Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  Pagina2Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<Pagina2Page> createState() => _Pagina2PageState();
}

class _Pagina2PageState extends State<Pagina2Page> {
  String selectedSport = 'Futebol';
  QuadraService quadraService = QuadraService();
  List<Quadras> quadras = [];

  Map<String, String> esporteIcones = {
    'Futebol': 'lib/assets/img/futebol.png',
    'Tênis': 'lib/assets/img/quadra-de-tenis.png',
    'Basquete': 'lib/assets/img/quadra-de-basquete.png',
    'Futevôlei': 'lib/assets/img/voleibol.png',
    'Vôlei': 'lib/assets/img/voleibol.png',
  };

  Map<String, String> quadraIcones = {}; // Mapeamento para armazenar ícones por tipo de quadra

  @override
  void initState() {
    super.initState();
    getAllQuadras(); 
  }

  Future<void> getAllQuadras() async {
    try {
      final List<Quadras> quadras = await quadraService.getAllQuadras() as List<Quadras>;

      if (quadras != null) {
        // Preencher o mapeamento de ícones por tipo de quadra
        quadraIcones = Map.fromIterable(
          quadras,
          key: (quadra) => quadra.tipoQuadra,
          value: (quadra) => setIconePorTipoQuadra(quadra.tipoQuadra),
        );

        setState(() {
          this.quadras = quadras; 
        });
      } else {
        print("A resposta do servidor não é uma lista de objetos Quadra.");
      }
    } catch (e) {
      print("Erro ao carregar as quadras: $e");
    }
  }

  String setIconePorTipoQuadra(String tipoQuadra) {
    switch (tipoQuadra) {
      case 'Futebol':
        return 'lib/assets/img/futebol.png';
      case 'Tênis':
        return 'lib/assets/img/quadra-de-tenis.png';
      case 'Basquete':
        return 'lib/assets/img/quadra-de-basquete.png';
      case 'Futevôlei':
        return 'lib/assets/img/voleibol.png';
      case 'Vôlei':
        return 'lib/assets/img/voleibol.png';
      default:
        return '';
    }
  }

   @override
  Widget build(BuildContext context) 
  {
    return Column(
    
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
         Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar local',
                  border: OutlineInputBorder(
                    
                  ),
                  filled: true,
                  fillColor: Colors.white, // Cor de fundo branca
                  
                ),
              ),
            ),
            SizedBox(width: 8), // Espaçamento entre o TextField e o DropdownButton
           
          ],
        ),
       
        Expanded(
          child: ChangeNotifierProvider<MapsController>(
            create: (context) => MapsController(),
            
            child: Builder(
              
              builder: (context) {
                
                final local = context.watch<MapsController>();
                print('Latitude: ${local.latitude}, Longitude: ${local.longitude}');
                
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(local.latitude, local.longitude),
                    //target: LatLng(-29.9147201, -51.1478324),
                    zoom: 15,
                  ),
                  zoomControlsEnabled: true,
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: local.onMapCreated,
                  markers: local.markers,
                 
                );
              },
            ),
          ),
        ),
       
      ],
    );
  }
}