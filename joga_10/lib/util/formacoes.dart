import 'dart:ui';

/// Uma formação tática: nome + posições normalizadas (0..1).
/// Convenção do eixo y: 0.0 = ataque (topo do campo), 1.0 = gol próprio (base).
/// A primeira posição é sempre o goleiro.
class Formacao {
  final String nome;
  final List<Offset> posicoes;
  const Formacao(this.nome, this.posicoes);
}

class Formacoes {
  static const Map<String, List<Formacao>> porFormato = {
    '5x5': [
      Formacao('2-2', [
        Offset(0.5, 0.90), // GOL
        Offset(0.30, 0.62), Offset(0.70, 0.62),
        Offset(0.30, 0.30), Offset(0.70, 0.30),
      ]),
      Formacao('1-2-1', [
        Offset(0.5, 0.90),
        Offset(0.50, 0.66),
        Offset(0.30, 0.45), Offset(0.70, 0.45),
        Offset(0.50, 0.24),
      ]),
      Formacao('2-1-1', [
        Offset(0.5, 0.90),
        Offset(0.30, 0.66), Offset(0.70, 0.66),
        Offset(0.50, 0.46),
        Offset(0.50, 0.24),
      ]),
      Formacao('3-1', [
        Offset(0.5, 0.90),
        Offset(0.25, 0.60), Offset(0.50, 0.60), Offset(0.75, 0.60),
        Offset(0.50, 0.30),
      ]),
    ],
    '7x7': [
      Formacao('2-3-1', [
        Offset(0.5, 0.92),
        Offset(0.30, 0.72), Offset(0.70, 0.72),
        Offset(0.25, 0.48), Offset(0.50, 0.48), Offset(0.75, 0.48),
        Offset(0.50, 0.24),
      ]),
      Formacao('3-2-1', [
        Offset(0.5, 0.92),
        Offset(0.25, 0.72), Offset(0.50, 0.72), Offset(0.75, 0.72),
        Offset(0.35, 0.48), Offset(0.65, 0.48),
        Offset(0.50, 0.24),
      ]),
      Formacao('2-2-2', [
        Offset(0.5, 0.92),
        Offset(0.30, 0.72), Offset(0.70, 0.72),
        Offset(0.30, 0.50), Offset(0.70, 0.50),
        Offset(0.30, 0.26), Offset(0.70, 0.26),
      ]),
      Formacao('3-3', [
        Offset(0.5, 0.92),
        Offset(0.25, 0.68), Offset(0.50, 0.68), Offset(0.75, 0.68),
        Offset(0.25, 0.38), Offset(0.50, 0.38), Offset(0.75, 0.38),
      ]),
    ],
  };

  static List<Formacao> doFormato(String formato) =>
      porFormato[formato] ?? porFormato['5x5']!;

  static Formacao? buscar(String formato, String? nome) {
    final lista = doFormato(formato);
    for (final f in lista) {
      if (f.nome == nome) return f;
    }
    return lista.first;
  }
}
