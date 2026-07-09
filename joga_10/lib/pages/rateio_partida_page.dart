import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:joga_10/config/build_config.dart';
import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/media_storage_contract.dart';
import 'package:joga_10/domain/contracts/monetizacao_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Cartao.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/Rateio.dart';
import 'package:joga_10/repositories/cartao_repository.dart';
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
  final _cartaoRepo = CartaoRepository();
  final _picker = ImagePicker();
  Future<PartidaRateio?>? _futuro;
  PartidaRateio? _rateioAtual;
  int? _usuarioId;
  bool _sessaoCarregada = false;
  bool _salvando = false;
  bool _processandoPagamento = false;

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
    if (mounted) {
      setState(() {
        _usuarioId = id;
        _sessaoCarregada = true;
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
                        metodoPagamento: status == CobrancaStatus.pago
                            ? item.metodoPagamento
                            : null,
                        limparMetodoPagamento: status != CobrancaStatus.pago,
                        comprovanteUrl: status == CobrancaStatus.pago
                            ? item.comprovanteUrl
                            : null,
                        limparComprovante: status != CobrancaStatus.pago,
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

  Future<void> _confirmarPagamento(RateioCobranca cobranca) async {
    if (_processandoPagamento) return;
    final metodo = await _selecionarMetodoPagamento();
    if (metodo == null || !mounted) return;
    final anexarComprovante = await _perguntarComprovante();
    if (!mounted) return;

    setState(() => _processandoPagamento = true);
    try {
      final comprovanteUrl =
          anexarComprovante ? await _anexarComprovante() : null;
      await _repo.atualizarStatusCobranca(
        cobranca.id,
        CobrancaStatus.pago,
        metodoPagamento: metodo.rotulo,
        comprovanteUrl: comprovanteUrl,
      );
      if (!mounted) return;
      final rateio = _rateioAtual;
      if (rateio != null) {
        setState(() {
          _rateioAtual = rateio.copyWith(
            cobrancas: rateio.cobrancas
                .map(
                  (item) => item.id == cobranca.id
                      ? item.copyWith(
                          status: CobrancaStatus.pago,
                          pagoEm: DateTime.now(),
                          metodoPagamento: metodo.rotulo,
                          comprovanteUrl: comprovanteUrl,
                        )
                      : item,
                )
                .toList(),
          );
        });
      }
      _msg('Pagamento confirmado.');
    } catch (_) {
      _msg('Nao foi possivel confirmar o pagamento.');
    } finally {
      if (mounted) setState(() => _processandoPagamento = false);
    }
  }

  Future<_MetodoPagamento?> _selecionarMetodoPagamento() async {
    if (!BuildConfig.demoPaymentsEnabled) {
      return showModalBottomSheet<_MetodoPagamento>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pagamento externo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Registrar comprovante'),
                  subtitle: const Text(
                    'Use para pagamentos combinados fora do app.',
                  ),
                  onTap: () => Navigator.pop(
                    context,
                    const _MetodoPagamento('Pagamento externo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Cartao> cartoes = const [];
    final usuarioId = _usuarioId;
    if (usuarioId != null) {
      try {
        cartoes = await _cartaoRepo.listarPorUsuario(usuarioId);
      } catch (_) {
        cartoes = const [];
      }
    }
    if (!mounted) return null;

    return showModalBottomSheet<_MetodoPagamento>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forma de pagamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Google Pay / Google Play'),
                subtitle: const Text('Confirmacao em ambiente de teste.'),
                onTap: () => Navigator.pop(
                  context,
                  const _MetodoPagamento('Google Pay / Google Play'),
                ),
              ),
              if (cartoes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6, bottom: 10),
                  child: Text(
                    'Nenhum cartao cadastrado. Use o Google Pay ou cadastre um cartao no perfil.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                )
              else
                ...cartoes.map(
                  (cartao) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.credit_card_outlined),
                    title: Text('Cartao final ${cartao.ultimos4}'),
                    subtitle: Text(
                      [
                        if ((cartao.bandeira ?? '').isNotEmpty)
                          cartao.bandeira!,
                        cartao.validade,
                      ].join(' - '),
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      _MetodoPagamento('Cartao final ${cartao.ultimos4}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _perguntarComprovante() async {
    final resposta = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comprovante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file_outlined),
                title: const Text('Anexar comprovante'),
                subtitle: const Text('Escolha uma imagem da galeria.'),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Confirmar sem comprovante'),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    return resposta ?? false;
  }

  Future<String?> _anexarComprovante() async {
    final midia = AppDependenciesScope.of(context).midia;
    final proprietarioId =
        FirestoreCompatIds.usuarioUid ?? _usuarioId?.toString() ?? 'usuario';
    final arquivo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (arquivo == null) return null;
    if (!midia.uploadsHabilitados) return arquivo.path;
    final armazenado = await midia.enviar(
      tipo: TipoMidia.documento,
      proprietarioId: proprietarioId,
      bytes: await arquivo.readAsBytes(),
      contentType: 'image/jpeg',
    );
    return armazenado.url;
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
          child: Row(
            children: [
              Icon(
                BuildConfig.demoPaymentsEnabled
                    ? Icons.science_outlined
                    : Icons.receipt_long_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  BuildConfig.demoPaymentsEnabled
                      ? 'Plataforma liberada: sem taxa Joga10 e sem cobranca real neste momento.'
                      : 'Pagamentos pelo app estao pausados. Registre apenas pagamentos externos e comprovantes.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
              _linhaResumo('Taxa Joga10 liberada', rateio.totalTaxas),
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
          _linhaResumo('Taxa Joga10 liberada', cobranca.taxaServico),
          _linhaResumo('Total', cobranca.valorTotal, destaque: true),
          if (cobranca.quitado) ...[
            const SizedBox(height: 10),
            _detalhesPagamento(cobranca),
          ],
          if (!cobranca.quitado) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _processandoPagamento
                  ? null
                  : () => _confirmarPagamento(cobranca),
              icon: _processandoPagamento
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_outlined),
              label: Text(
                _processandoPagamento
                    ? 'Confirmando...'
                    : BuildConfig.demoPaymentsEnabled
                        ? 'Pagar / anexar comprovante'
                        : 'Registrar comprovante',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detalhesPagamento(RateioCobranca cobranca) {
    final metodo = cobranca.metodoPagamento;
    final temComprovante = (cobranca.comprovanteUrl ?? '').isNotEmpty;
    if ((metodo ?? '').isEmpty && !temComprovante) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((metodo ?? '').isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(metodo!)),
              ],
            ),
          if (temComprovante) ...[
            if ((metodo ?? '').isNotEmpty) const SizedBox(height: 6),
            const Row(
              children: [
                Icon(
                  Icons.attach_file_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Expanded(child: Text('Comprovante anexado')),
              ],
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
    final descricao = cobranca.taxaServico == 0
        ? formatarMoeda(cobranca.valorQuadra)
        : '${formatarMoeda(cobranca.valorQuadra)} + '
            '${formatarMoeda(cobranca.taxaServico)} taxa';
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
                    descricao,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatarMoeda(cobranca.valorTotal),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if ((cobranca.metodoPagamento ?? '').isNotEmpty)
                    Text(
                      cobranca.metodoPagamento!,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  if ((cobranca.comprovanteUrl ?? '').isNotEmpty)
                    const Text(
                      'Comprovante anexado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

class _MetodoPagamento {
  final String rotulo;

  const _MetodoPagamento(this.rotulo);
}

class _DialogConfigurarRateio extends StatefulWidget {
  final double valorInicial;

  const _DialogConfigurarRateio({
    required this.valorInicial,
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
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.money_off_outlined, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rateio sem taxa enquanto a plataforma estiver liberada.',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
