import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:joga_10/pages/criarUsuario.dart';
import 'package:joga_10/pages/esqueciSenha.dart';
import 'package:joga_10/pages/main_page.dart';
import 'package:joga_10/pages/parceiro.dart';
import 'package:http/http.dart' as http;
import 'package:joga_10/service/UsuarioService.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}*/
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
                    Expanded(child: Container(   
                      color: Color.fromRGBO(56, 25, 139, 0.267),)),
                    Expanded(
                      flex: 3,
                       child: Image.asset(
                          'lib/assets/img/Joga_transparente.png',
                        ), 
                      //child: Image.network(
                     //   "https://static.vecteezy.com/ti/vetor-gratis/p1/2871329-design-dees-de-campo-verde-de-futebol-e-futebol-gratis-vetor.jpg",
                    //  ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
            /*    const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Joga 10",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),*/
                const Text(
                  "Faça seu login ou cadastre-se e jogue com a gente",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(
                  height: 40,
                ),
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
                const SizedBox(
                  height: 15,
                ),
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
                             // Color.fromARGB(255, 33, 150, 243),
                          color: const Color.fromARGB(255, 33, 150, 243),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                       
                        /*  if (emailController.text.trim() == "admin" &&
                            senhaController.text.trim() == "user") {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainPage(userData: decodedToken),
                            ),
                          );
                        } else {*/
                           login();
                        
                        }  // Chama o método login quando o botão é pressionado                       
     
                      ,
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
                        "ENTRAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  height: 30,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EsqueciSenhaPage()));
                    },
                    /*child: Text(
                      "Esqueci minha senha",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w400,
                      ),
                    ),*/
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
                const SizedBox(
                  height: 10,  // Adicione algum espaço entre os botões
                ),
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
                      backgroundColor: MaterialStateProperty.all(Colors.blue), // Personalize a cor conforme necessário
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
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> login() async {
  final url = Uri.parse('http://ec2-18-231-114-59.sa-east-1.compute.amazonaws.com:8080/login'); 

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
      
      print('Erro de autenticação: ${response.body}');
    }
  } catch (e) {
   
    print('Erro durante o login: $e');
  }
}

}
