import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joga_10/apiconfig.dart';

class MembroService {
  Future adicionarMembroPartida(int idPartida, int idUser, String equipe, String nome) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/adicionaMembro');

    print("Chamando adicionarUsuarioAEquipe com os seguintes parâmetros:");
    print("PartidaID: $idPartida");
    print("id_user: $idUser");
    print("nome: $nome");
    print("equipe: $equipe");
    
    final response = await http.post(
      url,
      body: {
        'idPartida': '$idPartida',
        'idUser': '$idUser',
        'nome': '$nome',
        'equipe': '$equipe',
        
      },
    );

    if (response.statusCode == 200) {
    
      final responseData = json.decode(response.body);
      print(responseData);
    } else {
     
      print('Erro: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
    }
  }
}
