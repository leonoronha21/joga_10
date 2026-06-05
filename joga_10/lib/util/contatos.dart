import 'package:flutter_contacts/flutter_contacts.dart';

/// Abre o seletor nativo de contatos e devolve o nome escolhido.
/// Retorna null se a permissão for negada ou nada for selecionado.
Future<String?> escolherNomeDeContato() async {
  final ok = await FlutterContacts.requestPermission(readonly: true);
  if (!ok) return null;
  final contato = await FlutterContacts.openExternalPick();
  final nome = contato?.displayName.trim();
  return (nome == null || nome.isEmpty) ? null : nome;
}
