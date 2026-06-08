import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Monetizacao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class AssinaturaPage extends StatefulWidget {
  const AssinaturaPage({super.key});

  @override
  State<AssinaturaPage> createState() => _AssinaturaPageState();
}

class _AssinaturaPageState extends State<AssinaturaPage> {
  late final MonetizacaoRepositoryContract _repo;
  late final SessaoContract _sessao;
  Future<_DadosAssinatura?>? _futuro;
  bool _ativando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futuro != null) return;
    final dependencies = AppDependenciesScope.of(context);
    _repo = dependencies.monetizacao;
    _sessao = dependencies.sessao;
    _futuro = _carregar();
  }

  Future<_DadosAssinatura?> _carregar() async {
    final id = await _sessao.usuarioId;
    if (id == null) return null;
    final resultados = await Future.wait([
      _repo.listarPlanos(),
      _repo.buscarAssinatura(id),
    ]);
    return _DadosAssinatura(
      usuarioId: id,
      planos: resultados[0] as List<PlanoAssinatura>,
      assinatura: resultados[1] as AssinaturaUsuario?,
    );
  }

  Future<void> _ativarTeste(int usuarioId) async {
    setState(() => _ativando = true);
    try {
      await _repo.ativarTestePro(usuarioId);
      if (!mounted) return;
      _msg('Teste local do Joga10 Pro ativado por 30 dias.');
      setState(() => _futuro = _carregar());
    } catch (_) {
      _msg('Nao foi possivel ativar o teste.');
    } finally {
      if (mounted) setState(() => _ativando = false);
    }
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Joga10 Pro')),
      body: FutureBuilder<_DadosAssinatura?>(
        future: _futuro!,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final dados = snapshot.data;
          if (dados == null) {
            return const EmptyState(
              icone: Icons.workspace_premium_outlined,
              titulo: 'Plano indisponivel',
            );
          }
          return _conteudo(dados);
        },
      ),
    );
  }

  Widget _conteudo(_DadosAssinatura dados) {
    final planosPro = dados.planos.where((p) => p.codigo == 'PRO').toList();
    final pro = planosPro.isEmpty ? null : planosPro.first;
    final assinaturaAtiva = dados.assinatura?.ativa == true;
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
              Text(
                assinaturaAtiva ? 'Joga10 Pro ativo' : 'Joga10 Pro',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (assinaturaAtiva && dados.assinatura?.fimEm != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Teste local ate ${formatarData(dados.assinatura!.fimEm!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ] else if (pro != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${formatarMoeda(pro.precoMensal)} por mes',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Recursos Pro',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _beneficio(Icons.insights_outlined, 'Estatisticas avancadas'),
        _beneficio(Icons.groups_outlined, 'Gestao recorrente do grupo'),
        _beneficio(Icons.auto_awesome_outlined, 'Conquistas exclusivas'),
        _beneficio(Icons.calculate_outlined, 'Relatorios de rateio'),
        const SizedBox(height: 18),
        if (!assinaturaAtiva)
          ElevatedButton.icon(
            onPressed: _ativando || pro == null
                ? null
                : () => _ativarTeste(dados.usuarioId),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(_ativando ? 'Ativando...' : 'Ativar teste local'),
          ),
        const SizedBox(height: 12),
        const Text(
          'A assinatura real sera conectada ao Google Play Billing antes da publicacao.',
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

class _DadosAssinatura {
  final int usuarioId;
  final List<PlanoAssinatura> planos;
  final AssinaturaUsuario? assinatura;

  const _DadosAssinatura({
    required this.usuarioId,
    required this.planos,
    required this.assinatura,
  });
}
