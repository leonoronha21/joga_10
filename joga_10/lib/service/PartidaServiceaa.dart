import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';

class PartidaService {




  Future<http.Response> SavePartida(int estabelecimento, int quadra, int usuario, 
  String duracao, String data_hora, String status, String preco,  List<PartidaMembro> time1Members,
    List<PartidaMembro> time2Members,) async {

    var uri = Uri.parse("http://192.168.10.104:8080/criarPartidas");

    Map<String, String> headers = {"Content-Type": "application/json"};

    Map data = {
      'id_estabelecimento': '$estabelecimento',
       'id_quadra': '$quadra',
       'user_id': '$usuario',
       'duracao': '$duracao',
       'data_hora': '$data_hora',
       'status': 0,
       'preco': '$preco',
    
    };
    List<PartidaMembro> time1MembersData = time1Members;
    List<PartidaMembro> time2MembersData = time2Members;

     Map<String, dynamic> partidaMembro = {
      'partidaData': data,
      'time1Members': time1MembersData.map((membro) => membro.toJson()).toList(),
      'time2Members': time2MembersData.map((membro) => membro.toJson()).toList(),
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    print("${response.body}");

    return response;
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