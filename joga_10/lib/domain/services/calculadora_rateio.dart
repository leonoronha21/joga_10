class ValoresRateio {
  final double valorQuadraPorJogador;
  final double taxaPorJogador;

  const ValoresRateio({
    required this.valorQuadraPorJogador,
    required this.taxaPorJogador,
  });

  double get totalPorJogador => valorQuadraPorJogador + taxaPorJogador;
}

class CalculadoraRateio {
  const CalculadoraRateio();

  ValoresRateio calcular({
    required double valorQuadra,
    required double taxaPercentual,
    required int participantes,
  }) {
    if (participantes <= 0) {
      throw StateError('Adicione jogadores antes de criar o rateio.');
    }
    if (valorQuadra <= 0) {
      throw ArgumentError.value(valorQuadra, 'valorQuadra');
    }
    if (taxaPercentual < 0) {
      throw ArgumentError.value(taxaPercentual, 'taxaPercentual');
    }

    final valorPorJogador = valorQuadra / participantes;
    return ValoresRateio(
      valorQuadraPorJogador: valorPorJogador,
      taxaPorJogador: valorPorJogador * taxaPercentual / 100,
    );
  }
}
