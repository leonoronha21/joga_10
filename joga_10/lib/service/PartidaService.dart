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
  Future<Partida> getPartidaByIdAndUserId(String partidaId, String userId) async {
    var uri = Uri.parse("http://192.168.10.104:8080/partidaPorId");

    Map<String, String> headers = {"Content-Type": "application/json"};
    Map<String, String> bodyParams = {
      "PartidaID": partidaId,
      "id_user": userId,
    };

    try {
      var body = json.encode(bodyParams);
      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        
        Map<String, dynamic> partidaMap = json.decode(response.body);
        Partida partida = Partida.fromJson(partidaMap);
        return partida;
      } else {
        print("Erro ao obter a partida. Código de status: ${response.statusCode}");
        print("Detalhes do erro: ${response.body}");
        throw Exception("Erro ao obter a partida. Código de status: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro durante a requisição: $e");
      throw Exception("Erro durante a requisição: $e");
    }
  }

   Future<List<Partida>> getPartidasByUserId(String userId) async {
    var uri = Uri.parse("http://192.168.10.104:8080/partidasPorUsuario");

    Map<String, String> headers = {"Content-Type": "application/json"};
    Map<String, String> bodyParams = {
      "id_user": userId,
    };

    try {
      var body = json.encode(bodyParams);
      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        Iterable lista = json.decode(response.body);
        List<Partida> partidas = lista.map((model) => Partida.fromJson(model)).toList();
        return partidas;
      } else {
        print("Erro ao obter as partidas. Código de status: ${response.statusCode}");
        print("Detalhes do erro: ${response.body}");
        throw Exception("Erro ao obter as partidas. Código de status: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro durante a requisição: $e");
      throw Exception("Erro durante a requisição: $e");
    }
  }
  Future<List<Partida>> getPartidasAtivas(String idUser, String status) async {
    final response = await http.post(
      Uri.parse('http://192.168.10.104:8080/partidasAtivas'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_user': idUser,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      // Parse da resposta JSON
      List<dynamic> data = jsonDecode(response.body);
      List<Partida> partidas = data.map((e) => Partida.fromJson(e)).toList();
      return partidas;
    } else {
      throw Exception('Falha ao obter partidas ativas');
    }
  }
  Future<http.Response> finalizaPartida(int partidaId) async {
    var uri = Uri.parse("http://192.168.10.104:8080/finalizaPartida");

    Map<String, String> headers = {"Content-Type": "application/json"};
    Map<String, String> bodyParams = {
      "id": '$partidaId',
      "status": "1",
    };

    try {
      var body = json.encode(bodyParams);
      var response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("Partida finalizada com sucesso: ${response.body}");
      } else {
        print("Erro ao finalizar a partida. Código de status: ${response.statusCode}");
        print("Detalhes do erro: ${response.body}");
      }

      return response;
    } catch (e) {
      print("Erro durante a requisição: $e");
      throw Exception("Erro durante a requisição: $e");
    }
  }
}

