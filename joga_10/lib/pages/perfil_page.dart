import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:joga_10/app.dart';
import 'package:joga_10/model/Usuario.dart';
import 'package:joga_10/pages/assinatura_page.dart';
import 'package:joga_10/pages/cartoes_page.dart';
import 'package:joga_10/pages/dados_cadastrais_page.dart';
import 'package:joga_10/pages/foto_perfil_page.dart';
import 'package:joga_10/pages/goleiro_perfil_page.dart';
import 'package:joga_10/pages/goleiros_page.dart';
import 'package:joga_10/pages/minha_jornada_page.dart';
import 'package:joga_10/pages/parceiro_page.dart';
import 'package:joga_10/repositories/usuario_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Usuario? get _usuario => Sessao.instance.atual;
  Uint8List? _foto;

  @override
  void initState() {
    super.initState();
    _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    final id = _usuario?.id;
    if (id == null) return;
    try {
      final foto = await UsuarioRepository().buscarFoto(id);
      if (mounted) setState(() => _foto = foto);
    } catch (_) {}
  }

  Future<void> _alterarFoto() async {
    final id = _usuario?.id;
    if (id == null) return;
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FotoPerfilPage(usuarioId: id, fotoAtual: _foto),
      ),
    );
    if (mudou == true) _carregarFoto();
  }

  Future<void> _sair() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja encerrar a sessão?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Sessao.instance.sair();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuario;
    return Column(
      children: [
        GradientHeader(
          titulo: u?.nomeCompleto ?? 'Meu perfil',
          subtitulo: u?.email,
          trailing: GestureDetector(
            onTap: _alterarFoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: _foto != null ? MemoryImage(_foto!) : null,
                  child: _foto == null
                      ? Text(
                          (u?.primeiroNome.isNotEmpty ?? false)
                              ? u!.primeiroNome[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera,
                        size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _item(
                icon: Icons.person_outline,
                titulo: 'Dados cadastrais',
                subtitulo: 'Edite suas informações',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DadosCadastraisPage()),
                ).then((_) => setState(() {})),
              ),
              _item(
                icon: Icons.credit_card,
                titulo: 'Meus cartões',
                subtitulo: 'Formas de pagamento',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartoesPage()),
                ),
              ),
              _item(
                icon: Icons.emoji_events_outlined,
                titulo: 'Minha jornada',
                subtitulo: 'Pontos, nivel e confiabilidade',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MinhaJornadaPage()),
                ),
              ),
              _item(
                icon: Icons.workspace_premium_outlined,
                titulo: 'Joga10 Pro',
                subtitulo: 'Recursos e assinatura',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssinaturaPage()),
                ),
              ),
              _item(
                icon: Icons.sports_handball_outlined,
                titulo: 'Contratar goleiro',
                subtitulo: 'Encontre goleiros para seus jogos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoleirosPage()),
                ),
              ),
              _item(
                icon: Icons.sports,
                titulo: 'Sou goleiro',
                subtitulo: 'Disponibilize-se e veja solicitações',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoleiroPerfilPage()),
                ),
              ),
              _item(
                icon: Icons.handshake_outlined,
                titulo: 'Torne-se parceiro',
                subtitulo: 'Cadastre seu estabelecimento',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParceiroPage()),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _sair,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitulo,
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
