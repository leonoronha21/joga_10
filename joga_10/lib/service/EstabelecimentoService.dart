import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EstabelecimentoService {

  Future<http.Response> SaveEstabelecimento(String cnpj, String  nome, String  razao_social, 
  String email, String cep, String cidade, String bairro, String rua, String contato, String hora_abertura,String hora_fechamento
  ,String telefone,String numero) async {

    var uri = Uri.parse("http://192.168.10.104:8080/cadastroEstabelecimento");

    Map<String, String> headers = {"Content-Type": "application/json"};

    Map data = {
      'cnpj': '$cnpj',
       'nome': '$nome',
       'razao_social': '$razao_social',
       'cidade': '$cidade',
       'cep': '$cep',
       'rua': '$rua',
       'bairro': '$bairro',
       'numero': '$numero',
       'telefone': '$telefone',
       'email': '$email',
       'hora_abertura': '$hora_abertura',
       'hora_fechamento': '$hora_fechamento',
      
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${response.body}");

    return response;
  }


}