import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/apiconfig.dart';
import 'package:joga_10/model/Usuario.dart';


class UsuarioService {

  Future<http.Response> SaveUsuario(String primeiro_nome, String  segundo_nome, String email, String password, String cidade, 
  String bairro, String rua, String contato, String complemento) async {

    var uri = Uri.parse("${ApiConfig.baseUrl}/cadastroUsuario");

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
       'complemento': '$complemento',
        'role': 'user'
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${response.body}");

    return response;
  }

  Future<http.Response> updateUsuario(String primeiroNome, String segundoNome, String email, String contato, String rua,
    String bairro, String cidade, String complemento) async {
  var uri = Uri.parse("${ApiConfig.baseUrl}/atualizaUsuario");

  Map<String, String> headers = {"Content-Type": "application/json"};

  Map<String, dynamic> data = {
    'primeiroNome': '$primeiroNome',
    'segundoNome': '$segundoNome',
    'email': '$email',
    'contato': '$contato',
    'rua': '$rua',
    'bairro': '$bairro',
    'cidade': '$cidade',
    'complemento': '$complemento',
    "role": "user"
  };

  var body = json.encode(data);
  
  
  print("Request Body: $body");

  var response = await http.put(uri, headers: headers, body: body);

  print("${response.body}");

  return response;
}
     Future<List<Usuario>> listarUsers() async {
    var uri = Uri.parse("${ApiConfig.baseUrl}/lista-usuarios");

    var response = await http.get(uri);

    if (response.statusCode == 200) {
    
      List<dynamic> jsonResponse = json.decode(response.body);

    
      List<Usuario> usuarios = jsonResponse.map((userMap) => Usuario.fromJson(userMap)).toList();

      return usuarios;
    } else {
   
      throw Exception('Falha ao carregar a lista de usuários');
    }
  }
Future<Map<String, dynamic>> decodeToken(String token) async {
  try {
    List<String> parts = token.split('.');
    String payload = parts[1];

 
    payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');

    String decodedPayload = utf8.decode(base64.decode(payload));
    Map<String, dynamic> decodedToken = json.decode(decodedPayload);
    return decodedToken;
  } catch (e) {
    print('Erro ao decodificar o token: $e');
    rethrow;
  }
}



}