import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaData.dart';

class PartidaService {




 Future<http.Response> SavePartida(PartidaData partidaData) async {
    var uri = Uri.parse("http://192.168.10.104:8080/criarPartidas");

    Map<String, String> headers = {"Content-Type": "application/json"};

    try {
      var body = json.encode(partidaData.toJson());
      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("Partida criada com sucesso: ${response.body}");
      } else {
        print("Erro ao criar a partida. Código de status: ${response.statusCode}");
        print("Detalhes do erro: ${response.body}");
      }

      return response;
    } catch (e) {
      print("Erro durante a requisição: $e");
      throw Exception("Erro durante a requisição: $e");
    }
  }

   Future<List<Partida>> getAllPartidas() async {
    final response = await http.get(Uri.parse('http://192.168.10.104:8080/listaPartidas'));

    if (response.statusCode == 200) {
      Iterable lista = json.decode(response.body);
      List<Partida> partidas = lista.map((model) => Partida.fromJson(model)).toList();
      return partidas;
    } else {
      throw Exception('Falha ao carregar as partidas');
    }
  }

}