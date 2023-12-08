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
      List<Cartao> cartoes = await cartaoService.getListCartaoUser(widget.userData['id_user'].toString());

      setState(() {
        // Atualizar o estado com a lista de cartões
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
                Image.asset(
                  'lib/assets/img/cartao-de-credito.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 16.0),
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
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: cartoesCadastrados.length,
                  itemBuilder: (context, index) {
                    String ultimosDigitos = cartoesCadastrados[index].numeroCartao.length >= 4
                      ? cartoesCadastrados[index].numeroCartao.substring(cartoesCadastrados[index].numeroCartao.length - 4)
                      : cartoesCadastrados[index].numeroCartao;
                    return GestureDetector(
                      onTap: () {
                        // Adicione a ação desejada ao tocar no cartão
                        print("Cartão tocado: ${cartoesCadastrados[index].numeroCartao}");
                        // Adicione aqui a navegação para outra página ou ação desejada
                      },
                      child: ListTile(
                        title: Text(
                          'Cartão: **** **** **** $ultimosDigitos',
                          style: TextStyle(color: Colors.white),
                        ),
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
