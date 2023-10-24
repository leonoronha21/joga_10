import 'package:flutter/material.dart';
import 'package:joga_10/pages/main_page.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;

  StarRating({required this.rating, this.maxRating = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxRating, (index) {
        if (index < rating) {
          return Icon(
            Icons.star,
            color: Colors.yellow,
          );
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.yellow,
          );
        }
      }),
    );
  }
}

class PartidaPage extends StatelessWidget {
  final List<String> equipe1Members;
  final List<String> equipe2Members;
  final String selectedLocation;
  final String selectedTime;
  final String selectedSport;

  PartidaPage({
    required this.equipe1Members,
    required this.equipe2Members,
    required this.selectedLocation,
    required this.selectedTime,
    required this.selectedSport,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Detalhes da Partida"),
      ),
      body: Container(
        color: Color.fromARGB(68, 56, 25, 139),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Esporte: $selectedSport", style: TextStyle(color: Colors.white)),
            Text("Local: $selectedLocation", style: TextStyle(color: Colors.white)),
            Text("Horário: $selectedTime", style: TextStyle(color: Colors.white)),
            Text("Equipe 1:", style: TextStyle(color: Colors.white)),
            Column(
              children: equipe1Members
                  .map(
                    (member) => Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(member),
                            Spacer(),
                            StarRating(rating: 5), // Aqui você define a avaliação do membro
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Text("Equipe 2:", style: TextStyle(color: Colors.white)),
            Column(
              children: equipe2Members
                  .map(
                    (member) => Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(member),
                            Spacer(),
                            StarRating(rating: 4), // Aqui você define a avaliação do membro
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
    );
  }
}
