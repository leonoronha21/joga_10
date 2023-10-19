import 'package:flutter/material.dart';

class EsqueciSenhaPage extends StatefulWidget {
  const EsqueciSenhaPage({Key? key}) : super(key: key);

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
          backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text('Esqueci a Senha'),
        
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
               labelText: 'E-mail',
               labelStyle: TextStyle(color: Colors.white)
               ),
               
              
              
            ),
            SizedBox(height: 16.0),
            
            ElevatedButton(
              onPressed: () {
                // Lógica para enviar o email de redefinição de senha aqui
                // Normalmente, você enviaria um email para o endereço fornecido
                // com um link para redefinir a senha.
              },
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
