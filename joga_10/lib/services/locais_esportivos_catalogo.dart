import 'package:joga_10/model/Estabelecimentos.dart';

class LocaisEsportivosCatalogo {
  const LocaisEsportivosCatalogo._();

  static final List<Estabelecimentos> locais = List.unmodifiable([
    Estabelecimentos(
      id: -5101,
      nome: 'Parque Marinha do Brasil',
      cidade: 'Porto Alegre',
      bairro: 'Praia de Belas',
      rua: 'Av. Edvaldo Pereira Paiva',
      status: 1,
      latitude: -30.0577,
      longitude: -51.2370,
    ),
    Estabelecimentos(
      id: -5102,
      nome: 'Quadras do Parque da Redenção',
      cidade: 'Porto Alegre',
      bairro: 'Bom Fim',
      rua: 'Av. João Pessoa',
      status: 1,
      latitude: -30.0395,
      longitude: -51.2160,
    ),
    Estabelecimentos(
      id: -5103,
      nome: 'Parque Esportivo PUCRS',
      cidade: 'Porto Alegre',
      bairro: 'Jardim Botânico',
      rua: 'Av. Ipiranga',
      numero: '6690',
      telefone: '(51) 3320-3622',
      status: 1,
      latitude: -30.0546677,
      longitude: -51.1713178,
    ),
    Estabelecimentos(
      id: -5104,
      nome: 'Sesc Protásio Alves',
      cidade: 'Porto Alegre',
      bairro: 'Jardim Sabará',
      rua: 'Av. Protásio Alves',
      numero: '6220',
      status: 1,
      latitude: -30.0402543,
      longitude: -51.1484912,
    ),
    Estabelecimentos(
      id: -5201,
      nome: 'Parque Municipal Getúlio Vargas',
      cidade: 'Canoas',
      bairro: 'Marechal Rondon',
      rua: 'Av. Farroupilha',
      status: 1,
      latitude: -29.9146389,
      longitude: -51.1681662,
    ),
    Estabelecimentos(
      id: -5202,
      nome: 'Parque Esportivo Eduardo Gomes',
      cidade: 'Canoas',
      bairro: 'Fátima',
      rua: 'Av. Guilherme Schell',
      numero: '3600',
      status: 1,
      latitude: -29.9388081,
      longitude: -51.1848620,
    ),
    Estabelecimentos(
      id: -5203,
      nome: 'Centro de Esporte e Lazer Mathias Velho',
      cidade: 'Canoas',
      bairro: 'Mathias Velho',
      rua: 'Av. Rio Grande do Sul',
      numero: '1790',
      status: 1,
      latitude: -29.9004034,
      longitude: -51.2326658,
    ),
    Estabelecimentos(
      id: -5204,
      nome: 'Centro Olímpico Municipal de Canoas',
      cidade: 'Canoas',
      bairro: 'Igara',
      rua: 'Rua Araguaia',
      numero: '1151',
      status: 1,
      latitude: -29.9010784,
      longitude: -51.1644995,
    ),
    Estabelecimentos(
      id: -5301,
      nome: 'Ginásio Municipal Celso Morbach',
      cidade: 'São Leopoldo',
      bairro: 'Centro',
      rua: 'Av. Dom João Becker',
      numero: '313',
      status: 1,
      latitude: -29.7594189,
      longitude: -51.1449645,
    ),
    Estabelecimentos(
      id: -5302,
      nome: 'Parque do Trabalhador',
      cidade: 'São Leopoldo',
      bairro: 'Vicentina',
      rua: 'Rua Henrique Lopes',
      status: 1,
      latitude: -29.7785843,
      longitude: -51.1671211,
    ),
    Estabelecimentos(
      id: -5401,
      nome: 'Paladino Tênis Clube',
      cidade: 'Gravataí',
      bairro: 'Altos da Boa Vista',
      rua: 'Rua João Maria Fonseca',
      numero: '1000',
      status: 1,
      latitude: -29.9470143,
      longitude: -50.9986822,
    ),
    Estabelecimentos(
      id: -5402,
      nome: 'Quadra da Igreja',
      cidade: 'Gravataí',
      bairro: 'Parque dos Anjos',
      rua: 'Av. Antônio Gomes Corrêa',
      numero: '245',
      status: 1,
      latitude: -29.9490383,
      longitude: -50.9739523,
    ),
  ]);

  static List<Estabelecimentos> mesclar(
    Iterable<Estabelecimentos> cadastrados,
  ) =>
      mesclarSomente([...cadastrados, ...locais]);

  static List<Estabelecimentos> mesclarSomente(
    Iterable<Estabelecimentos> locaisParaMesclar,
  ) {
    final resultado = <Estabelecimentos>[];
    final chavesNomes = <String>{};
    final chavesCoordenadas = <String>{};
    final placeIds = <String>{};

    for (final local in locaisParaMesclar) {
      if (!local.temLocalizacao) continue;
      final chaveNome =
          '${normalizar(local.nome)}|${normalizar(local.cidade ?? '')}';
      final chaveCoordenada =
          '${local.latitude!.toStringAsFixed(5)}|${local.longitude!.toStringAsFixed(5)}';
      final placeId = local.placeId;
      if ((placeId != null && placeIds.contains(placeId)) ||
          chavesNomes.contains(chaveNome) ||
          chavesCoordenadas.contains(chaveCoordenada)) {
        continue;
      }
      if (placeId != null) placeIds.add(placeId);
      chavesNomes.add(chaveNome);
      chavesCoordenadas.add(chaveCoordenada);
      resultado.add(local);
    }

    resultado.sort((a, b) {
      final porCidade = (a.cidade ?? '').compareTo(b.cidade ?? '');
      return porCidade != 0 ? porCidade : a.nome.compareTo(b.nome);
    });
    return resultado;
  }

  static List<Estabelecimentos> filtrar(
    Iterable<Estabelecimentos> locais,
    String termo,
  ) {
    final busca = normalizar(termo);
    if (busca.isEmpty) return locais.toList();

    return locais.where((local) {
      final texto = normalizar([
        local.nome,
        local.cidade,
        local.bairro,
        local.rua,
        local.numero,
      ].whereType<String>().join(' '));
      return texto.contains(busca);
    }).toList();
  }

  static String normalizar(String valor) {
    const comAcento = 'áàãâäéèêëíìîïóòõôöúùûüç';
    const semAcento = 'aaaaaeeeeiiiiooooouuuuc';
    var resultado = valor.toLowerCase().trim();
    for (var i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado.replaceAll(RegExp(r'\s+'), ' ');
  }
}
