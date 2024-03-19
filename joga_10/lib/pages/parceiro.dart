import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  TextEditingController telefoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController horaAberturaController = TextEditingController();
  TextEditingController horaFechamentoController = TextEditingController();
  
  TextEditingController cidadeController = TextEditingController();
  TextEditingController cepController = TextEditingController();
  TextEditingController ruaController = TextEditingController();
  TextEditingController bairroController = TextEditingController();
  TextEditingController numeroController = TextEditingController();

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
          // Dados da Empresa
          TextField(
            controller: cnpjController,
            decoration: const InputDecoration(
              labelText: 'CNPJ',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
              CNPJMaskTextInputFormatter(),
            ],
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
            controller: telefoneController,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              TelefoneMaskTextInputFormatter(),
            ],
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
          // Dados de Endereço
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              CEPMaskTextInputFormatter(),
            ],
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
            keyboardType: TextInputType.number,
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
  onPressed: () {
    estabelecimento.SaveEstabelecimento(cnpjController.text, nomeFantasiaController.text, razaoSocialController.text, emailController.text, cepController.text, cidadeController.text, bairroController.text, ruaController.text, telefoneController.text, horaAberturaController.text, horaFechamentoController.text, telefoneController.text, numeroController.text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Solicitação de parceria enviada!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Fechar"),
            ),
          ],
        );
      },
    );
  },
  child: const Text('Registrar como Parceiro'),
),
        ],
      ),
    );
  }
}
class CNPJMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 1) {
      return TextEditingValue(
        text: text.length == 1 ? text : '${text.substring(0, 1)}.',
        selection: newValue.selection.copyWith(
          baseOffset: text.length == 1 ? text.length : text.length + 1,
          extentOffset: text.length == 1 ? text.length : text.length + 1,
        ),
      );
    } else if (newValue.selection.baseOffset == 5) {
      return TextEditingValue(
        text: text.length == 5 ? text : '${text.substring(0, 4)}.${text.substring(4)}',
        selection: newValue.selection.copyWith(
          baseOffset: text.length == 5 ? text.length : text.length + 1,
          extentOffset: text.length == 5 ? text.length : text.length + 1,
        ),
      );
    } else if (newValue.selection.baseOffset == 9) {
      return TextEditingValue(
        text: text.length == 9 ? text : '${text.substring(0, 8)}/${text.substring(8)}',
        selection: newValue.selection.copyWith(
          baseOffset: text.length == 9 ? text.length : text.length + 1,
          extentOffset: text.length == 9 ? text.length : text.length + 1,
        ),
      );
    }

    return newValue;
  }
  
}
class CEPMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (text.length <= 5) {
      return TextEditingValue(
        text: text,
        selection: newValue.selection.copyWith(
          baseOffset: text.length,
          extentOffset: text.length,
        ),
      );
    } else {
      return TextEditingValue(
        text: '${text.substring(0, 5)}-${text.substring(5)}',
        selection: newValue.selection.copyWith(
          baseOffset: text.length,
          extentOffset: text.length,
        ),
      );
    }
  }
}

class TelefoneMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var formattedText = '';

    if (text.length >= 1) {
      formattedText += '(${text.substring(0, 2)}';
    }
    if (text.length >= 3) {
      formattedText += ') ${text.substring(2, 7)}';
    }
    if (text.length >= 7) {
      formattedText += '-${text.substring(7)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
