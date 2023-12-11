import 'dart:convert';
import 'package:http/http.dart' as http;

class MembroService {
  Future adicionarMembroPartida(int idPartida, int idUser, String equipe, String nome) async {
    final url = Uri.parse('http://http://ec2-18-231-114-59.sa-east-1.compute.amazonaws.com:8080/adicionaMembro');
    
    final response = await http.post(
      url,
      body: {
        'idPartida': '$idPartida',
        'idUser': '$idUser',
        'equipe': '$equipe',
        'nome': '$nome',
      },
    );

    if (response.statusCode == 200) {
      // A solicitação foi bem-sucedida, você pode processar a resposta aqui
      final responseData = json.decode(response.body);
      print(responseData);
    } else {
      // A solicitação falhou com um código de status diferente de 200
      print('Erro: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
    }
  }
}
