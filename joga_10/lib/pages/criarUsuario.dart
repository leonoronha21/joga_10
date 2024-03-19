import 'package:flutter/material.dart';
import 'package:joga_10/pages/login_page.dart';
import 'package:flutter/services.dart';
import '../service/usuarioService.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<RegistrationPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dados Pessoais"),
      ),
      backgroundColor: Color.fromRGBO(56, 25, 139, 0.267),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CircleAvatar(
                radius: 50,
                child: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    _showAvatarOptions(context);
                  },
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Sobrenome',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o sobrenome';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o e-mail';
                  }
                  // Adicione sua própria validação de e-mail aqui, se necessário
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a senha';
                  } else if (!_isPasswordCompliant(value)) {
                    return 'Senha deve conter pelo menos 8 caracteres, incluindo letras maiúsculas, minúsculas e caracteres especiais';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmação de senha',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme a senha';
                  } else if (value != passwordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState != null &&
                      _formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddressInfoPage(
                            firstName: firstNameController.text, 
                            lastName: lastNameController.text, 
                            email: emailController.text, 
                            password: passwordController.text,
                          )),
                    );
                  }
                },
                child: Text("Próximo", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Selecionar da galeria'),
                onTap: () {
                  // Implementar a lógica para selecionar um avatar da galeria
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Tirar uma foto'),
                onTap: () {
                  // Implementar a lógica para tirar uma foto como avatar
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isPasswordCompliant(String? password) {
    if (password == null || password.isEmpty) {
      return false;
    }
    final RegExp _passwordRegex = RegExp(
        r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$');
    return _passwordRegex.hasMatch(password);
  }
}

class AddressInfoPage extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final TextEditingController cityController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController complementController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final UsuarioService usuarioService = UsuarioService();
  final _formKey = GlobalKey<FormState>();

  AddressInfoPage({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Endereço"),
      ),
      backgroundColor: Color.fromRGBO(56, 25, 139, 0.267),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a cidade';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: bairroController,
                decoration: InputDecoration(
                  labelText: 'Bairro',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o bairro';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Contato (telefone)',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o contato';
                  }
                  // Adicione sua própria validação de número de telefone aqui, se necessário
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: complementController,
                decoration: InputDecoration(
                  labelText: 'Complemento',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: streetController,
                decoration: InputDecoration(
                  labelText: 'Rua',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a rua';
                  }
                  return null;
                },
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState != null &&
                      _formKey.currentState!.validate()) {
                    usuarioService.SaveUsuario(
                      firstName,
                      lastName,
                      email,
                      password,
                      cityController.text,
                      bairroController.text,
                      streetController.text,
                      contactController.text,
                      complementController.text,
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  }
                },
                child: Text("Cadastrar", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
