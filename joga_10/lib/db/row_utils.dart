/// Helpers para ler valores de linhas do PostgreSQL de forma segura.
///
/// Tipos NUMERIC podem chegar como `double`, `int` ou `String` dependendo
/// do codec; estas funções normalizam isso.
double asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

/// Formata um valor de coluna TIME do Postgres como "HH:MM".
/// O driver pode devolver algo como `Time(07:00:00.000)`; extraímos HH:MM.
String? formatHora(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
  if (m == null) return s;
  return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
}
