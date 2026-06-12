import 'package:flutter_test/flutter_test.dart';
import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/services/locais_esportivos_catalogo.dart';

void main() {
  group('LocaisEsportivosCatalogo', () {
    test('inclui locais de Porto Alegre, Canoas e regiao', () {
      final cidades =
          LocaisEsportivosCatalogo.locais.map((local) => local.cidade).toSet();

      expect(cidades, containsAll(['Porto Alegre', 'Canoas', 'São Leopoldo']));
      expect(LocaisEsportivosCatalogo.locais.length, greaterThanOrEqualTo(10));
      expect(
        LocaisEsportivosCatalogo.locais.every((local) => local.temLocalizacao),
        isTrue,
      );
    });

    test('busca ignora acentos e pesquisa cidade, bairro e nome', () {
      final locais = LocaisEsportivosCatalogo.locais;

      expect(
        LocaisEsportivosCatalogo.filtrar(locais, 'protasio').single.nome,
        'Sesc Protásio Alves',
      );
      expect(
        LocaisEsportivosCatalogo.filtrar(locais, 'canoas').length,
        greaterThanOrEqualTo(4),
      );
      expect(
        LocaisEsportivosCatalogo.filtrar(locais, 'parque dos anjos')
            .single
            .nome,
        'Quadra da Igreja',
      );
    });

    test('cadastro existente ganha prioridade sobre item do catalogo', () {
      final cadastrado = Estabelecimentos(
        id: 99,
        nome: 'Parque Esportivo PUCRS',
        cidade: 'Porto Alegre',
        latitude: -30,
        longitude: -51,
      );

      final resultado = LocaisEsportivosCatalogo.mesclar([cadastrado]);
      final pucrs =
          resultado.where((local) => local.nome == 'Parque Esportivo PUCRS');

      expect(pucrs.single.id, 99);
    });

    test('nao repete marcador quando a coordenada ja esta cadastrada', () {
      final cadastrado = Estabelecimentos(
        id: 100,
        nome: 'Nome personalizado',
        cidade: 'Porto Alegre',
        latitude: -30.0577,
        longitude: -51.2370,
      );

      final resultado = LocaisEsportivosCatalogo.mesclar([cadastrado]);
      final naCoordenada = resultado.where(
        (local) =>
            local.latitude == cadastrado.latitude &&
            local.longitude == cadastrado.longitude,
      );

      expect(naCoordenada.single.id, 100);
    });
  });
}
