import 'package:flutter_contacts/flutter_contacts.dart';

class ContatoSelecionado {
  final String nome;
  final String? telefone;

  const ContatoSelecionado({
    required this.nome,
    this.telefone,
  });
}

Future<ContatoSelecionado?> escolherContato() async {
  final permitido = await FlutterContacts.requestPermission(readonly: true);
  if (!permitido) return null;

  final contato = await FlutterContacts.openExternalPick();
  final nome = contato?.displayName.trim();
  if (contato == null || nome == null || nome.isEmpty) return null;

  final completo = await FlutterContacts.getContact(
    contato.id,
    withProperties: true,
    withThumbnail: false,
    withPhoto: false,
  );
  String? telefone;
  for (final item in completo?.phones ?? const []) {
    final numero = item.number.trim();
    if (numero.isNotEmpty) {
      telefone = numero;
      break;
    }
  }
  return ContatoSelecionado(nome: nome, telefone: telefone);
}

Future<String?> escolherNomeDeContato() async =>
    (await escolherContato())?.nome;
