import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/pages/main_page.dart';
import 'package:joga_10/service/MembroService.dart';
import 'package:joga_10/service/PartidaService.dart';

class DetalhePartida extends StatefulWidget {
  final Partida partida;
  final Map<String, dynamic> userData;

  DetalhePartida({required this.partida, required this.userData});

  @override
  _DetalhePartidaState createState() => _DetalhePartidaState();
  
}

class _DetalhePartidaState extends State<DetalhePartida> {
  int userRating = 0;

  @override
  Widget build(BuildContext context) {
    List<PartidaMembro> equipe1 =
        widget.partida.membros.where((membro) => membro.equipe == "Equipe 1").toList();

    List<PartidaMembro> equipe2 =
        widget.partida.membros.where((membro) => membro.equipe == "Equipe 2").toList();

    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Detalhes da Partida"),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            color: Color.fromARGB(68, 56, 25, 139),
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dono da Partida: ${widget.partida.userId} ",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("ID da Partida: ${widget.partida.id}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("ID do Estabelecimento: ${widget.partida.idEstabelecimento}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("ID da Quadra: ${widget.partida.idQuadra}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("Data: ${widget.partida.dataHora}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("\n\nMembros da Equipe 1:\n",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Column(
                  children: equipe1
                      .map(
                        (membro) => Card(
                          color: Color.fromARGB(68, 56, 25, 139),
                          child: ListTile(
                            leading: Image.asset(
                              'lib/assets/img/volei.png',
                              width: 40.0,
                              height: 40.0,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    membro.nome,
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StarRating(),
                                IconButton(
                                  icon: Icon(Icons.report, color: Colors.red),
                                  onPressed: () {
                                    _mostrarDialogoDenuncia(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                Text("Membros da Equipe 2:\n",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Column(
                  children: equipe2
                      .map(
                        (membro) => Card(
                          color: Color.fromARGB(68, 56, 25, 139),
                          child: ListTile(
                            leading: Image.asset(
                              'lib/assets/img/volei.png',
                              width: 40.0,
                              height: 40.0,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    membro.nome,
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StarRating(),
                                IconButton(
                                  icon: Icon(Icons.report, color: Colors.red),
                                  onPressed: () {
                                    _mostrarDialogoDenuncia(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                Text("Comentários:", style: TextStyle(color: Colors.white)),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Adicione seus comentários aqui",
                    hintStyle: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20.0),
                Center(
                  child: (widget.partida.userId == widget.userData['id_user'])
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                try {
                                  
                                  PartidaService partidaService = PartidaService();
                              
                                  partidaService.finalizaPartida(widget.partida.id);

                                  // Exibe o modal com a mensagem "Partida finalizada"
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Partida Finalizada"),
                                        content: Text("A partida foi finalizada com sucesso."),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); 
                                               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage(userData:widget.userData,))); // Navega para a MainPage // Retorna à tela anterior
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } catch (e) {
                                  
                                  print("Erro ao finalizar a partida: $e");
                                }
                              },
                              child: Text("Finalizar Partida"),
                            ),
                            ElevatedButton(
                               onPressed: () {
                               _mostrarSelecaoEquipe(context);
                              },
                              child: Text("Entrar na Partida"),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: () {
                          _mostrarSelecaoEquipe(context);
                          },
                          child: Text("Entrar na Partida"),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _adicionarUsuarioAEquipe(String equipe) {
  try {
  
    MembroService partidaService = MembroService();
    partidaService.adicionarMembroPartida(
        widget.partida.id, widget.userData['id_user'], equipe, widget.userData['nome']);

  } catch (e) {
    print("Erro ao adicionar usuário à equipe: $e");
    // Trate o erro conforme necessário
  }
}

void _mostrarSelecaoEquipe(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Selecionar Equipe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                try{
                _adicionarUsuarioAEquipe("Equipe 1");
                Navigator.of(context).pop(); 
              }catch (e){
                print('Erro ao adicionar usuário à equipe: $e');
              }},
              child: Text("Equipe 1"),
            ),
            ElevatedButton(
              onPressed: () {
                try{
                _adicionarUsuarioAEquipe("Equipe 2");
                Navigator.of(context).pop(); 
              }catch(e){
                     print('Erro ao adicionar usuário à equipe: $e');
              }},
              child: Text("Equipe 2"),
            ),
          ],
        ),
      );
    },
  );
}
}



class StarRating extends StatefulWidget {
  @override
  _StarRatingState createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int userRating = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _mostrarDialogoAvaliacao(context);
      },
      child: Row(
        children: List.generate(5, (index) {
          final starNumber = index + 1;
          return Icon(
            userRating >= starNumber ? Icons.star : Icons.star_border,
            color: Colors.yellow,
          );
        }),
      ),
    );
  }

  _mostrarDialogoAvaliacao(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirme a avaliação"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Toque na estrela para avaliar:"),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(starNumber);
                    },
                    child: Icon(
                      userRating >= starNumber ? Icons.star : Icons.star_border,
                      color: Colors.yellow,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          userRating = value;
        });
        // Adicione a lógica para enviar a avaliação
        // Implemente a ação desejada
      }
    });
  }
}

void _mostrarDialogoDenuncia(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Fazer Denúncia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Descreva sua denúncia:"),
            TextFormField(
              decoration: InputDecoration(
                hintText: "Digite sua denúncia aqui",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
               
                Navigator.of(context).pop(); 
              },
              child: Text("Enviar"),
            ),
          ],
        ),
      );
    },
  );
}
