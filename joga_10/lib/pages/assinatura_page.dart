import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class AssinaturaPage extends StatefulWidget {
  const AssinaturaPage({super.key});

  @override
  State<AssinaturaPage> createState() => _AssinaturaPageState();
}

class _AssinaturaPageState extends State<AssinaturaPage> {
  late final SessaoContract _sessao;
  Future<bool>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futuro != null) return;
    final dependencies = AppDependenciesScope.of(context);
    _sessao = dependencies.sessao;
    _futuro = _carregar();
  }

  Future<bool> _carregar() async {
    final id = await _sessao.usuarioId;
    return id != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recursos liberados')),
      body: FutureBuilder<bool>(
        future: _futuro!,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.data != true) {
            return const EmptyState(
              icone: Icons.workspace_premium_outlined,
              titulo: 'Plano indisponivel',
            );
          }
          return _conteudo();
        },
      ),
    );
  }

  Widget _conteudo() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'Joga10 liberado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sem cobranca enquanto a monetizacao estiver pausada.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Recursos disponiveis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _beneficio(Icons.insights_outlined, 'Estatisticas avancadas'),
        _beneficio(Icons.groups_outlined, 'Gestao recorrente do grupo'),
        _beneficio(Icons.emoji_events_outlined, 'Acesso aos campeonatos'),
        _beneficio(Icons.percent_outlined, 'Rateios sem taxa'),
        _beneficio(Icons.auto_awesome_outlined, 'Conquistas exclusivas'),
        const SizedBox(height: 18),
        const Text(
          'Assinaturas e taxas serao reavaliadas em uma etapa futura.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _beneficio(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.check, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
