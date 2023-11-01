import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UsuarioService {

  Future<http.Response> SaveUsuario(String primeiro_nome, String  segundo_nome, String email, String password, String cidade, 
  String bairro, String rua, String contato, String complemento) async {

    var uri = Uri.parse("http://192.168.10.104:8080/cadastroUsuario");

    Map<String, String> headers = {"Content-Type": "application/json"};

    Map data = {
      'primeiroNome': '$primeiro_nome',
       'segundoNome': '$segundo_nome',
       'email': '$email',
       'password': '$password',
       'cidade': '$cidade',
       'contato': '$contato',
       'bairro': '$bairro',
       'rua': '$rua',
       'complemento': '$complemento'
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${response.body}");

    return response;
  }

  Future<http.Response> updateUsuario(String primeiro_nome, String  segundo_nome, String email, String password, String cidade, 
  String bairro, String rua, String contato, String complemento) async {
  var uri = Uri.parse("http://192.168.10.104:8080/atualizaUsuario");
  
  Map<String, String> headers = {"Content-Type": "application/json"};
  
   Map data = {
      'primeiroNome': '$primeiro_nome',
       'segundoNome': '$segundo_nome',
       'email': '$email',
       'password': '$password',
       'cidade': '$cidade',
       'contato': '$contato',
       'bairro': '$bairro',
       'rua': '$rua',
       'complemento': '$complemento'
    };
  
        var body = json.encode(data);
        var response = await http.post(uri, headers: headers, body: body);
        
        print("${response.body}");
        
        return response;
    }

}