import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:joga_10/pages/DetalhePartida.dart';
import 'package:joga_10/service/PartidaService.dart';
import 'package:joga_10/service/QuadraService.dart';
import 'package:collection/collection.dart';

class Pagina2Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  Pagina2Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<Pagina2Page> createState() => _Pagina2PageState();
}

class _Pagina2PageState extends State<Pagina2Page> {
  String selectedSport = 'Futebol';
  PartidaService partidaService = PartidaService();
  QuadraService quadraService = QuadraService();
  List<Partida> partidas = [];
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
    loadPartidas();
  }

  Future<void> loadPartidas() async {
    try {
      final List<Partida> partidas = await partidaService.getAllPartidas() as List<Partida>;

      if (partidas != null) {
        setState(() {
          this.partidas = partidas;
        });
      } else {
        print("A resposta do servidor não é uma lista de objetos Partida.");
      }
    } catch (e) {
      print("Erro ao carregar as partidas: $e");
    }
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
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16.0),
          child: Image.asset(
            esporteIcones[selectedSport] ?? '',
            width: 200,
            height: 200,
          ),
        ),
        SizedBox(height: 16.0),
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButton<String>(
                value: selectedSport,
                items: <String>['Futebol', 'Tênis', 'Basquete', 'Futevôlei', 'Vôlei']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: value == selectedSport ? Colors.white : Colors.white,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSport = newValue!;
                  });
                },
                dropdownColor: Color.fromARGB(255, 0, 10, 80),
              ),
              SizedBox(height: 16.0),
              Text(
                "Partidas Possíveis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: partidas.length,
                itemBuilder: (context, index) {
                  final partida = partidas[index];
                  String tipoQuadra = getTipoQuadraForPartida(partida, quadras);
                  String iconeQuadra = quadraIcones[tipoQuadra] ?? '';

                  return ListTile(
                    isThreeLine: true,
                    title: Text(
                      "Partida ${partida.id}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "Descrição da partida ${partida.idQuadra}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhePartida(partida: partida, userData: widget.userData),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String getTipoQuadraForPartida(Partida partida, List<Quadras> quadras) {
    try {
      var idQuadra = partida.idQuadra;
      //COLLECTION
      var quadraCorrespondente = quadras.firstWhereOrNull((quadra) => quadra.id == idQuadra);

      if (quadraCorrespondente != null) {
        var tipoQuadra = quadraCorrespondente.tipoQuadra;
        return tipoQuadra;
      } else {
        print("Quadra não encontrada para o id ${idQuadra} da partida ${partida.id}");
        return '';
      }
    } catch (e) {
      print("Erro ao obter o tipo de quadra para a partida ${partida.id}: $e");
      return '';
    }
  }
}
