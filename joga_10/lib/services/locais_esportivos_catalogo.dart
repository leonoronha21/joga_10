import 'package:joga_10/model/Estabelecimentos.dart';

class LocaisEsportivosCatalogo {
  const LocaisEsportivosCatalogo._();

  static const List<Estabelecimentos> locais = <Estabelecimentos>[];

  static List<Estabelecimentos> mesclar(
    Iterable<Estabelecimentos> cadastrados,
  ) =>
      mesclarSomente(cadastrados);

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
    const acentos = <String, String>{
      '\u00e1': 'a',
      '\u00e0': 'a',
      '\u00e3': 'a',
      '\u00e2': 'a',
      '\u00e4': 'a',
      '\u00e9': 'e',
      '\u00e8': 'e',
      '\u00ea': 'e',
      '\u00eb': 'e',
      '\u00ed': 'i',
      '\u00ec': 'i',
      '\u00ee': 'i',
      '\u00ef': 'i',
      '\u00f3': 'o',
      '\u00f2': 'o',
      '\u00f5': 'o',
      '\u00f4': 'o',
      '\u00f6': 'o',
      '\u00fa': 'u',
      '\u00f9': 'u',
      '\u00fb': 'u',
      '\u00fc': 'u',
      '\u00e7': 'c',
    };
    var resultado = valor.toLowerCase().trim();
    for (final entry in acentos.entries) {
      resultado = resultado.replaceAll(entry.key, entry.value);
    }
    return resultado.replaceAll(RegExp(r'\s+'), ' ');
  }
}
