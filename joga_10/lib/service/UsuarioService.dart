import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/model/Usuario.dart';


class UsuarioService {

  Future<http.Response> SaveUsuario(String primeiro_nome, String  segundo_nome, String email, String password, String cidade, 
  String bairro, String rua, String contato, String complemento) async {

    var uri = Uri.parse("http://http://ec2-18-231-114-59.sa-east-1.compute.amazonaws.com:8080/cadastroUsuario");

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
  var uri = Uri.parse("http://http://ec2-18-231-114-59.sa-east-1.compute.amazonaws.com:8080/atualizaUsuario");

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
  
  // Adiciona um log para verificar o corpo da solicitação
  print("Request Body: $body");

  var response = await http.put(uri, headers: headers, body: body);

  print("${response.body}");

  return response;
}
     Future<List<Usuario>> listarUsers() async {
    var uri = Uri.parse("http://http://ec2-18-231-114-59.sa-east-1.compute.amazonaws.com:8080/lista-usuarios");

    var response = await http.get(uri);

    if (response.statusCode == 200) {
      // Decodifique a resposta JSON para uma lista de mapas.
      List<dynamic> jsonResponse = json.decode(response.body);

      // Converta cada mapa em uma instância de Usuario usando o método fromJson.
      List<Usuario> usuarios = jsonResponse.map((userMap) => Usuario.fromJson(userMap)).toList();

      return usuarios;
    } else {
      // Se a requisição falhar, lança uma exceção.
      throw Exception('Falha ao carregar a lista de usuários');
    }
  }
Future<Map<String, dynamic>> decodeToken(String token) async {
  try {
    List<String> parts = token.split('.');
    String payload = parts[1];

    // Adicionar o padding manualmente se necessário
    payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');

    String decodedPayload = utf8.decode(base64.decode(payload));
    Map<String, dynamic> decodedToken = json.decode(decodedPayload);
    return decodedToken;
  } catch (e) {
    print('Erro ao decodificar o token: $e');
    rethrow; // Rethrow a exceção para que ela possa ser capturada onde a função foi chamada
  }
}


}