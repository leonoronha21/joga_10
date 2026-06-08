import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Monetizacao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class MinhaJornadaPage extends StatefulWidget {
  const MinhaJornadaPage({super.key});

  @override
  State<MinhaJornadaPage> createState() => _MinhaJornadaPageState();
}

class _MinhaJornadaPageState extends State<MinhaJornadaPage> {
  late final MonetizacaoRepositoryContract _repo;
  late final SessaoContract _sessao;
  Future<GamificacaoUsuario?>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futuro != null) return;
    final dependencies = AppDependenciesScope.of(context);
    _repo = dependencies.monetizacao;
    _sessao = dependencies.sessao;
    _futuro = _carregar();
  }

  Future<GamificacaoUsuario?> _carregar() async {
    final id = await _sessao.usuarioId;
    if (id == null) return null;
    return _repo.buscarGamificacao(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha jornada')),
      body: FutureBuilder<GamificacaoUsuario?>(
        future: _futuro!,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final jornada = snapshot.data;
          if (jornada == null) {
            return const EmptyState(
              icone: Icons.emoji_events_outlined,
              titulo: 'Jornada indisponivel',
            );
          }
          return _conteudo(jornada);
        },
      ),
    );
  }

  Widget _conteudo(GamificacaoUsuario jornada) {
    final progressoNivel = (jornada.pontos % 100) / 100;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${jornada.nivel}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jornada.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${jornada.pontos} pontos',
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: progressoNivel,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: AppColors.warning,
                backgroundColor: AppColors.border,
              ),
              const SizedBox(height: 6),
              Text(
                '${100 - (jornada.pontos % 100)} pontos para o proximo nivel',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _metrica(
              Icons.sports_soccer_outlined,
              '${jornada.partidasConfirmadas}',
              'Partidas',
              AppColors.info,
            ),
            const SizedBox(width: 12),
            _metrica(
              Icons.verified_outlined,
              '${jornada.pagamentosEmDia}',
              'Pagamentos',
              AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confiabilidade',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: jornada.confiabilidade / 100,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      color: _corConfiabilidade(jornada.confiabilidade),
                      backgroundColor: AppColors.border,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${jornada.confiabilidade.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (jornada.pagamentosPendentes > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '${jornada.pagamentosPendentes} pagamento(s) pendente(s)',
                  style: const TextStyle(color: AppColors.warning),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como ganhar pontos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _regra(Icons.sports_soccer_outlined, '+10',
                  'Participar de uma partida'),
              _regra(Icons.payments_outlined, '+20', 'Confirmar um pagamento'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metrica(IconData icon, String valor, String label, Color cor) {
    return Expanded(
      child: AppCard(
        child: Column(
          children: [
            Icon(icon, color: cor),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }

  Widget _regra(IconData icon, String pontos, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
          Text(
            pontos,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _corConfiabilidade(double valor) {
    if (valor >= 90) return AppColors.success;
    if (valor >= 70) return AppColors.warning;
    return AppColors.danger;
  }
}
