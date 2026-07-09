import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class PrivacidadePage extends StatelessWidget {
  const PrivacidadePage({super.key});

  Future<void> _solicitarExclusao(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'privacidade@joga10.app',
      queryParameters: {
        'subject': 'Solicitação de exclusão de conta - Joga 10',
        'body':
            'Olá, quero solicitar a exclusão da minha conta e dos meus dados do Joga 10.',
      },
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel abrir o app de email.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            titulo: 'Privacidade',
            subtitulo: 'Dados, permissões e exclusão de conta',
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
                const AppCard(
                  child: Text(
                    'O Joga 10 usa dados de conta, perfil, contato, localização, '
                    'câmera, fotos e informações de partidas para autenticar o '
                    'usuário, organizar jogos, sugerir locais esportivos, exibir '
                    'perfil social e permitir comprovantes quando houver rateio.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
                const SizedBox(height: 12),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LinhaPrivacidade(
                        icon: Icons.location_on_outlined,
                        titulo: 'Localização',
                        texto:
                            'Usada para buscar locais esportivos próximos e abrir mapas.',
                      ),
                      Divider(height: 24),
                      _LinhaPrivacidade(
                        icon: Icons.contacts_outlined,
                        titulo: 'Contatos',
                        texto:
                            'Usados somente para convites e identificação de amigos no app.',
                      ),
                      Divider(height: 24),
                      _LinhaPrivacidade(
                        icon: Icons.photo_camera_outlined,
                        titulo: 'Câmera e imagens',
                        texto:
                            'Usadas para foto de perfil, verificação facial e comprovantes.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exclusão de conta',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Você pode solicitar a exclusão da conta e dos dados '
                        'associados. Dados que precisem ser mantidos por obrigação '
                        'legal, segurança ou prevenção de fraude serão tratados '
                        'conforme a política de retenção.',
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _solicitarExclusao(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Solicitar exclusão'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaPrivacidade extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String texto;

  const _LinhaPrivacidade({
    required this.icon,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                texto,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
