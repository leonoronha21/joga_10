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
  
  UsuarioService usuarioservice = UsuarioService();

    Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Atualizado com sucesso!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o modal
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Atribuir os valores iniciais aos controladores no initState
    primeiroNomeController.text = widget.userData['nome'];
    segundoNomeController.text = widget.userData['sobrenome'];
    emailController.text = widget.userData['sub'];
    cidadeController.text = widget.userData['cidade'];
    complementoController.text = widget.userData['complemento'];
    ruaController.text = widget.userData['rua'];
    bairroController.text = widget.userData['bairro'];
    contatoController.text = widget.userData['contato'];

    
  }
  
 

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
                  hintText: widget.userData['cidade'],
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
                  hintText:  widget.userData['complemento'],
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
                  hintText: widget.userData['rua'],
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
                  hintText:  widget.userData['bairro'],
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
                  hintText: widget.userData['contato'],
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
             ElevatedButton(
  onPressed: () async {
    await usuarioservice.updateUsuario(
      primeiroNomeController.text,
      segundoNomeController.text,
      emailController.text,
       contatoController.text,      
        ruaController.text,
         bairroController.text,
         cidadeController.text,     
        complementoController.text
      
    );

    setState(() {
      _showSuccessDialog();
    });

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

