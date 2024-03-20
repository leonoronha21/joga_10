import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:joga_10/endEmail.dart';
import 'dart:math';

class EsqueciSenhaPage extends StatefulWidget {
  const EsqueciSenhaPage({Key? key}) : super(key: key);

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  final TextEditingController emailController = TextEditingController();

  Future<void> _enviarEmailResetSenha() async {
  final String codigo = _gerarCodigoAleatorio();
  final String endpoint = '${endEmail.baseUrl}/sending-email';
  final String body = '''
  {
    "ownerRef": "Joga 10",
    "emailFrom": "joga10.app@gmail.com",
    "emailTo": "${emailController.text}",
    "subject": "E-mail para reset de senha - Esqueci minha senha",
    "text": "Olá, a sua nova senha é: $codigo"
  }
  ''';

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode==201)  {
      // Sucesso
      print('E-mail enviado com sucesso!');
    } else {
      // Erro
      print('Erro ao enviar o e-mail. Status code: ${response.statusCode}');
    }
  } catch (e) {
    // Exceção
    print('Exceção ao enviar o e-mail: $e');
  }
}

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
              onPressed: _enviarEmailResetSenha,
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
String _gerarCodigoAleatorio() {
  const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final _random = Random.secure();
  return Iterable.generate(8, (_) => _chars[_random.nextInt(_chars.length)]).join();
}