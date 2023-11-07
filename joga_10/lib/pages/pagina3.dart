import 'package:flutter/material.dart';

class Pagina3Page extends StatefulWidget {
  const Pagina3Page({Key? key}) : super(key: key);

  @override
  State<Pagina3Page> createState() => _Pagina3PageState();
}

class _Pagina3PageState extends State<Pagina3Page> {
  final TextEditingController gastosController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  int totalPartidas = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
        backgroundColor: Color.fromARGB(68, 56, 25, 100),
      body: ListView(
          
        children: <Widget>[
          Container(
           color: Color.fromARGB(68, 56, 25, 100),
            alignment: Alignment.center,
            child:
             Text(
              "Dados de pagamento",
              style: TextStyle(
                
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                    hintText: 'Seu Nome',
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
                  controller: emailController,
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
                  "Codigo de Segurança",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: gastosController,
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
                  onChanged: (value) {
                    setState(() {
                      totalPartidas = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Text(
                  "Bandeira: $totalPartidas",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Adicione aqui a lógica para salvar os dados
                    print("Botão Salvar pressionado");
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
}
