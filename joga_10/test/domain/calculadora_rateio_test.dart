import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/domain/services/calculadora_rateio.dart';

void main() {
  const calculadora = CalculadoraRateio();

  test('divide quadra e taxa igualmente entre participantes', () {
    final valores = calculadora.calcular(
      valorQuadra: 120,
      taxaPercentual: 5,
      participantes: 4,
    );

    expect(valores.valorQuadraPorJogador, 30);
    expect(valores.taxaPorJogador, 1.5);
    expect(valores.totalPorJogador, 31.5);
  });

  test('exige ao menos um participante', () {
    expect(
      () => calculadora.calcular(
        valorQuadra: 120,
        taxaPercentual: 5,
        participantes: 0,
      ),
      throwsStateError,
    );
  });
}
