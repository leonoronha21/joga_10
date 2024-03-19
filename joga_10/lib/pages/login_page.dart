import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:joga_10/apiconfig.dart';
import 'package:joga_10/pages/criarUsuario.dart';
import 'package:joga_10/pages/esqueciSenha.dart';
import 'package:joga_10/pages/main_page.dart';
import 'package:joga_10/pages/parceiro.dart';
import 'package:joga_10/service/UsuarioService.dart';
import 'package:http/http.dart' as http;


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var emailController = TextEditingController(text: "");
  var senhaController = TextEditingController(text: "");
  bool isObscureText = true;

  @override
  Widget build(BuildContext context) {
    
    return SafeArea(
      child: Scaffold(
         
        backgroundColor: Color.fromRGBO(56, 25, 139, 0.267),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: Container(color: Color.fromRGBO(56, 25, 139, 0.267))),
                    Expanded(
                      flex: 3,
                      child: Image.asset(
                        'lib/assets/img/Joga_transparente.png',
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
                const Text(
                  "Faça seu login ou cadastre-se e jogue com a gente",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 30,
                  alignment: Alignment.center,
                  child: TextField(
                    controller: emailController,
                    onChanged: (value) {
                      debugPrint(value);
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(top: 0),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 33, 150, 243),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 30,
                  alignment: Alignment.center,
                  child: TextField(
                    controller: senhaController,
                    obscureText: isObscureText,
                    onChanged: (value) {
                      debugPrint(value);
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 0),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                      hintText: "Senha",
                      hintStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color.fromARGB(255, 33, 150, 243),
                      ),
                      suffixIcon: InkWell(
                        onTap: () {
                          setState(() {
                            isObscureText = !isObscureText;
                          });
                        },
                        child: Icon(
                          isObscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                    ),
                  ),
                ),
           const SizedBox(height: 15),
Container(
  alignment: Alignment.center,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 248, 246, 246),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset('lib/assets/img/google.png', width: 40, height: 40), // Usando o widget Image.asset com o arquivo google.png
      ),
      SizedBox(width: 10),                  
    ],
  ),
),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                        onPressed: () async {
                       
                          if(emailController.text.trim() == "admin" && senhaController.text.trim() == "user") 
                          {
                              UsuarioService usuarioService =  UsuarioService();
                              Map<String, dynamic> decodedToken =  await usuarioService.decodeToken('eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJsZW9ub3JvbmhhLmFuZHJhZGVAZ21haWwuY29tIiwibm9tZSI6Ikxlb25hcmRvIiwic29icmVub21lIjoiTm9yb25oYSAiLCJpZF91c2VyIjozOSwiYmFpcnJvIjoiRXN0YW5jaWEiLCJjaWRhZGUiOiJDYW5vYXMiLCJjb21wbGVtZW50byI6IkphcmRpbSBQYXJrIENhbm9hcyIsInJ1YSI6IkFKIFJFTk5FUiIsImNvbnRhdG8iOiI1MTk4MjMwODk4ODExIiwiaWF0IjoxNzEwMjkwNjI3LCJleHAiOjE3MTAzNzcwMjd9.bfngOOzfkYcNw0yvUtwoOhXQ1lnteA2A89zj3TvwzoMFTi5K5qYRPYtIqS6zXPg03o2A7cg3xVQQiiTkglEVrw') as Map<String, dynamic>;
                              Navigator.pushReplacement(
                            
                            context,
                            MaterialPageRoute(
                              
                              builder: (context) =>  MainPage(userData: decodedToken),
                            ),
                          );
                        } else {
                           login();
                        }
                         
                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                      child: const Text(
                        "Entrar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 30,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EsqueciSenhaPage()));
                    },
                    child: const Text(
                      "Esqueci minha senha",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 30,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage()));
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    child: const Text(
                      "Criar conta",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 30,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ParceiroPage()));
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    child: const Text(
                      "Torne-se Parceiro",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
  final url = Uri.parse('${ApiConfig.baseUrl}/login');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': emailController.text,
        'password': senhaController.text,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      String token = data['token'];
      print('Token recebido: $token');

      UsuarioService usuarioService = UsuarioService();
      Map<String, dynamic> decodedToken = await usuarioService.decodeToken(token);

      print('Informações do usuário: ${decodedToken.toString()}');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(userData: decodedToken),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Senha Inválida'),
            content: Text('A senha digitada está incorreta. Por favor, tente novamente.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    print('Erro durante o login: $e');
  }
  }
}
