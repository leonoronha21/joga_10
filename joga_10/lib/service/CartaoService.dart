import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/model/Cartao.dart';

class CartaoService {
  final String baseUrl = "http://ec2-18-231-114-59.sa-east-1.compute.amazonaws.com:8080";

  

  Future<String> cadastraCartao(Cartao cartao) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cadastraCartao'),
  headers: <String, String>{
    'Content-Type': 'application/json',
         },
          body: jsonEncode(cartao.toJson()),
      );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao cadastrar o cartão');
    }
  }

  Future<List<Cartao>> getCartaoUser(int idUser) async {
  final response = await http.post(
    Uri.parse('$baseUrl/cartaoUserId'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'id_user': idUser}),
  );

  if (response.statusCode == 200) {
    Iterable list = json.decode(response.body);
    List<Cartao> cartaoList = List<Cartao>.from(list.map((e) => Cartao.fromJson(e)));
    return cartaoList;
  } else {
    throw Exception('Falha ao obter os cartões do usuário');
  }
}
Future<List<Cartao>> getListCartaoUser(String idUser) async {
    final response = await http.get(
      Uri.parse('$baseUrl/listaCartoesUser?idUser=$idUser'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      List<Cartao> cartaoList = List<Cartao>.from(list.map((e) => Cartao.fromJson(e)));
      return cartaoList;
    } else {
      throw Exception('Falha ao obter os cartões do usuário');
    }
  }
}