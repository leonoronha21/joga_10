import 'package:flutter/material.dart';
import 'package:joga_10/service/UsuarioService.dart';

class DadosCadastraisPage extends StatefulWidget {

   final Map<String, dynamic> userData;

  DadosCadastraisPage({Key? key, required this.userData}) : super(key: key);
  

  @override
  State<DadosCadastraisPage> createState() => _DadosCadastraisPageState();
}

class _DadosCadastraisPageState extends State<DadosCadastraisPage> {
  var nomeController = TextEditingController();
  var dataController = TextEditingController();
  var emailController = TextEditingController();
  var primeiroNomeController = TextEditingController();
  var segundoNomeController = TextEditingController();
  var cidadeController = TextEditingController();
  var complementoController = TextEditingController();
  var ruaController = TextEditingController();
  var bairroController = TextEditingController();
  var contatoController = TextEditingController();
  
  UsuarioService usuarioservice =  UsuarioService();

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
                "Nome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: primeiroNomeController,
                decoration: InputDecoration(
                  hintText: widget.userData['nome'],
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Sobrenome",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: segundoNomeController,
                decoration: InputDecoration(
                  hintText: widget.userData['sobrenome'],
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
                 Text(
                "E-mail",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: emailController,
                decoration: InputDecoration(
                  hintText: widget.userData['sub'],
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Cidade",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: cidadeController,
                decoration: InputDecoration(
                  hintText: 'Sua cidade',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Complemento",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: complementoController,
                decoration: InputDecoration(
                  hintText: 'Complemento',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Rua",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: ruaController,
                decoration: InputDecoration(
                  hintText: 'Rua',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Bairro",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: bairroController,
                decoration: InputDecoration(
                  hintText: 'Bairro',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              Text(
                "Contato",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              TextField(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                controller: contatoController,
                decoration: InputDecoration(
                  hintText: 'Contato',
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  usuarioservice.updateUsuario(primeiroNomeController.text, 
                segundoNomeController.text, emailController.text, 
                cidadeController.text, cidadeController.text, bairroController.text, ruaController.text, 
                contatoController.text, complementoController.text);
                  print("Primeiro Nome: ${primeiroNomeController.text}");
                  print("Segundo Nome: ${segundoNomeController.text}");
                  print("Cidade: ${cidadeController.text}");
                  print("Complemento: ${complementoController.text}");
                  print("Rua: ${ruaController.text}");
                  print("Bairro: ${bairroController.text}");
                  print("Contato: ${contatoController.text}");
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

