import 'dart:convert';

import 'package:crypto/crypto.dart';

String? chaveContatoConvite(String? contato) {
  if (contato == null) return null;
  var digitos = contato.replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return null;
  if (!digitos.startsWith('55') &&
      (digitos.length == 10 || digitos.length == 11)) {
    digitos = '55$digitos';
  }
  return sha256.convert(utf8.encode('joga10-convite:$digitos')).toString();
}
