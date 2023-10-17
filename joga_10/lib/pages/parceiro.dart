import 'package:flutter/material.dart';

class ParceiroPage extends StatefulWidget {
  const ParceiroPage({Key? key}) : super(key: key);

  @override
  State<ParceiroPage> createState() => _ParceiroPageState();
}

class _ParceiroPageState extends State<ParceiroPage> {
  TextEditingController cnpjController = TextEditingController();
  TextEditingController nomeController = TextEditingController();
  TextEditingController nomeComercialController = TextEditingController();
  TextEditingController enderecoController = TextEditingController();
  TextEditingController cidadeController = TextEditingController();
  TextEditingController telefoneController = TextEditingController();
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(68, 56, 25, 139),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(68, 56, 25, 139),
        title: const Text('Torne-se Parceiro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: cnpjController,
              decoration: const InputDecoration(labelText: 'CNPJ',
               labelStyle: TextStyle(color: Colors.white),
               
               ),
                            style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome',
               labelStyle: TextStyle(color: Colors.white),),
               style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: nomeComercialController,
              decoration: const InputDecoration(labelText: 'Nome Comercial',
               labelStyle: TextStyle(color: Colors.white),),
               style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço',
               labelStyle: TextStyle(color: Colors.white),),
               style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: cidadeController,
              decoration: const InputDecoration(labelText: 'Cidade',
               labelStyle: TextStyle(color: Colors.white),),
               style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone',
               labelStyle: TextStyle(color: Colors.white),),
               style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                // Ação a ser realizada ao pressionar o botão de registro
              },
              child: const Text('Registrar como Parceiro'),
            ),
          ],
        ),
      ),
    );
  }
}
