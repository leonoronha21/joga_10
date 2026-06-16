import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:joga_10/model/Estabelecimentos.dart';
import 'package:joga_10/services/google_places_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/google_places');
  late GooglePlacesService service;

  setUp(() {
    service = GooglePlacesService(channel: channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('converte resultados esportivos encontrados na regiao', () async {
    MethodCall? chamada;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      chamada = call;
      return [
        {
          'placeId': 'place-arena-1',
          'name': 'Arena Esportiva',
          'formattedAddress': 'Av. Esporte, 10 - Porto Alegre',
          'latitude': -30.01,
          'longitude': -51.20,
          'primaryTypeDisplayName': 'Complexo esportivo',
          'rating': 4.7,
          'userRatingCount': 81,
        }
      ];
    });

    final locais = await service.buscarTexto(
      termo: 'futsal',
      centro: const LatLng(-30, -51),
    );

    expect(chamada?.method, 'searchByText');
    expect(chamada?.arguments['query'], 'futsal');
    expect(locais, hasLength(1));
    expect(locais.single.nome, 'Arena Esportiva');
    expect(locais.single.origemGooglePlaces, isTrue);
    expect(locais.single.enderecoResumo, contains('Porto Alegre'));
    expect(locais.single.avaliacao, 4.7);
  });

  test('combina detalhes do Places com o estabelecimento base', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'fetchPlace');
      expect(call.arguments['placeId'], 'place-arena-1');
      return {
        'placeId': 'place-arena-1',
        'name': 'Arena Esportiva',
        'phone': '(51) 99999-0000',
        'websiteUrl': 'https://arena.example',
        'googleMapsUrl': 'https://maps.google.com/?cid=1',
        'openingHours': ['segunda-feira: 08:00-22:00'],
      };
    });
    final base = Estabelecimentos(
      id: -1,
      nome: 'Arena Esportiva',
      placeId: 'place-arena-1',
      latitude: -30.01,
      longitude: -51.20,
      enderecoFormatado: 'Av. Esporte, 10',
    );

    final local = await service.buscarDetalhes(base);

    expect(local?.telefone, '(51) 99999-0000');
    expect(local?.siteUrl, 'https://arena.example');
    expect(local?.googleMapsUrl, contains('maps.google.com'));
    expect(local?.horariosFuncionamento, hasLength(1));
    expect(local?.enderecoResumo, 'Av. Esporte, 10');
  });

  test('retorna lista vazia quando o Places falha', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'PLACES_ERROR');
    });

    final locais = await service.buscarProximos(
      centro: const LatLng(-30, -51),
    );

    expect(locais, isEmpty);
  });
}
