import 'package:flutter/material.dart';
import 'package:joga_10/pages/partida.dart';
import 'package:joga_10/pages/selecaoLocal.dart';

class Pagina1Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  Pagina1Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<Pagina1Page> createState() => _Pagina1PageState();
}

class _Pagina1PageState extends State<Pagina1Page> {
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
                      // ignore: prefer_const_constructors
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SelecionaLocalPage(userData: widget.userData,)));
                    },
                    child: Text("Criar Partida"),
                  ),
                  SizedBox(width: 16.0), // Adiciona espaço entre os botões
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PartidaPage(equipe1Members: [], equipe2Members: [], selectedLocation: '', selectedTime: '', selectedSport: '', estabelecimento: '', price: '',userData: widget.userData,)));
                    },
                    child: Text("Acompanhar partida"),
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
                "Historico de partidas",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Widget de lista de partidas existentes (semelhante a lista de restaurantes)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 5, // Número de itens na lista de partidas existentes
                itemBuilder: (context, index) {
                  // Crie um widget de item da lista aqui
                  return PartidaItemWidget(
                    partidaNumber: index,
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
  final int partidaNumber;

  PartidaItemWidget({required this.partidaNumber});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true, // Define como três linhas (alinhando a imagem à esquerda)
      leading: Container(
        width: 64.0,
        height: 64.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue, // Cor da imagem de exemplo
        ),
      ),
      title: Text(
        "Partida $partidaNumber",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        "Data da partida $partidaNumber",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          // Adicionar ação para "Entrar" na partida
        },
        child: Text("Visualizar"),
      ),
      onTap: () {
        // Adicionar ação ao toque no item, se necessário
      },
    );
  }
}

