import 'package:flutter_test/flutter_test.dart';

import 'package:joga_10/domain/services/recorrencia_partida.dart';

void main() {
  const recorrencia = RecorrenciaPartida();
  final inicio = DateTime(2026, 1, 31, 19);

  test('gera partidas semanais incluindo a primeira e a data final', () {
    final datas = recorrencia.gerarDatas(
      inicio: inicio,
      tipo: TipoRecorrenciaPartida.semanal,
      ate: inicio.add(const Duration(days: 21)),
    );

    expect(datas, hasLength(4));
    expect(datas.last, DateTime(2026, 2, 21, 19));
  });

  test('recorrência mensal respeita o último dia de cada mês', () {
    final datas = recorrencia.gerarDatas(
      inicio: inicio,
      tipo: TipoRecorrenciaPartida.mensal,
      ate: DateTime(2026, 3, 31, 19),
    );

    expect(datas, [
      DateTime(2026, 1, 31, 19),
      DateTime(2026, 2, 28, 19),
      DateTime(2026, 3, 31, 19),
    ]);
  });

  test('exige data final quando há repetição', () {
    expect(
      () => recorrencia.gerarDatas(
        inicio: inicio,
        tipo: TipoRecorrenciaPartida.diaria,
      ),
      throwsArgumentError,
    );
  });
}
