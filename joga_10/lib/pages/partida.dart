import 'package:flutter/material.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/pages/main_page.dart';
import 'package:joga_10/service/CartaoService.dart';

class PartidaPage extends StatefulWidget {
  final List<String> equipe1Members;
  final List<String> equipe2Members;
  final String selectedLocation;
  final String estabelecimento;
  final String price;
  final String selectedTime;
  final String selectedSport;
    final Map<String, dynamic> userData;

  PartidaPage({
    required this.equipe1Members,
    required this.equipe2Members,
    required this.selectedLocation,
    required this.estabelecimento,
    required this.price,
    required this.selectedTime,
    required this.selectedSport,
    required this.userData
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
                Text("Dono da partida: ${widget.userData['nome']}${widget.userData['sobrenome']}", style: TextStyle(color: Colors.white)),
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
                CircleAvatar(
                  child: Image.asset(
                    'lib/assets/img/volei.png', 
                    width: 48.0, 
                    height: 48.0,
                  ),
                ),
                SizedBox(width: 8.0), 
                Text(member, style: TextStyle(color: Colors.white)),
                Spacer(),
            
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
                CircleAvatar(
                  child: Image.asset(
                    'lib/assets/img/volei.png', // Substitua pelo caminho correto do seu asset
                    width: 48.0, // Ajuste conforme necessário
                    height: 48.0, // Ajuste conforme necessário
                  ),
                ),
                SizedBox(width: 8.0), // Adicione um espaçamento entre o avatar e o texto
                Text(member, style: TextStyle(color: Colors.white)),
                Spacer(),
                // Aqui você define a avaliação do membro
              ],
            ),
          ),
        ),
      )
      .toList(),
                ),
                
                Text("\n\nComentários:", style: TextStyle(color: Colors.white)),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Adicione seus comentários aqui",
                    hintStyle: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MainPage(userData: widget.userData,))); // Voltar à Página Principal
                      },
                      child: Text("Menu principal"),
                    ),
                    SizedBox(width: 20.0), 
                    ElevatedButton(
                      onPressed: () {
                        _showCardSelectionModal(); 
                      },
                      child: Text("Pagamento"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
void _showCardSelectionModal() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<List<Cartao>>(
        future: CartaoService().getListCartaoUser(widget.userData['id_user'].toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text("Erro ao carregar os cartões");
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text("Nenhum cartão cadastrado");
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Cartao cartao = snapshot.data![index];
                return ListTile(
                  title: Text(cartao.toString()), 
                  onTap: () {
  Navigator.pop(context);
  _showSelectedCard(cartao);
},
                );
              },
            );
          }
        },
      );
    },
  );
}

void _showSelectedCard(Cartao cartaoSelecionado) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Cartão Selecionado"),
    ),
  );
}
}

