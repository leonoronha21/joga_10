import 'package:flutter/material.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/pages/main_page.dart';
import 'package:joga_10/pages/pagina3.dart';
import 'package:joga_10/service/CartaoService.dart';

class CadastroCartaoPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  CadastroCartaoPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<CadastroCartaoPage> createState() => _Pagina3PageState();
}

class _Pagina3PageState extends State<CadastroCartaoPage> {
  final TextEditingController cpfcontroller = TextEditingController();
  final TextEditingController cvcControler = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController numeroCartaoController = TextEditingController();
   final TextEditingController bandeiraController = TextEditingController();
   final TextEditingController validadeController = TextEditingController();
 int totalPartidas = 0;
  final CartaoService cartaoService = CartaoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
        backgroundColor: Color.fromARGB(68, 56, 25, 100),
       
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Dados de pagamento"),
      ),
      body: ListView(
          
        children: <Widget>[
       
          SizedBox(height: 16.0),
          Container(
            
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Nome",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: nomeController,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Titular do cartão',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  "CPF",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: cpfcontroller,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '000.000.000-00',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                  SizedBox(height: 16.0),
                Text(
                  "Validade",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: validadeController,
                 
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'MM/AA',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  "Codigo de Segurança",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: cvcControler,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '000',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  "Número do cartão",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: numeroCartaoController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '4365 0000 0000 0000',
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  
                ),
               /* SizedBox(height: 16.0),
                Text(
                  "Bandeira: $totalPartidas",
                  
                  style: TextStyle(
                    
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),*/
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                   
                    salvarDados();
                         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage(userData:widget.userData,))); // Navega para a MainPage // Retorna à tela anterior

                  },
                  child: Text("Salvar"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
   Future<void> salvarDados() async {
    try {
      
      Cartao cartao = Cartao(

        cpf: cpfcontroller.text,
        cvc: cvcControler.text,
        bandeira: "Bandeira padrão",  // Substitua pela lógica necessária
        numeroCartao: numeroCartaoController.text,  // Substitua pela lógica necessária
        nomeTitular: nomeController.text,
        idUser: widget.userData['id_user'],  // Use o ID do usuário do widget
        validade: validadeController.text,  // Substitua pela lógica necessária
      );

      // Chame o método cadastraCartao do serviço
      String resultadoCadastro = await cartaoService.cadastraCartao(cartao);

      // Exiba o resultado do cadastro
      print("Resultado do cadastro: $resultadoCadastro");

      // Adicione qualquer lógica adicional após o cadastro, se necessário
    } catch (e) {
      // Lidere com erros durante o processo de salvamento
      print("Erro ao cadastrar o cartão: $e");
      // Exiba uma mensagem de erro ou tome medidas apropriadas
    }
  }
}

