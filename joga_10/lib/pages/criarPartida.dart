import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: CriarPartidaPage(),
  ));
}

class CriarPartidaPage extends StatefulWidget {
  const CriarPartidaPage({Key? key}) : super(key: key);

  @override
  _CriarPartidaPageState createState() => _CriarPartidaPageState();
}

class _CriarPartidaPageState extends State<CriarPartidaPage> {
  String selectedSport = 'Futebol';
  List<String> equipe1Members = ['Membro1Equipe1'];
  List<String> equipe2Members = ['Membro1Equipe2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Criar Partida"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Selecionar Esporte",
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
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20.0),
            Text(
              "Equipe 1 (Até 10 membros)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: equipe1Members.length,
              itemBuilder: (context, index) {
                final member = equipe1Members[index];
                return ListTile(
                  title: Text(
                    member,
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        equipe1Members.removeAt(index);
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                if (equipe1Members.length < 10) {
                  equipe1Members.add("Novo Membro Equipe 1");
                }
                setState(() {});
              },
              child: Text("Adicionar na Equipe 1"),
            ),
            SizedBox(height: 20.0),
            Text(
              "Equipe 2 (Até 10 membros)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: equipe2Members.length,
              itemBuilder: (context, index) {
                final member = equipe2Members[index];
                return ListTile(
                  title: Text(
                    member,
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        equipe2Members.removeAt(index);
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Ação a ser realizada ao pressionar o botão "Finalizar"
              },
              child: Text("Finalizar"),
            ),
          ],
        ),
      ),
    );
  }
}
