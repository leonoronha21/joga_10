import 'package:flutter/material.dart';
import 'package:joga_10/pages/login_page.dart';

import '../service/usuarioService.dart';


class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController complementController = TextEditingController();
  final TextEditingController streetController = TextEditingController();

  UsuarioService usuarioservice =  UsuarioService();
  
  OutlineInputBorder customBorder() {
    return OutlineInputBorder(
      borderSide: BorderSide(
        color: const Color.fromARGB(255, 224, 224, 224),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: Text("Cadastro de usuário"),
      ),
      body: Container(
        decoration: BoxDecoration(
          // color: Color.fromARGB(68, 56, 25, 139), // Define a cor de fundo
        ),
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            SizedBox(height: 16.0),
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'Nome',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Sobrenome',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmação de senha',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: cityController,
              decoration: InputDecoration(
                labelText: 'Cidade',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: bairroController,
              decoration: InputDecoration(
                labelText: 'Bairro',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contato (telefone)',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: complementController,
              decoration: InputDecoration(
                labelText: 'Complemento',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: streetController,
              decoration: InputDecoration(
                labelText: 'Rua',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: customBorder(),
                enabledBorder: customBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
             
                usuarioservice.SaveUsuario(firstNameController.text, 
                lastNameController.text, emailController.text, 
                passwordController.text, cityController.text, bairroController.text, streetController.text, 
                contactController.text, complementController.text);

                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }));
              },
              child: Text("Cadastrar-se"),
            ),
          ],
        ),
      ),
    );
  }
}
