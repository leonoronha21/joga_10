import 'package:flutter/material.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/pages/cadastro_cartao.dart';
import 'package:joga_10/service/CartaoService.dart';

class Pagina3Page extends StatefulWidget {
  final Map<String, dynamic> userData;

  Pagina3Page({Key? key, required this.userData}) : super(key: key);

  @override
  State<Pagina3Page> createState() => _Pagina3PageState();
}

class _Pagina3PageState extends State<Pagina3Page> {

  // Lista de cartões cadastrados
  List<Cartao> cartoesCadastrados = [];

  // Serviço para obter cartões
  final CartaoService cartaoService = CartaoService();

  @override
  void initState() {
    super.initState();
    // Carregar a lista de cartões ao inicializar a tela
    carregarCartoes();
  }

Future<void> carregarCartoes() async {
  try {
    // Converta idUser para String antes de passá-lo
    

    List<Cartao> cartoes = await cartaoService.getCartaoUser(widget.userData['id_user']);
    setState(() {
      cartoesCadastrados = cartoes;
    });
  } catch (e) {
    print("Erro ao carregar os cartões: $e");
    // Adicione a lógica necessária para lidar com erros, como exibir uma mensagem de erro ao usuário.
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 100),
      body: ListView(
        children: <Widget>[
          SizedBox(height: 16.0),
          Container(
            padding: EdgeInsets.all(16.0),
            color: Color.fromARGB(68, 56, 25, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Cartões",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                // Lista de cartões
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: cartoesCadastrados.length-1,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        'Nº:       '+cartoesCadastrados[index].numeroCartao,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CadastroCartaoPage(userData: widget.userData),
                      ),
                    );
                  },
                  child: Text("Adicionar Cartão"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
