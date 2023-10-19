import 'package:flutter/material.dart';

class PartidaItemWidget extends StatelessWidget {
  final int partidaNumber;

  PartidaItemWidget({required this.partidaNumber});

  @override
  Widget build(BuildContext context) {
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
      title: Text(
        "Partida $partidaNumber",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        "Descrição da partida $partidaNumber",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          // Adicionar ação para "Entrar" na partida
        },
        child: Text("Entrar"),
      ),
      onTap: () {
        // Adicionar ação ao toque no item, se necessário
      },
    );
  }
}

class Pagina2Page extends StatefulWidget {
  const Pagina2Page({Key? key}) : super(key: key);

  @override
  State<Pagina2Page> createState() => _Pagina2PageState();
}

class _Pagina2PageState extends State<Pagina2Page> {
  String selectedSport = 'Futebol';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          child: Text(
            "Buscar partida",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16.0),
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "Qual esporte?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.0),
              DropdownButton<String>(
                value: selectedSport,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSport = newValue!;
                  });
                },
                items: <String>[
                  'Futebol',
                  'Vôlei',
                  'Basquete',
                  'Futevôlei',
                  'Tênis',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: selectedSport == value ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
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
                itemCount: 5, // Número de partidas possíveis
                itemBuilder: (context, index) {
                  return PartidaItemWidget(partidaNumber: index + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
