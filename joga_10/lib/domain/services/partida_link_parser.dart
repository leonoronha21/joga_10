class PartidaLinkParser {
  final String host;

  const PartidaLinkParser({this.host = 'joga10.app'});

  int? parse(Uri uri) {
    final queryId = int.tryParse(uri.queryParameters['id'] ?? '');
    if (queryId != null) return queryId;

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.toLowerCase() == host) {
      return _idNosSegmentos(uri.pathSegments);
    }

    if (uri.scheme == 'joga10') {
      if (uri.host == 'partida' && uri.pathSegments.isNotEmpty) {
        return int.tryParse(uri.pathSegments.first);
      }
      return _idNosSegmentos(uri.pathSegments);
    }

    return null;
  }

  int? _idNosSegmentos(List<String> segmentos) {
    if (segmentos.length < 2 || segmentos.first != 'partida') return null;
    return int.tryParse(segmentos[1]);
  }
}
