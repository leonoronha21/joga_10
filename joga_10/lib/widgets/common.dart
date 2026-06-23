import 'package:flutter/material.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/theme/app_theme.dart';

/// Cabeçalho com gradiente esportivo, usado no topo das telas principais.
class GradientHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? trailing;
  final EdgeInsets padding;

  const GradientHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitulo!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Estado vazio amigável.
class EmptyState extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  const EmptyState({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 8),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 20), acao!],
          ],
        ),
      ),
    );
  }
}

/// Loading central padrão.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

/// Selo de status colorido (para partidas).
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color get _cor {
    switch (status) {
      case PartidaStatus.agendada:
        return AppColors.info;
      case PartidaStatus.emAndamento:
        return AppColors.accent;
      case PartidaStatus.finalizada:
        return AppColors.success;
      case PartidaStatus.cancelada:
        return AppColors.danger;
      default:
        return AppColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        PartidaStatus.label(status),
        style: TextStyle(
          color: _cor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Selo de status genérico (texto + cor).
class StatusBadgeGenerico extends StatelessWidget {
  final String texto;
  final Color cor;
  const StatusBadgeGenerico(
      {super.key, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// Cartão branco padrão com borda suave.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
