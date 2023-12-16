import 'package:joga_10/apiconfig.dart';
import 'package:joga_10/model/Quadras.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuadraService {
  final String baseUrl = "${ApiConfig.baseUrl}";

  Future<List<Quadras>> getAllQuadras() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quadras'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        List<Quadras> quadrasList =
            List<Quadras>.from(list.map((e) => Quadras.fromJson(e)));
        return quadrasList;
      } else {
        throw Exception('Falha ao obter as quadras');
      }
    } catch (e) {
      print("Erro ao obter as quadras: $e");

      throw e;
    }
  }
}