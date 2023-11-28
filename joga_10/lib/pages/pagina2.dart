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
  PartidaService partidaService = PartidaService(); // Crie uma instância do serviço

  List<Partida> partidas = []; // Lista para armazenar as partidas

  @override
  void initState() {
    super.initState();
    loadPartidas(); // Carregue as partidas quando a tela for iniciada
  }

 Future<void> loadPartidas() async {
  try {
    final List<Partida> partidas = await partidaService.getAllPartidas()as List<Partida>; 
    if (partidas != null) {
      setState(() {
        this.partidas = partidas;
      });
    } else {
      // Lide com o caso em que a resposta do servidor não é uma lista de objetos Partida
      print("A resposta do servidor não é uma lista de objetos Partida.");
    }
  } catch (e) {
    // Lidar com erros aqui, por exemplo, exibir uma mensagem de erro
    print("Erro ao carregar as partidas: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
          // ... (código anterior)
        ),
        SizedBox(height: 16.0),
        Container(
          // ... (código anterior)
        ),
        SizedBox(height: 16.0),
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
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
        width: 64.0,
        height: 64.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
      ),
      title: Text("Partida ${partida.id}",style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),), // Use o campo correto da classe Partida
      subtitle: Text("Descrição da partida ${partida.id}",style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),), // Use o campo correto da classe Partida
      trailing: ElevatedButton(
        onPressed: () {
                      Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalhePartida(partida: partida),
                    ),
                  );
        },
        child: Text("Entrar"),
                    ),
                    onTap: () {
                      
                      
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
