import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/domain/services/beneficios_assinatura.dart';
import 'package:joga_10/model/Monetizacao.dart';

void main() {
  const beneficios = BeneficiosAssinatura();

  test('plano free esta liberado sem taxa e com campeonatos', () {
    expect(beneficios.taxaRateio(null), 0);
    expect(beneficios.podeAcessarCampeonatos(null), isTrue);
  });

  test('assinatura Pro ativa tem rateio sem taxa e campeonatos', () {
    final assinatura = AssinaturaUsuario(
      id: 1,
      usuarioId: 10,
      plano: PlanoAssinatura(
        id: 2,
        codigo: 'PRO',
        nome: 'Joga10 Pro',
        precoMensal: 14.90,
      ),
      status: 'ATIVA',
      inicioEm: DateTime.now().subtract(const Duration(days: 1)),
      fimEm: DateTime.now().add(const Duration(days: 1)),
      origem: 'TESTE',
    );

    expect(beneficios.taxaRateio(assinatura), 0);
    expect(beneficios.podeAcessarCampeonatos(assinatura), isTrue);
  });
}
