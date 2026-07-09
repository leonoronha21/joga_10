import 'package:flutter_test/flutter_test.dart';
import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/services/locais_esportivos_catalogo.dart';

void main() {
  group('LocaisEsportivosCatalogo', () {
    test('nao adiciona locais fixos ao mapa', () {
      expect(LocaisEsportivosCatalogo.locais, isEmpty);
      expect(LocaisEsportivosCatalogo.mesclar(const []), isEmpty);
    });

    test('busca ignora acentos e pesquisa cidade, bairro e nome', () {
      final locais = [
        Estabelecimentos(
          id: 1,
          nome: 'Sesc Protasio Alves',
          cidade: 'Porto Alegre',
          bairro: 'Jardim Sabara',
          latitude: -30.04,
          longitude: -51.14,
        ),
        Estabelecimentos(
          id: 2,
          nome: 'Quadra da Igreja',
          cidade: 'Gravatai',
          bairro: 'Parque dos Anjos',
          latitude: -29.94,
          longitude: -50.97,
        ),
      ];

      expect(
        LocaisEsportivosCatalogo.filtrar(locais, 'prot\u00e1sio').single.nome,
        'Sesc Protasio Alves',
      );
      expect(
        LocaisEsportivosCatalogo.filtrar(locais, 'parque dos anjos')
            .single
            .nome,
        'Quadra da Igreja',
      );
    });

    test('cadastro existente e resultado remoto nao se repetem por nome', () {
      final cadastrado = Estabelecimentos(
        id: 99,
        nome: 'Parque Esportivo PUCRS',
        cidade: 'Porto Alegre',
        latitude: -30,
        longitude: -51,
      );
      final remotoDuplicado = Estabelecimentos(
        id: -1,
        nome: 'Parque Esportivo PUCRS',
        cidade: 'Porto Alegre',
        latitude: -30.0546677,
        longitude: -51.1713178,
        placeId: 'places-pucrs',
      );

      final resultado = LocaisEsportivosCatalogo.mesclarSomente([
        cadastrado,
        remotoDuplicado,
      ]);

      expect(resultado.single.id, 99);
    });

    test('nao repete marcador quando a coordenada ja esta cadastrada', () {
      final cadastrado = Estabelecimentos(
        id: 100,
        nome: 'Nome personalizado',
        cidade: 'Porto Alegre',
        latitude: -30.0577,
        longitude: -51.2370,
      );
      final remotoDuplicado = Estabelecimentos(
        id: -2,
        nome: 'Outro nome',
        cidade: 'Porto Alegre',
        latitude: -30.057704,
        longitude: -51.236996,
        placeId: 'places-coord',
      );

      final resultado = LocaisEsportivosCatalogo.mesclarSomente([
        cadastrado,
        remotoDuplicado,
      ]);

      expect(resultado.single.id, 100);
    });
  });
}
