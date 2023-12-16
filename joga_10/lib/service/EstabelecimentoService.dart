import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/apiconfig.dart';
import 'package:joga_10/model/Estabelecimentos.dart';

class EstabelecimentoService {

  Future<http.Response> SaveEstabelecimento(String cnpj, String  nome, String  razao_social, 
  String email, String cep, String cidade, String bairro, String rua, String contato, String hora_abertura,String hora_fechamento
  ,String telefone,String numero) async {

    var uri = Uri.parse("${ApiConfig.baseUrl}/cadastroEstabelecimento");

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
   Future<List<Estabelecimentos>> getAllEstabelecimentos() async {
    var uri = Uri.parse("${ApiConfig.baseUrl}/estabelecimentos");

    var response = await http.get(uri);

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      List<Estabelecimentos> estabelecimentosList =
          List<Estabelecimentos>.from(
              list.map((e) => Estabelecimentos.fromJson(e)));
      return estabelecimentosList;
    } else {
      throw Exception('Falha ao obter os estabelecimentos');
    }
  }


}