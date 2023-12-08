import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/pages/DetalhePartida.dart';
import 'package:joga_10/service/PartidaService.dart';

class Pagina2Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  Pagina2Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<Pagina2Page> createState() => _Pagina2PageState();
}

class _Pagina2PageState extends State<Pagina2Page> {
  String selectedSport = 'Futebol';
  PartidaService partidaService = PartidaService();
  List<Partida> partidas = [];

  Map<String, String> esporteIcones = {
    'Futebol': 'lib/assets/img/futebol.png',
    'Tênis': 'lib/assets/img/quadra-de-tenis.png',
    'Basquete': 'lib/assets/img/quadra-de-basquete.png',
    'Futevôlei': 'lib/assets/img/voleibol.png',
    'Vôlei': 'lib/assets/img/voleibol.png',
  };

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16.0),
          child: Image.asset(
            esporteIcones[selectedSport] ?? '', // Usa o ícone correspondente ao esporte selecionado
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
                  return ListTile(
                    isThreeLine: true,
                    leading: Container(
                      child: Image.asset(
                        esporteIcones[selectedSport] ?? '', // Usa o ícone correspondente ao esporte selecionado
                        width: 100,
                        height: 100,
                      ),
                    ),
                    title: Text(
                      "Partida ${partida.id}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "Descrição da partida ${partida.id}",
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
                          builder: (context) => DetalhePartida(partida: partida),
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
}
