import 'dart:convert';

import 'package:http/http.dart' as http;

class EnderecoViaCep {
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;

  const EnderecoViaCep({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });
}

class ViaCepService {
  final http.Client _client;

  ViaCepService({http.Client? client}) : _client = client ?? http.Client();

  Future<EnderecoViaCep?> buscar(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;

    final resposta = await _client
        .get(Uri.https('viacep.com.br', '/ws/$digits/json/'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) return null;

    final dados = jsonDecode(resposta.body);
    if (dados is! Map<String, dynamic> || dados['erro'] == true) return null;
    return EnderecoViaCep(
      cep: (dados['cep'] as String?) ?? cep,
      logradouro: (dados['logradouro'] as String?) ?? '',
      bairro: (dados['bairro'] as String?) ?? '',
      cidade: (dados['localidade'] as String?) ?? '',
      uf: (dados['uf'] as String?) ?? '',
    );
  }

  void dispose() => _client.close();
}
