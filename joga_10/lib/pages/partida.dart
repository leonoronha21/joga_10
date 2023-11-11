import 'package:flutter/material.dart';
import 'package:joga_10/pages/main_page.dart';

class PartidaPage extends StatefulWidget {
  final List<String> equipe1Members;
  final List<String> equipe2Members;
  final String selectedLocation;
  final String estabelecimento;
  final String price;
  final String selectedTime;
  final String selectedSport;

  PartidaPage( {
    required this.equipe1Members,
    required this.equipe2Members,
    required this.selectedLocation,
    required this.estabelecimento,
    required this.price,
    required this.selectedTime,
    required this.selectedSport,
  });

  @override
  _PartidaPageState createState() => _PartidaPageState();
}

class _PartidaPageState extends State<PartidaPage> {
  @override
  Widget build(BuildContext context) {
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
                 Text("Estabelecimento: ${widget.estabelecimento}", style: TextStyle(color: Colors.white)),
                Text("Preco: ${widget.price}", style: TextStyle(color: Colors.white)),
                Text("Esporte: ${widget.selectedSport}", style: TextStyle(color: Colors.white)),
                Text("Quadra: ${widget.selectedLocation}", style: TextStyle(color: Colors.white)),
                Text("Horário: ${widget.selectedTime}", style: TextStyle(color: Colors.white)),
                Text("Equipe 1:", style: TextStyle(color: Colors.white)),
                Column(
                  children: widget.equipe1Members
                      .map(
                        (member) => Card(
                          color: Color.fromARGB(68, 56, 25, 139),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(member,style: TextStyle(color: Colors.white)),
                                Spacer(),
                                StarRating(), // Aqui você define a avaliação do membro
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                Text("Equipe 2:", style: TextStyle(color: Colors.white)),
                Column(
                  children: widget.equipe2Members
                      .map(
                        (member) => Card(
                         color: Color.fromARGB(68, 56, 25, 139),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(member,style: TextStyle(color: Colors.white)),
                                Spacer(),
                                StarRating(), // Aqui você define a avaliação do membro
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MainPage())); // Voltar à Página Principal
                    },
                    child: Text("Voltar à Página Principal"),
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
    return Row(
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              userRating = starNumber;
            });
          },
          child: Icon(
            userRating >= starNumber ? Icons.star : Icons.star_border,
            color: Colors.yellow,
          ),
        );
      }),
    );
  }
}
