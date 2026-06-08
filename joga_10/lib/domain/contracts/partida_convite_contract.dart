import 'package:joga_10/model/Partida.dart';

abstract interface class PartidaConviteContract {
  Stream<int> get partidaLinks;

  Future<void> iniciar();

  void guardarPartidaPendente(int partidaId);

  int? consumirPartidaPendente();

  Uri linkDaPartida(int partidaId);

  String mensagemConvite(Partida partida);

  Future<bool> abrirConviteWhatsApp(Partida partida);

  int? partidaIdFromUri(Uri uri);

  Future<void> dispose();
}
