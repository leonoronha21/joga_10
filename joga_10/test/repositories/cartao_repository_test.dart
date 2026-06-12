import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/repositories/cartao_repository.dart';

void main() {
  test('persiste somente dados seguros do cartao no Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = CartaoRepository(
      firestore: firestore,
      usuarioUid: 'uid-teste',
    );

    await repository.salvar(
      idUser: 0,
      nomeTitular: '  Maria Silva  ',
      bandeira: 'Visa',
      numeroCompleto: '4111 1111 1111 1234',
      validade: '12/2030',
    );

    final snapshot = await firestore
        .collection('cartoes')
        .doc('uid-teste')
        .collection('itens')
        .get();
    expect(snapshot.docs, hasLength(1));
    expect(snapshot.docs.single.data(), containsPair('ultimos4', '1234'));
    expect(snapshot.docs.single.data(), isNot(contains('numeroCompleto')));
    expect(snapshot.docs.single.data(), isNot(contains('cvc')));

    final cartoes = await repository.listarPorUsuario(0);
    expect(cartoes.single.nomeTitular, 'Maria Silva');
    expect(cartoes.single.mascarado, '**** **** **** 1234');
  });
}
