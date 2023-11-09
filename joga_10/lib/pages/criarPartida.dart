import 'package:flutter/material.dart';
import 'package:joga_10/pages/partida.dart';
import 'package:joga_10/pages/selecaoLocal.dart';
import 'package:joga_10/service/PartidaService.dart';

/*
void main() {
  runApp(MaterialApp(
    home: CriarPartidaPage(),
  ));
}*/
/*
class CriarPartidaPage extends StatefulWidget {
  const CriarPartidaPage({Key? key}) : super(key: key);

  @override
  _CriarPartidaPageState createState() => _CriarPartidaPageState();
}*/
class CriarPartidaPage extends StatefulWidget {
  final String estabelecimento; 
  final String price; 
  final String selectedLocation; // Adicione este parâmetro para o local selecionado
  final String selectedTime; // Adicione este parâmetro para o horário selecionado

  CriarPartidaPage({
    required this.estabelecimento,
    required this.price,
    required this.selectedLocation,
    required this.selectedTime,
    
  });

  @override
  _CriarPartidaPageState createState() => _CriarPartidaPageState();
}

class _CriarPartidaPageState extends State<CriarPartidaPage> {
  String selectedSport = 'Futebol';
  List<String> equipe1Members = ['Membro1Equipe1'];
  List<String> equipe2Members = ['Membro1Equipe2'];
  bool isSingleTeam = false; // Variável para armazenar a seleção de time único
  bool isLocationAndTimeSelected = false; // Variável para rastrear a seleção de local e horário

  @override
  Widget build(BuildContext context) {
    // Verifique se tanto o local quanto o horário estão preenchidos
    if (widget.selectedLocation.isNotEmpty && widget.selectedTime.isNotEmpty && widget.price.isNotEmpty && widget.estabelecimento.isNotEmpty) {
      isLocationAndTimeSelected = true;
    } else {
      isLocationAndTimeSelected = false;
    }

    ElevatedButton createButton() {
      if (isLocationAndTimeSelected) {
        return ElevatedButton(
       onPressed: () async {
        // RETIRAR ESSAS VARIAVEIS APOS IMPLEMENTAR GETTERS
        
     
        final response = await PartidaService().SavePartida(
          7, // Substitua por um valor apropriado
          1,          // Substitua por um valor apropriado
          1,            // Substitua por um valor apropriado
          "1 ",           // Substitua por um valor apropriado
          "2023-11-04 "+widget.selectedTime+":00",         // Substitua por um valor apropriado
          "0",               // Status está definido como "0" no seu exemplo
         "120",             // Substitua por um valor apropriado
        );

        if (response.statusCode == 200) {
          // Se a resposta for bem-sucedida (código 200), navegue para a página de partida

        final snackBar = SnackBar(
                      content: Text('Partida criada com sucesso!'),
                      duration: Duration(seconds: 3), // Duração da mensagem
                    );
                     ScaffoldMessenger.of(context).showSnackBar(snackBar);


          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartidaPage(
                equipe1Members: equipe1Members,
                equipe2Members: equipe2Members,
                selectedLocation: widget.selectedLocation,
                selectedTime: widget.selectedTime,
                selectedSport: selectedSport,
                estabelecimento: widget.estabelecimento,
                price: widget.price
              ),
            ),
          );
        } else {
          // Lidar com erros aqui se necessário
          print("Erro ao criar a partida: ${response.body}");
        }
      },
      child: Text("Finalizar"),
    );
  } else {
        return ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SelecionaLocalPage()));
          },
          child: Text("Selecionar Local"),
        );
      }
    }

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
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == selectedSport ? Colors.blue : Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.0),
          // RadioButton para escolher entre time único (Sim) ou dois times (Não)
          RadioListTile(
            title: Text('Time Único (Sim)', style: TextStyle(color: Colors.white)),
            value: true,
            groupValue: isSingleTeam,
            onChanged: (bool? value) {
              setState(() {
                isSingleTeam = value!;
              });
            },
          ),
          RadioListTile(
            title: Text('Dois Times (Não)', style: TextStyle(color: Colors.white)),
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
            'Estabelecimento Selecionado: ${widget.estabelecimento}\nHorário Selecionado: ${widget.selectedTime}\nLocal Selecionado: ${widget.selectedLocation}\nPreço Selecionado: ${widget.price}\n\n\n',
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
                          color: Colors.blue,
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
                        color: Colors.blue,
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
          // Botão de criação (altera de acordo com a variável isLocationAndTimeSelected)
          createButton(),
        ],
      ),
    );
  }
}