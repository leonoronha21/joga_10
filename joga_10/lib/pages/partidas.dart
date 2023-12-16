import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/pages/DetalhePartida.dart';

class PartidasPage extends StatelessWidget {
  final List<Partida> partidas; 
final Map<String, dynamic> userData;

  PartidasPage({required this.partidas, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Minhas Partidas"),
      ),
      body: ListView.builder(
        itemCount: partidas.length,
        itemBuilder: (context, index) {
          return Card(
            color: Color.fromARGB(68, 56, 25, 139),
            child: ListTile(
              title: Text(
                "ID da Partida: ${partidas[index].id}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                "Data: ${partidas[index].dataHora}",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
               
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalhePartida(partida: partidas[index], userData: userData,),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
