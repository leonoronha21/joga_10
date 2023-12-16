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
               //TENHO QUE COLOCAR A LÓGICA PARA RESET DE SENHA AQUI
              },
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
