import 'package:flutter/material.dart';

import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/domain/services/beneficios_assinatura.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/Rateio.dart';
import 'package:joga_10/services/firestore_compat_ids.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class RateioPartidaPage extends StatefulWidget {
  final Partida partida;

  const RateioPartidaPage({super.key, required this.partida});

  @override
  State<RateioPartidaPage> createState() => _RateioPartidaPageState();
}

class _RateioPartidaPageState extends State<RateioPartidaPage> {
  late final MonetizacaoRepositoryContract _repo;
  late final SessaoContract _sessao;
  Future<PartidaRateio?>? _futuro;
  PartidaRateio? _rateioAtual;
  int? _usuarioId;
  bool _sessaoCarregada = false;
  bool _assinaturaProAtiva = false;
  bool _salvando = false;

  bool get _souOrganizador {
    final uid = FirestoreCompatIds.usuarioUid;
    if (uid != null && widget.partida.organizadorUid != null) {
      return widget.partida.organizadorUid == uid;
    }
    return _usuarioId == widget.partida.organizadorId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futuro != null) return;
    final dependencies = AppDependenciesScope.of(context);
    _repo = dependencies.monetizacao;
    _sessao = dependencies.sessao;
    _futuro = _repo.buscarRateioPorPartida(widget.partida.id);
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final id = await _sessao.usuarioId;
    final assinatura = id == null ? null : await _repo.buscarAssinatura(id);
    if (mounted) {
      setState(() {
        _usuarioId = id;
        _sessaoCarregada = true;
        _assinaturaProAtiva =
            const BeneficiosAssinatura().assinaturaProAtiva(assinatura);
      });
    }
  }

  void _recarregar() => setState(() {
        _rateioAtual = null;
        _futuro = _repo.buscarRateioPorPartida(widget.partida.id);
      });

  Future<void> _configurarRateio(PartidaRateio? atual) async {
    final resultado = await showDialog<_ConfiguracaoRateio>(
      context: context,
      builder: (_) => _DialogConfigurarRateio(
        valorInicial: atual?.valorQuadra ?? widget.partida.preco,
        taxaPercentual: _assinaturaProAtiva
            ? BeneficiosAssinatura.taxaRateioPro
            : BeneficiosAssinatura.taxaRateioFree,
      ),
    );
    if (resultado == null) return;

    setState(() => _salvando = true);
    try {
      await _repo.criarOuAtualizarRateio(
        partidaId: widget.partida.id,
        valorQuadra: resultado.valorQuadra,
      );
      if (!mounted) return;
      _msg('Rateio atualizado.');
      _recarregar();
    } on StateError catch (e) {
      _msg(e.message);
    } catch (_) {
      _msg('Nao foi possivel criar o rateio.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _alterarStatus(RateioCobranca cobranca, String status) async {
    try {
      await _repo.atualizarStatusCobranca(cobranca.id, status);
      if (!mounted) return;
      final rateio = _rateioAtual;
      if (rateio == null) return;
      setState(() {
        _rateioAtual = rateio.copyWith(
          cobrancas: rateio.cobrancas
              .map(
                (item) => item.id == cobranca.id
                    ? item.copyWith(
                        status: status,
                        pagoEm: status == CobrancaStatus.pago
                            ? DateTime.now()
                            : null,
                        limparPagoEm: status != CobrancaStatus.pago,
                      )
                    : item,
              )
              .toList(),
        );
      });
    } catch (_) {
      _msg('Nao foi possivel atualizar o pagamento.');
    }
  }

  Future<void> _fecharRateio(PartidaRateio rateio) async {
    if (rateio.totalPendentes > 0) {
      _msg('Ainda existem pagamentos pendentes.');
      return;
    }
    await _repo.fecharRateio(rateio.id);
    if (!mounted) return;
    _msg('Rateio fechado.');
    _recarregar();
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rateio da partida')),
      body: !_sessaoCarregada
          ? const LoadingView()
          : !_souOrganizador
              ? const EmptyState(
                  icone: Icons.lock_outline,
                  titulo: 'Acesso restrito',
                  mensagem:
                      'Somente o criador da partida pode acessar e gerenciar o rateio.',
                )
              : FutureBuilder<PartidaRateio?>(
                  future: _futuro!,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingView();
                    }
                    if (snapshot.hasError) {
                      return const EmptyState(
                        icone: Icons.cloud_off_outlined,
                        titulo: 'Nao foi possivel carregar o rateio',
                      );
                    }

                    final rateio = _rateioAtual ?? snapshot.data;
                    _rateioAtual ??= rateio;
                    if (rateio == null) return _semRateio();
                    return _conteudo(rateio);
                  },
                ),
    );
  }

  Widget _semRateio() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 56),
        EmptyState(
          icone: Icons.account_balance_wallet_outlined,
          titulo: 'Rateio ainda nao iniciado',
          mensagem: _souOrganizador
              ? 'Divida o valor da quadra entre os participantes.'
              : 'O organizador ainda nao abriu o rateio.',
          acao: _souOrganizador
              ? ElevatedButton.icon(
                  onPressed: _salvando ? null : () => _configurarRateio(null),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Criar rateio'),
                )
              : null,
        ),
      ],
    );
  }

  Widget _conteudo(PartidaRateio rateio) {
    final minhasCobrancas =
        rateio.cobrancas.where((c) => c.idUser == _usuarioId).toList();
    final minhaCobranca =
        minhasCobrancas.isEmpty ? null : minhasCobrancas.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.science_outlined, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pagamento em modo local. Nenhum valor real sera movimentado.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Resumo financeiro',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusBadgeGenerico(
                    texto: rateio.status == RateioStatus.fechado
                        ? 'Fechado'
                        : 'Aberto',
                    cor: rateio.status == RateioStatus.fechado
                        ? AppColors.success
                        : AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _linhaResumo('Valor da quadra', rateio.valorQuadra),
              _linhaResumo('Taxa Joga10', rateio.totalTaxas),
              _linhaResumo('Total do rateio', rateio.totalCobrado,
                  destaque: true),
              const Divider(height: 24),
              Row(
                children: [
                  _contador(
                    'Quitados',
                    '${rateio.totalQuitados}/${rateio.totalParticipantes}',
                    AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _contador(
                    'Pendentes',
                    '${rateio.totalPendentes}',
                    rateio.totalPendentes == 0
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (minhaCobranca != null) ...[
          const SizedBox(height: 16),
          _minhaCobranca(minhaCobranca),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Participantes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            if (_souOrganizador && rateio.status == RateioStatus.aberto)
              IconButton(
                tooltip: 'Recalcular rateio',
                onPressed: _salvando ? null : () => _configurarRateio(rateio),
                icon: const Icon(Icons.calculate_outlined),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...rateio.cobrancas.map((c) => _cobrancaCard(rateio, c)),
        if (_souOrganizador && rateio.status == RateioStatus.aberto) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _fecharRateio(rateio),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Fechar rateio'),
          ),
        ],
      ],
    );
  }

  Widget _minhaCobranca(RateioCobranca cobranca) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minha parte',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _linhaResumo('Quadra', cobranca.valorQuadra),
          _linhaResumo('Taxa do servico', cobranca.taxaServico),
          _linhaResumo('Total', cobranca.valorTotal, destaque: true),
          if (!cobranca.quitado) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _alterarStatus(cobranca, CobrancaStatus.pago),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Simular pagamento'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cobrancaCard(PartidaRateio rateio, RateioCobranca cobranca) {
    final cor = cobranca.pago
        ? AppColors.success
        : cobranca.isento
            ? AppColors.info
            : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.12),
              child: Icon(
                cobranca.quitado
                    ? Icons.check_outlined
                    : Icons.schedule_outlined,
                color: cor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cobranca.nome,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${formatarMoeda(cobranca.valorQuadra)} + ${formatarMoeda(cobranca.taxaServico)} taxa',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatarMoeda(cobranca.valorTotal),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (_souOrganizador && rateio.status == RateioStatus.aberto)
              PopupMenuButton<String>(
                tooltip: 'Atualizar pagamento',
                initialValue: cobranca.status,
                onSelected: (status) => _alterarStatus(cobranca, status),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: CobrancaStatus.pendente,
                    child: Text('Marcar pendente'),
                  ),
                  PopupMenuItem(
                    value: CobrancaStatus.pago,
                    child: Text('Marcar pago'),
                  ),
                  PopupMenuItem(
                    value: CobrancaStatus.isento,
                    child: Text('Marcar isento'),
                  ),
                ],
              )
            else
              StatusBadgeGenerico(
                texto: CobrancaStatus.label(cobranca.status),
                cor: cor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _linhaResumo(String label, double valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: destaque ? AppColors.ink : AppColors.inkMuted,
                fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatarMoeda(valor),
            style: TextStyle(
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contador(String label, String valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.inkMuted)),
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfiguracaoRateio {
  final double valorQuadra;

  const _ConfiguracaoRateio({
    required this.valorQuadra,
  });
}

class _DialogConfigurarRateio extends StatefulWidget {
  final double valorInicial;
  final double taxaPercentual;

  const _DialogConfigurarRateio({
    required this.valorInicial,
    required this.taxaPercentual,
  });

  @override
  State<_DialogConfigurarRateio> createState() =>
      _DialogConfigurarRateioState();
}

class _DialogConfigurarRateioState extends State<_DialogConfigurarRateio> {
  late final TextEditingController _valor;

  @override
  void initState() {
    super.initState();
    _valor =
        TextEditingController(text: widget.valorInicial.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar rateio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _valor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor total da quadra',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (widget.taxaPercentual == 0
                        ? AppColors.success
                        : AppColors.info)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.taxaPercentual == 0
                        ? Icons.workspace_premium_outlined
                        : Icons.percent,
                    color: widget.taxaPercentual == 0
                        ? AppColors.success
                        : AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.taxaPercentual == 0
                          ? 'Assinante Pro: rateio sem taxa.'
                          : 'Plano Free: taxa de 2,5% sobre o rateio.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final valor =
                double.tryParse(_valor.text.replaceAll(',', '.')) ?? 0;
            if (valor <= 0) return;
            Navigator.pop(
              context,
              _ConfiguracaoRateio(
                valorQuadra: valor,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
