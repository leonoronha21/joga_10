import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joga_10/domain/contracts/partida_convite_contract.dart';
import 'package:joga_10/domain/services/partida_link_parser.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/util/format.dart';

class PartidaConviteService implements PartidaConviteContract {
  final AppLinks _appLinks;
  final PartidaLinkParser _parser;

  PartidaConviteService({
    AppLinks? appLinks,
    PartidaLinkParser parser = const PartidaLinkParser(),
  })  : _appLinks = appLinks ?? AppLinks(),
        _parser = parser;

  static const String host = 'joga10.app';

  final _controller = StreamController<int>.broadcast();

  StreamSubscription<Uri>? _subscription;
  bool _iniciado = false;
  int? _partidaPendenteId;

  @override
  Stream<int> get partidaLinks => _controller.stream;

  @override
  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;

    final inicial = await _appLinks.getInitialLink();
    _registrarUri(inicial);

    _subscription = _appLinks.uriLinkStream.listen(_registrarUri);
  }

  @override
  void guardarPartidaPendente(int partidaId) {
    _partidaPendenteId = partidaId;
  }

  @override
  int? consumirPartidaPendente() {
    final id = _partidaPendenteId;
    _partidaPendenteId = null;
    return id;
  }

  @override
  Uri linkDaPartida(int partidaId) => Uri.https(host, '/partida/$partidaId');

  @override
  String mensagemConvite(Partida partida) {
    final nome = partida.quadraNome ?? 'Partida #${partida.id}';
    final data = formatarDataHora(partida.dataHora);
    return 'Bora jogar? Entre na partida #${partida.id} - $nome em $data: ${linkDaPartida(partida.id)}';
  }

  @override
  Future<bool> abrirConviteWhatsApp(Partida partida) {
    final uri = Uri.https('wa.me', '/', {
      'text': mensagemConvite(partida),
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  int? partidaIdFromUri(Uri uri) => _parser.parse(uri);

  void _registrarUri(Uri? uri) {
    if (uri == null) return;
    final partidaId = partidaIdFromUri(uri);
    if (partidaId == null) return;
    guardarPartidaPendente(partidaId);
    _controller.add(partidaId);
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
