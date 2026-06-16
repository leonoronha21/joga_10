import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:joga_10/model/Estabelecimentos.dart';

class GooglePlacesService {
  GooglePlacesService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('br.com.joga10.app/google_places');

  final MethodChannel _channel;

  Future<List<Estabelecimentos>> buscarProximos({
    required LatLng centro,
    double raioMetros = 30000,
  }) {
    return _buscar('searchNearby', {
      'latitude': centro.latitude,
      'longitude': centro.longitude,
      'radius': raioMetros.clamp(1000, 50000),
    });
  }

  Future<List<Estabelecimentos>> buscarTexto({
    required String termo,
    required LatLng centro,
    double raioMetros = 30000,
  }) {
    if (termo.trim().isEmpty) {
      return buscarProximos(centro: centro, raioMetros: raioMetros);
    }
    return _buscar('searchByText', {
      'query': termo.trim(),
      'latitude': centro.latitude,
      'longitude': centro.longitude,
      'radius': raioMetros.clamp(1000, 50000),
    });
  }

  Future<Estabelecimentos?> buscarDetalhes(Estabelecimentos local) async {
    final placeId = local.placeId;
    if (placeId == null || placeId.isEmpty) return local;
    try {
      final dados = await _channel.invokeMapMethod<String, dynamic>(
          'fetchPlace',
          {'placeId': placeId}).timeout(const Duration(seconds: 12));
      return dados == null ? local : _converter(dados, base: local);
    } on PlatformException {
      return local;
    } on TimeoutException {
      return local;
    } on MissingPluginException {
      return local;
    }
  }

  Future<List<Estabelecimentos>> _buscar(
    String metodo,
    Map<String, Object> argumentos,
  ) async {
    try {
      final resposta = await _channel
          .invokeListMethod<dynamic>(metodo, argumentos)
          .timeout(const Duration(seconds: 15));
      return (resposta ?? [])
          .whereType<Map>()
          .map((dados) => _converter(Map<String, dynamic>.from(dados)))
          .where((local) => local.temLocalizacao && local.nome.isNotEmpty)
          .toList();
    } on PlatformException {
      return [];
    } on TimeoutException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  Estabelecimentos _converter(
    Map<String, dynamic> dados, {
    Estabelecimentos? base,
  }) {
    final placeId = dados['placeId'] as String? ?? base?.placeId;
    final latitude = (dados['latitude'] as num?)?.toDouble() ?? base?.latitude;
    final longitude =
        (dados['longitude'] as num?)?.toDouble() ?? base?.longitude;
    final horarios = (dados['openingHours'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        base?.horariosFuncionamento ??
        const [];

    return Estabelecimentos(
      id: base?.id ?? _idDoPlace(placeId ?? '${latitude}_$longitude'),
      nome: (dados['name'] as String?) ?? base?.nome ?? '',
      cidade: base?.cidade,
      bairro: base?.bairro,
      rua: base?.rua,
      numero: base?.numero,
      telefone: (dados['phone'] as String?) ?? base?.telefone,
      status: 1,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      enderecoFormatado:
          (dados['formattedAddress'] as String?) ?? base?.enderecoFormatado,
      tipoPrincipal:
          (dados['primaryTypeDisplayName'] as String?) ?? base?.tipoPrincipal,
      avaliacao: (dados['rating'] as num?)?.toDouble() ?? base?.avaliacao,
      totalAvaliacoes:
          (dados['userRatingCount'] as num?)?.toInt() ?? base?.totalAvaliacoes,
      googleMapsUrl: (dados['googleMapsUrl'] as String?) ?? base?.googleMapsUrl,
      siteUrl: (dados['websiteUrl'] as String?) ?? base?.siteUrl,
      statusFuncionamento:
          (dados['businessStatus'] as String?) ?? base?.statusFuncionamento,
      horariosFuncionamento: horarios,
    );
  }

  int _idDoPlace(String valor) {
    var hash = 0;
    for (final unidade in valor.codeUnits) {
      hash = 0x7fffffff & (hash * 31 + unidade);
    }
    return -(100000 + hash);
  }
}
