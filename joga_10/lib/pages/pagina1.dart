import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/pages/DetalhePartida.dart';
import 'package:joga_10/pages/partida.dart';
import 'package:joga_10/pages/partidas.dart';
import 'package:joga_10/pages/selecaoLocal.dart';
import 'package:joga_10/service/PartidaService.dart';

class Pagina1Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  Pagina1Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<Pagina1Page> createState() => _Pagina1PageState();
}

class _Pagina1PageState extends State<Pagina1Page> {
  List<Partida> historicoPartidas = []; // Lista para armazenar o histórico de partidas

  @override
  void initState() {
    super.initState();
    // Carregar o histórico de partidas ao iniciar a página
    carregarHistoricoPartidas();
  }

  Future<void> carregarHistoricoPartidas() async {
    try {
      PartidaService partidaService = PartidaService();
      List<Partida> historico = await partidaService.getPartidasAtivas(widget.userData['id_user'].toString(), "1");
      setState(() {
        historicoPartidas = historico;
      });
    } catch (e) {
      print("Erro ao carregar o histórico de partidas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
          color: Color.fromARGB(68, 56, 25, 139),
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SelecionaLocalPage(userData: widget.userData)));
                    },
                    child: Text("Criar Partida"),
                  ),
                  SizedBox(width: 16.0),
                ElevatedButton(
  onPressed: () async {
    PartidaService p = new PartidaService();
    List<Partida> partidas = await p.getPartidasAtivas(widget.userData['id_user'].toString(), "0");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartidasPage(
         
          userData: widget.userData, partidas: partidas,
        
        ),
      ),
    );
  },
  child: Text("Partidas"),
),
                ],
              ),
            ],
          ),
        ),
        Container(
          color: Color.fromARGB(68, 56, 25, 100),
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "Histórico de partidas",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: historicoPartidas.length,
                itemBuilder: (context, index) {
                  return PartidaItemWidget(
                    partida: historicoPartidas[index], userData: widget.userData,
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

class PartidaItemWidget extends StatelessWidget {
  final Partida partida;
  final Map<String, dynamic> userData;

  PartidaItemWidget({required this.partida, required this.userData});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      leading: Container(
        child: //Image.network(
          //'https://static.vecteezy.com/ti/vetor-gratis/p1/2871329-design-dees-de-campo-verde-de-futebol-e-futebol-gratis-vetor.jpg',
         // width: 70,
         // height: 70,
      //  ),
      Image.asset(
                          'lib/assets/img/futebol.png',
                           width: 100,
                           height: 200,
                        ), 
      ),
      title: Text(
        "Partida ${partida.id}",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        "Data da partida: ${partida.dataHora}",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetalhePartida(partida: partida, userData: userData,)),
        );
      },
    );
  }
}

