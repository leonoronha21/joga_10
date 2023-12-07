import 'package:flutter/material.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';

class DetalhePartida extends StatelessWidget {
  final Partida partida;
   

  DetalhePartida({required this.partida});

  @override
  Widget build(BuildContext context) {
    List<PartidaMembro> equipe1 =
        partida.membros.where((membro) => membro.equipe == "Equipe 1").toList();

    List<PartidaMembro> equipe2 =
        partida.membros.where((membro) => membro.equipe == "Equipe 2").toList();

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
                Text("ID da Partida: ${partida.id}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("ID do Estabelecimento: ${partida.idEstabelecimento}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text("ID da Quadra: ${partida.idQuadra}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                    Text("Data: ${partida.dataHora}",
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
                              title: Row(
                                children: [
                                  Text(membro.nome, style: TextStyle(color: Colors.white)),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.person_add, color: Colors.blue), // Adiciona esta linha
                                    onPressed: () {
                                      // Lógica para adicionar como amigo
                                      // Implemente a ação desejada
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.star, color: Colors.yellow), // Adiciona esta linha
                                    onPressed: () {
                                      // Lógica para avaliar
                                      // Implemente a ação desejada
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.report, color: Colors.red), // Adiciona esta linha
                                    onPressed: () {
                                      // Lógica para denunciar
                                      // Implemente a ação desejada
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
                              title: Row(
                                children: [
                                  Text(membro.nome, style: TextStyle(color: Colors.white)),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.person_add, color: Colors.blue), // Adiciona esta linha
                                    onPressed: () {
                                      // Lógica para adicionar como amigo
                                      // Implemente a ação desejada
                                    },
                                  ),
                                 IconButton(
                                    icon: Icon(Icons.star, color: Colors.yellow),
                                    onPressed: () {
                               
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.report, color: Colors.red), // Adiciona esta linha
                                    onPressed: () {
                                      // Lógica para denunciar
                                      // Implemente a ação desejada
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Voltar à tela anterior
                    },
                    child: Text("Entrar na partida"),
                  ),
                ),
              
                
              ],
            ),
          ),
        ],
      ),
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
          title: Text("Avaliar Usuário"),
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
        // Aqui você pode adicionar a lógica para enviar a avaliação
        // Implemente a ação desejada
      }
    });
  }
  
}