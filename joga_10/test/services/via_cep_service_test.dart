import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:joga_10/services/via_cep_service.dart';

void main() {
  test('converte resposta do ViaCEP em endereco', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://viacep.com.br/ws/90000000/json/');
      return http.Response(
        '{"cep":"90000-000","logradouro":"Rua Teste","bairro":"Centro",'
        '"localidade":"Porto Alegre","uf":"RS"}',
        200,
      );
    });

    final endereco = await ViaCepService(client: client).buscar('90000-000');

    expect(endereco?.logradouro, 'Rua Teste');
    expect(endereco?.cidade, 'Porto Alegre');
  });

  test('nao consulta CEP com formato invalido', () async {
    var chamou = false;
    final client = MockClient((request) async {
      chamou = true;
      return http.Response('{}', 200);
    });

    final endereco = await ViaCepService(client: client).buscar('123');

    expect(endereco, isNull);
    expect(chamou, isFalse);
  });
}
