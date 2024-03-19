import 'package:flutter/material.dart';
import 'package:joga_10/model/PartidaData.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/pages/partida.dart';
import 'package:joga_10/pages/selecaoLocal.dart';
import 'package:joga_10/service/PartidaService.dart';
import 'package:joga_10/service/usuarioService.dart';
import 'package:intl/intl.dart';

class CriarPartidaPage extends StatefulWidget {
  final String estabelecimento;
  final String price;
  final String selectedLocation;
  final String selectedTime;
  final Map<String, dynamic> userData;

  
   
 


  CriarPartidaPage({
    required this.estabelecimento,
    required this.price,
    required this.selectedLocation,
    required this.selectedTime,
   required this.userData
    
  });

  @override
  _CriarPartidaPageState createState() => _CriarPartidaPageState();
}

class _CriarPartidaPageState extends State<CriarPartidaPage> {
  //String selectedSport = 'Futebol';
  List<String> equipe1Members = [];
  List<String> equipe2Members = [];
  List<int> selectedUserIds = [];
  bool isSingleTeam = false;
  bool isLocationAndTimeSelected = false;
  int estabelecimentoId = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedLocation.isNotEmpty &&
        widget.selectedTime.isNotEmpty &&
        widget.price.isNotEmpty &&
        widget.estabelecimento.isNotEmpty) {
      isLocationAndTimeSelected = true;
    } else {
      isLocationAndTimeSelected = false;
    }

    Map<String, dynamic> buildPartidaData() {
      String formattedTime = DateFormat('HH').format(DateTime.now());
  return {
    "partidas": {
      "id_estabelecimento": 18,
      "id_quadra": 1,
      "user_id": widget.userData['id_user'],
      "duracao": "1",
     "data_hora": "2023-12-10 " + formattedTime + ":00",
      "status": "0",
      "preco": 120.0,
    },
    "time1Members": equipe1Members.map((member) {
      var memberId = int.parse(member.split(' ')[0]);
      return {
        "id_user": memberId,
        "equipe": "Equipe 1",
        "nome": member.split(' ')[1],
      };
    }).toList(),
    "time2Members": equipe2Members.map((member) {
      var memberId = int.parse(member.split(' ')[0]);
      return {
        "id_user": memberId,
        "equipe": "Equipe 2",
        "nome": member.split(' ')[1],
      };
    }).toList(),
  };
}
PartidaData buildPartidaDataAsObject() {
  final Map<String, dynamic> partidaDataMap = buildPartidaData();

  return PartidaData(
    idEstabelecimento: partidaDataMap['partidas']['id_estabelecimento'],
    idQuadra: partidaDataMap['partidas']['id_quadra'],
    userId: partidaDataMap['partidas']['user_id'],
    duracao: partidaDataMap['partidas']['duracao'],
    dataHora: partidaDataMap['partidas']['data_hora'],
    status: partidaDataMap['partidas']['status'],
    preco: partidaDataMap['partidas']['preco'],
    time1Members: (partidaDataMap['time1Members'] as List<dynamic>)
        .map((member) => {
              'id_user': member['id_user'],
              'equipe': member['equipe'],
              'nome': member['nome'],
            })
        .toList(),
    time2Members: (partidaDataMap['time2Members'] as List<dynamic>)
        .map((member) => {
              'id_user': member['id_user'],
              'equipe': member['equipe'],
              'nome': member['nome'],
            })
        .toList(),
  );
}

    ElevatedButton createButton() {
      if (isLocationAndTimeSelected) {
        return ElevatedButton(
        onPressed: () async {
  try {
    final partidaData = buildPartidaDataAsObject();
   
    final response = await PartidaService().SavePartida(partidaData);

    if (response.statusCode == 200) {
      final snackBar = SnackBar(
        content: Text('Partida criada com sucesso!'),
        duration: Duration(seconds: 3),
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
           // selectedSport: selectedSport,
            estabelecimento: widget.estabelecimento,
            price: widget.price,
            userData: widget.userData,
          ),
        ),
      );
    } else {
      print("Erro ao criar a partida: ${response.body}");
    }
  } catch (e) {
    print("Erro durante a criação da partida: $e");
  }
},
          child: Text("Criar"),
        );
      } else {
        return ElevatedButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SelecionaLocalPage(userData: widget.userData)));
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
       // padding: const EdgeInsets.all(16.0),
        children: [
          /*  const SizedBox(height: 20),
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
          ),*/
          //SizedBox(height: 20.0),
          RadioListTile(
            title: Text('Time Único', style: TextStyle(color: Colors.white)),
            value: true,
            groupValue: isSingleTeam,
            onChanged: (bool? value) {
              setState(() {
                isSingleTeam = value!;
              });
            },
          ),
          RadioListTile(
            title: Text('Dois Times', style: TextStyle(color: Colors.white)),
            value: false,
            groupValue: isSingleTeam,
            onChanged: (bool? value) {
              setState(() {
                isSingleTeam = value!;
              });
            },
          ),
          Text('Dono da partida:${widget.userData['nome']} ${widget.userData['sobrenome']}'
            '\nEstabelecimento: ${widget.estabelecimento}\nHorário Selecionado: ${widget.selectedTime}\nLocal Selecionado: ${widget.selectedLocation}\nPreço Selecionado: ${widget.price}\n\n\n',
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
                            leading: CircleAvatar(

  child: Image.asset(
    'lib/assets/img/volei.png', 
  
  ),),
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
                    _showUserSearchModal(context, equipe1Members);
                  },
                  child: Text("Buscar usuário - Equipe 1"),
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
                    leading: CircleAvatar(

  child: Image.asset(
    'lib/assets/img/volei.png', 
  
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
                  _showUserSearchModal(context, equipe2Members);
                },
                child: Text("Buscar usuário - Equipe 2"),
              ),
            ],
          ),
          SizedBox(height: 20.0),
          createButton(),
        ],
      ),
    );
  }

  void _showUserSearchModal(BuildContext context, List<String> membersList) async {
    List<Usuario> usuarios = await UsuarioService().listarUsers();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              /*TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar usuários',
                ),
              ),*/
              SizedBox(height: 10.0),
              Expanded(
                child: ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    Usuario usuario = usuarios[index];
                    return ListTile(
                      title: Text('${usuario.primeiroNome} ${usuario.segundoNome}'),
                      onTap: () {
                        setState(() {
                          selectedUserIds.add(usuario.id);
                        });
                        _addUserToTeam(
                          membersList,
                          '${usuario.id} ${usuario.primeiroNome} ${usuario.segundoNome} ',
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addUserToTeam(List<String> teamMembers, String userName) {
    setState(() {
      teamMembers.add(userName);
    });
  }
}
