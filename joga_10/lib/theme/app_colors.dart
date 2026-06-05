import 'package:flutter/material.dart';

/// Paleta do Joga 10 (redesign). Conceito: gramado/energia esportiva.
class AppColors {
  AppColors._();

  // Marca (azul marinho — identidade do projeto)
  static const Color primary = Color(0xFF1B3A6B); // azul marinho
  static const Color primaryDark = Color(0xFF0E2342);
  static const Color primaryLight = Color(0xFF3D6FB5);
  static const Color accent = Color(0xFF2196F3); // azul (destaques)

  // Neutros
  static const Color ink = Color(0xFF0F1B2D); // texto principal
  static const Color inkMuted = Color(0xFF64748B); // texto secundário
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  // Estados
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Gradiente usado em heros/headers
  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2240), Color(0xFF16335E), Color(0xFF1E4D8B)],
  );
}
