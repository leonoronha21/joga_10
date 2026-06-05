import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:joga_10/theme/app_colors.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _data = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
final _dataCurta = DateFormat('dd/MM/yyyy', 'pt_BR');

String formatarMoeda(num valor) => _moeda.format(valor);
String formatarDataHora(DateTime d) => _data.format(d.toLocal());
String formatarData(DateTime d) => _dataCurta.format(d.toLocal());

/// "agora", "há 5 min", "há 3 h", "há 2 d" ou data curta.
String tempoAtras(DateTime d, {DateTime? agora}) {
  final base = agora ?? DateTime.now();
  final diff = base.difference(d.toLocal());
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays < 7) return 'há ${diff.inDays} d';
  return _dataCurta.format(d.toLocal());
}

/// Mapeia o tipo de quadra para ícone e cor.
class Esporte {
  final IconData icone;
  final Color cor;
  const Esporte(this.icone, this.cor);

  static Esporte porTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'futebol':
      case 'society':
      case 'campo':
        return const Esporte(Icons.sports_soccer, AppColors.primary);
      case 'basquete':
        return const Esporte(Icons.sports_basketball, Color(0xFFEA580C));
      case 'tenis':
      case 'tênis':
        return const Esporte(Icons.sports_tennis, Color(0xFF65A30D));
      case 'volei':
      case 'vôlei':
        return const Esporte(Icons.sports_volleyball, Color(0xFF2563EB));
      default:
        return const Esporte(Icons.sports, AppColors.inkMuted);
    }
  }
}
