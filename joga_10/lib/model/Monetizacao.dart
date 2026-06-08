import 'package:joga_10/db/row_utils.dart';

class GamificacaoUsuario {
  final int pontos;
  final int partidasConfirmadas;
  final int pagamentosEmDia;
  final int pagamentosPendentes;
  final double confiabilidade;

  GamificacaoUsuario({
    required this.pontos,
    required this.partidasConfirmadas,
    required this.pagamentosEmDia,
    required this.pagamentosPendentes,
    required this.confiabilidade,
  });

  int get nivel => (pontos ~/ 100) + 1;

  String get titulo {
    if (confiabilidade >= 95 && pagamentosEmDia >= 5) return 'Craque confiavel';
    if (partidasConfirmadas >= 10) return 'Figurinha carimbada';
    if (partidasConfirmadas >= 3) return 'Presenca confirmada';
    return 'Comecando o jogo';
  }

  factory GamificacaoUsuario.fromRow(Map<String, dynamic> row) {
    return GamificacaoUsuario(
      pontos: asInt(row['pontos']),
      partidasConfirmadas: asInt(row['partidas_confirmadas']),
      pagamentosEmDia: asInt(row['pagamentos_em_dia']),
      pagamentosPendentes: asInt(row['pagamentos_pendentes']),
      confiabilidade: asDouble(row['confiabilidade'], fallback: 100),
    );
  }
}

class PlanoAssinatura {
  final int id;
  final String codigo;
  final String nome;
  final String? descricao;
  final double precoMensal;

  PlanoAssinatura({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.precoMensal,
  });

  factory PlanoAssinatura.fromRow(Map<String, dynamic> row) {
    return PlanoAssinatura(
      id: asInt(row['id']),
      codigo: (row['codigo'] as String?) ?? 'FREE',
      nome: (row['nome'] as String?) ?? 'Joga10 Free',
      descricao: row['descricao'] as String?,
      precoMensal: asDouble(row['preco_mensal']),
    );
  }
}

class AssinaturaUsuario {
  final int id;
  final int usuarioId;
  final PlanoAssinatura plano;
  final String status;
  final DateTime inicioEm;
  final DateTime? fimEm;
  final String origem;

  AssinaturaUsuario({
    required this.id,
    required this.usuarioId,
    required this.plano,
    required this.status,
    required this.inicioEm,
    this.fimEm,
    required this.origem,
  });

  bool get ativa =>
      status == 'ATIVA' && (fimEm == null || fimEm!.isAfter(DateTime.now()));
}
