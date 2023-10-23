import 'package:flutter/material.dart';
import '../service/EstabelecimentoService.dart';

class ParceiroPage extends StatefulWidget {
  const ParceiroPage({Key? key}) : super(key: key);

  @override
  State<ParceiroPage> createState() => _ParceiroPageState();
}

class _ParceiroPageState extends State<ParceiroPage> {
  TextEditingController cnpjController = TextEditingController();
  TextEditingController nomeFantasiaController = TextEditingController();
  TextEditingController razaoSocialController = TextEditingController();
  TextEditingController cidadeController = TextEditingController();
  TextEditingController cepController = TextEditingController();
  TextEditingController ruaController = TextEditingController();
  TextEditingController bairroController = TextEditingController();
  TextEditingController numeroController = TextEditingController();
  TextEditingController telefoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController horaAberturaController = TextEditingController();
  TextEditingController horaFechamentoController = TextEditingController();

  EstabelecimentoService estabelecimento = EstabelecimentoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: const Text('Torne-se Parceiro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(
            height: 20,
          ),
          TextField(
            controller: cnpjController,
            decoration: const InputDecoration(
              labelText: 'CNPJ',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: nomeFantasiaController,
            decoration: const InputDecoration(
              labelText: 'Nome Fantasia',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: razaoSocialController,
            decoration: const InputDecoration(
              labelText: 'Razão Social',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: cidadeController,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: cepController,
            decoration: const InputDecoration(
              labelText: 'CEP',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: ruaController,
            decoration: const InputDecoration(
              labelText: 'Rua',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: bairroController,
            decoration: const InputDecoration(
              labelText: 'Bairro',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: numeroController,
            decoration: const InputDecoration(
              labelText: 'Número',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: telefoneController,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: horaAberturaController,
            decoration: const InputDecoration(
              labelText: 'Hora de abertura',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: horaFechamentoController,
            decoration: const InputDecoration(
              labelText: 'Hora de fechamento',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () {
              // Ação a ser realizada ao pressionar o botão de registro
              estabelecimento.SaveEstabelecimento(cnpjController.text, 
              nomeFantasiaController.text, razaoSocialController.text, emailController.text, cepController.text, 
              cidadeController.text, bairroController.text, ruaController.text, telefoneController.text, horaAberturaController.text, 
              horaFechamentoController.text, telefoneController.text, numeroController.text);
              /* cnpjController 
                  nomeFantasiaController
                  razaoSocialController 
                  cidadeController 
                  cepController
                  ruaController
                  bairroController
                  numeroController
                  telefoneController
                  emailController 
                  horaAberturaController
                  horaFechamentoController  */
                              },
            child: const Text('Registrar como Parceiro'),
          ),
        ],
      ),
    );
  }
}