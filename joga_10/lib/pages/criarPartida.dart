import 'package:flutter/material.dart';
import 'package:joga_10/pages/selecaoLocal.dart';

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
  String selectedLocation = ''; // Variável para armazenar o local selecionado
  String selectedTime = ''; // Variável para armazenar o horário selecionado
  bool isSingleTeam = false; // Variável para armazenar a seleção de time único

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Criar Partida"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
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
          // RadioButton para escolher entre time único (Sim) ou dois times (Não)
          RadioListTile(
            
            title: Text('Time Único (Sim)', style: TextStyle(color: Colors.white),),
            value: true,
            groupValue: isSingleTeam,
            onChanged: (bool? value) {
              setState(() {
                isSingleTeam = value!;
              });
            },
          ),
          RadioListTile(
            title: Text('Dois Times (Não)',  style: TextStyle(color: Colors.white),),
            value: false,
            groupValue: isSingleTeam,
            onChanged: (bool? value) {
              setState(() {
                isSingleTeam = value!;
              });
              
            },
          ),
          // Label para mostrar o local e o horário selecionados
          Text(
            'Local Selecionado: $selectedLocation\nHorário Selecionado: $selectedTime',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (!isSingleTeam)
            Column(
              children: [
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
                      leading: Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue, // Cor do círculo (pode ser uma imagem)
                        ),
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
              ],
            ),
          Column(
            children: [
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
                    leading: Container(
                      width: 64.0,
                      height: 64.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue, // Cor do círculo (pode ser uma imagem)
                      ),
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
                  if (equipe2Members.length < 10) {
                    equipe2Members.add("Novo Membro Equipe 2");
                  }
                  setState(() {});
                },
                child: Text("Adicionar na Equipe 2"),
              ),
            ],
          ),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SelecionaLocalPage()));
            },
            child: Text("Finalizar"),
          ),
        ],
      ),
    );
  }
}
