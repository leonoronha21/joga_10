import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';

class DetalhePartida extends StatelessWidget {
  final Partida partida;

  DetalhePartida({required this.partida});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
         backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Detalhes da Partida"),
      ),
      body: Container(
         color: Color.fromARGB(68, 56, 25, 139),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID da Partida: ${partida.id}",style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),),
            Text("ID do Estabelecimento: ${partida.idEstabelecimento}",style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),),
            Text("ID da Quadra: ${partida.idQuadra}",style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),),
          
          ],
        ),
      ),
    );
  }
}
