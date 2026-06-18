import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/util/convite_privado.dart';

void main() {
  test('gera a mesma chave para formatos equivalentes de telefone', () {
    final formatado = chaveContatoConvite('(51) 99999-1234');
    final internacional = chaveContatoConvite('55 51 99999 1234');

    expect(formatado, internacional);
    expect(formatado, hasLength(64));
  });

  test('ignora contato vazio', () {
    expect(chaveContatoConvite(null), isNull);
    expect(chaveContatoConvite('sem telefone'), isNull);
  });
}
