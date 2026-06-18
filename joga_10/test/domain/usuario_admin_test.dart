import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/model/Usuario.dart';

void main() {
  test('somente a role ADMIN habilita recursos administrativos', () {
    final admin = Usuario(
      id: 1,
      primeiroNome: 'Admin',
      email: 'admin@joga10.com',
      role: 'ADMIN',
    );
    final usuario = Usuario(
      id: 2,
      primeiroNome: 'Jogador',
      email: 'jogador@joga10.com',
    );

    expect(admin.isAdmin, isTrue);
    expect(usuario.isAdmin, isFalse);
  });
}
