import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class SobrePage extends StatefulWidget {
  const SobrePage({super.key});

  @override
  State<SobrePage> createState() => _SobrePageState();
}

class _SobrePageState extends State<SobrePage> {
  late final Future<PackageInfo> _infoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            titulo: 'Sobre o Joga 10',
            subtitulo: 'Organize, encontre e viva suas partidas',
            trailing: IconButton(
              tooltip: 'Voltar',
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Joga 10',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'MVP para comunidades esportivas',
                                  style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'O Joga 10 é um aplicativo para conectar jogadores, '
                        'organizadores e locais esportivos. A proposta do MVP '
                        'é facilitar a criação de partidas, a descoberta de '
                        'locais, a participação em jogos, a interação social e '
                        'a evolução da jornada esportiva do usuário.',
                        style: TextStyle(
                          color: AppColors.ink,
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<PackageInfo>(
                  future: _infoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final version = info == null
                        ? 'Carregando...'
                        : '${info.version}+${info.buildNumber}';
                    final packageName =
                        info?.packageName ?? 'br.com.joga10.app';

                    return AppCard(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.new_releases_outlined,
                            label: 'Versão do app',
                            value: version,
                          ),
                          const Divider(height: 28),
                          _InfoRow(
                            icon: Icons.apps_outlined,
                            label: 'Identificador',
                            value: packageName,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
