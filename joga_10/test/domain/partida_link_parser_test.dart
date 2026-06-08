import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/domain/services/partida_link_parser.dart';

void main() {
  const parser = PartidaLinkParser();

  test('le o id de um link web da partida', () {
    expect(parser.parse(Uri.parse('https://joga10.app/partida/42')), 42);
  });

  test('le o id de um deep link do app', () {
    expect(parser.parse(Uri.parse('joga10://partida/73')), 73);
  });

  test('ignora links de outro dominio', () {
    expect(parser.parse(Uri.parse('https://exemplo.com/partida/42')), isNull);
  });
}
