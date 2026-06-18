class TipoRecorrenciaPartida {
  static const nenhuma = 'NENHUMA';
  static const diaria = 'DIARIA';
  static const semanal = 'SEMANAL';
  static const mensal = 'MENSAL';

  static const valores = [nenhuma, diaria, semanal, mensal];

  static String label(String tipo) {
    switch (tipo) {
      case diaria:
        return 'Diariamente';
      case semanal:
        return 'Semanalmente';
      case mensal:
        return 'Mensalmente';
      default:
        return 'Não repetir';
    }
  }
}

class RecorrenciaPartida {
  static const int maximoOcorrencias = 366;

  const RecorrenciaPartida();

  List<DateTime> gerarDatas({
    required DateTime inicio,
    String tipo = TipoRecorrenciaPartida.nenhuma,
    DateTime? ate,
  }) {
    if (!TipoRecorrenciaPartida.valores.contains(tipo)) {
      throw ArgumentError.value(tipo, 'tipo', 'Recorrência inválida.');
    }
    if (tipo == TipoRecorrenciaPartida.nenhuma) return [inicio];
    if (ate == null || ate.isBefore(inicio)) {
      throw ArgumentError.value(
        ate,
        'ate',
        'Informe uma data final igual ou posterior à primeira partida.',
      );
    }

    final datas = <DateTime>[];
    for (var indice = 0; indice < maximoOcorrencias; indice++) {
      final data = _dataDaOcorrencia(inicio, tipo, indice);
      if (data.isAfter(ate)) break;
      datas.add(data);
    }
    if (datas.isEmpty) datas.add(inicio);
    return datas;
  }

  DateTime _dataDaOcorrencia(DateTime inicio, String tipo, int indice) {
    switch (tipo) {
      case TipoRecorrenciaPartida.diaria:
        return inicio.add(Duration(days: indice));
      case TipoRecorrenciaPartida.semanal:
        return inicio.add(Duration(days: indice * 7));
      case TipoRecorrenciaPartida.mensal:
        return _adicionarMeses(inicio, indice);
      default:
        return inicio;
    }
  }

  DateTime _adicionarMeses(DateTime data, int meses) {
    final mesBase = data.month - 1 + meses;
    final ano = data.year + mesBase ~/ 12;
    final mes = mesBase % 12 + 1;
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    final dia = data.day > ultimoDia ? ultimoDia : data.day;
    return DateTime(
      ano,
      mes,
      dia,
      data.hour,
      data.minute,
      data.second,
      data.millisecond,
      data.microsecond,
    );
  }
}
