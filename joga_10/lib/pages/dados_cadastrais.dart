import 'package:flutter/material.dart';

class DadosCadastraisPage extends StatefulWidget {
  DadosCadastraisPage({Key? key}) : super(key: key);

  @override
  State<DadosCadastraisPage> createState() => _DadosCadastraisPageState();
}

class _DadosCadastraisPageState extends State<DadosCadastraisPage> {
  var nomeController = TextEditingController();
  var dataController = TextEditingController();
  var emailController = TextEditingController();
  var primeiroNomeController = TextEditingController();
  var segundoNomeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        title: const Text("Meus Dados"),
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(
                "Primeiro Nome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: primeiroNomeController,
                decoration: InputDecoration(
                  hintText: 'Seu primeiro nome',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Segundo Nome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: segundoNomeController,
                decoration: InputDecoration(
                  hintText: 'Seu segundo Nome',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Data de nascimento",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: dataController,
                decoration: InputDecoration(
                  hintText: 'Data de nascimento',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Email",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'E-mail',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  print("Primeiro Nome: ${primeiroNomeController.text}");
                  print("Segundo Nome: ${segundoNomeController.text}");
                  print("Data: ${dataController.text}");
                  print("Email: ${emailController.text}");
                },
                child: Text("Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
