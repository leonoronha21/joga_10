import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/domain/services/beneficios_assinatura.dart';
import 'package:joga_10/model/Liga.dart';
import 'package:joga_10/pages/assinatura_page.dart';
import 'package:joga_10/pages/liga_detalhe_page.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class CampeonatosPage extends StatefulWidget {
  const CampeonatosPage({super.key});

  @override
  State<CampeonatosPage> createState() => _CampeonatosPageState();
}

class _CampeonatosPageState extends State<CampeonatosPage> {
  final _repo = CampeonatoRepository();
  late final MonetizacaoRepositoryContract _monetizacao;
  late final SessaoContract _sessao;
  Future<_DadosCampeonatos>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futuro != null) return;
    final dependencies = AppDependenciesScope.of(context);
    _monetizacao = dependencies.monetizacao;
    _sessao = dependencies.sessao;
    _futuro = _carregar();
  }

  Future<_DadosCampeonatos> _carregar() async {
    final usuarioId = await _sessao.usuarioId;
    final assinatura = usuarioId == null
        ? null
        : await _monetizacao.buscarAssinatura(usuarioId);
    final acesso =
        const BeneficiosAssinatura().podeAcessarCampeonatos(assinatura);
    return _DadosCampeonatos(
      acessoLiberado: acesso,
      ligas: acesso ? await _repo.listarLigas() : const [],
    );
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  Future<void> _abrirAssinatura() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssinaturaPage()),
    );
    if (mounted) _recarregar();
  }

  Future<void> _novaLiga() async {
    final nome = TextEditingController();
    final cidade = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova liga'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome da liga'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cidade,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (ok == true && nome.text.trim().isNotEmpty) {
      await _repo.criarLiga(nome: nome.text, cidade: cidade.text);
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DadosCampeonatos>(
      future: _futuro!,
      builder: (context, snapshot) {
        final dados = snapshot.data;
        return Scaffold(
          floatingActionButton: dados?.acessoLiberado == true
              ? FloatingActionButton.extended(
                  onPressed: _novaLiga,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova liga'),
                )
              : null,
          body: Column(
            children: [
              const GradientHeader(
                titulo: 'Ligas',
                subtitulo: 'Campeonatos com times e classificação',
              ),
              Expanded(child: _corpo(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(AsyncSnapshot<_DadosCampeonatos> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const LoadingView();
    }
    if (snapshot.hasError) {
      return ListView(children: const [
        SizedBox(height: 80),
        EmptyState(
          icone: Icons.cloud_off,
          titulo: 'Erro ao carregar',
          mensagem: 'Não foi possível conectar ao banco.',
        ),
      ]);
    }

    final dados = snapshot.data!;
    if (!dados.acessoLiberado) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 56),
          EmptyState(
            icone: Icons.workspace_premium_outlined,
            titulo: 'Campeonatos são exclusivos do Pro',
            mensagem:
                'Assine o Joga10 Pro para criar ligas, cadastrar times e acompanhar a classificação.',
            acao: ElevatedButton.icon(
              onPressed: _abrirAssinatura,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Conhecer o Joga10 Pro'),
            ),
          ),
        ],
      );
    }

    if (dados.ligas.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        EmptyState(
          icone: Icons.emoji_events_outlined,
          titulo: 'Nenhuma liga',
          mensagem: 'Crie uma liga e adicione os times.',
          acao: ElevatedButton(
            onPressed: _novaLiga,
            child: const Text('Criar liga'),
          ),
        ),
      ]);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _recarregar(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: dados.ligas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _LigaCard(
          liga: dados.ligas[i],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LigaDetalhePage(liga: dados.ligas[i]),
              ),
            );
            _recarregar();
          },
        ),
      ),
    );
  }
}

class _DadosCampeonatos {
  final bool acessoLiberado;
  final List<Liga> ligas;

  const _DadosCampeonatos({
    required this.acessoLiberado,
    required this.ligas,
  });
}

class _LigaCard extends StatelessWidget {
  final Liga liga;
  final VoidCallback onTap;

  const _LigaCard({required this.liga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liga.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${liga.cidade ?? ''}${liga.cidade != null ? ' · ' : ''}${liga.totalTimes} time(s)',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
