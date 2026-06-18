import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:joga_10/application/use_cases/participar_da_partida.dart';
import 'package:joga_10/core/app_dependencies.dart';
import 'package:joga_10/domain/contracts/partida_convite_contract.dart';
import 'package:joga_10/domain/contracts/partida_repository_contract.dart';
import 'package:joga_10/domain/contracts/sessao_contract.dart';
import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/pages/escalacao_page.dart';
import 'package:joga_10/pages/finalizar_partida_page.dart';
import 'package:joga_10/pages/rateio_partida_page.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/contatos.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class PartidaDetalhePage extends StatefulWidget {
  final int partidaId;
  const PartidaDetalhePage({super.key, required this.partidaId});

  @override
  State<PartidaDetalhePage> createState() => _PartidaDetalhePageState();
}

class _PartidaDetalhePageState extends State<PartidaDetalhePage> {
  late final PartidaRepositoryContract _repo;
  late final SessaoContract _sessao;
  late final PartidaConviteContract _convites;
  late final ParticiparDaPartida _participar;
  Future<Partida?>? _futuro;
  int? _meuId;
  String? _meuNome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futuro != null) return;
    final dependencies = AppDependenciesScope.of(context);
    _repo = dependencies.partidas;
    _sessao = dependencies.sessao;
    _convites = dependencies.convites;
    _participar = dependencies.participarDaPartida;
    _futuro = _repo.buscarPorId(widget.partidaId);
    _carregarSessao();
  }

  Future<void> _carregarSessao() async {
    final usuario = await _sessao.restaurarLocal();
    final id = usuario?.id ?? await _sessao.usuarioId;
    if (!mounted) return;
    setState(() {
      _meuId = id;
      _meuNome = usuario?.nomeCompleto;
    });
  }

  void _recarregar() => setState(() {
        _futuro = _repo.buscarPorId(widget.partidaId);
      });

  Future<void> _adicionarMembro(Partida partida, String equipe) async {
    final jogador = await _perguntarJogador(equipe);
    if (jogador == null || jogador.nome.trim().isEmpty) return;
    try {
      await _repo.adicionarMembro(
        partidaId: widget.partidaId,
        equipe: equipe,
        nome: jogador.nome.trim(),
        telefone: jogador.telefone,
      );
      _recarregar();
    } catch (_) {
      _msg('Nao foi possivel adicionar o jogador.');
      return;
    }

    if (jogador.telefone != null) {
      try {
        final abriu = await _convites.abrirConviteWhatsApp(
          partida,
          telefone: jogador.telefone,
        );
        if (!abriu) throw Exception('WhatsApp indisponivel');
      } catch (_) {
        final link = _convites.linkDaPartida(partida.id).toString();
        await Clipboard.setData(ClipboardData(text: link));
        if (!mounted) return;
        _msg(
            'Jogador adicionado. Nao foi possivel abrir o WhatsApp; link copiado.');
      }
    }
  }

  Future<void> _entrarNaPartida(Partida partida) async {
    try {
      final participacao = await _participar.execute(partida);
      if (!mounted) return;
      final mensagem = switch (participacao.resultado) {
        ResultadoParticipacao.requerLogin =>
          'Entre na sua conta para participar da partida.',
        ResultadoParticipacao.jaParticipa => 'Voce ja esta nessa partida.',
        ResultadoParticipacao.timesCompletos => 'Os times ja estao completos.',
        ResultadoParticipacao.sucesso => 'Voce entrou na partida.',
      };
      if (participacao.resultado != ResultadoParticipacao.sucesso) {
        _msg(mensagem);
        return;
      }
      setState(() {
        _meuId = participacao.usuarioId;
        _meuNome = participacao.nome;
      });
      _msg(mensagem);
      _recarregar();
    } catch (_) {
      _msg('Nao foi possivel entrar na partida.');
    }
  }

  Future<void> _convidarWhatsApp(Partida partida) async {
    try {
      final abriu = await _convites.abrirConviteWhatsApp(partida);
      if (abriu) return;
      throw Exception('WhatsApp indisponivel');
    } catch (_) {
      final link = _convites.linkDaPartida(partida.id).toString();
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      _msg('Nao foi possivel abrir o WhatsApp. Link copiado.');
    }
  }

  String _nomeJogador(String? nomeSessao) {
    final nome = (nomeSessao ?? _meuNome ?? '').trim();
    return _participar.nomeJogador(_meuId, nome);
  }

  bool _jaEstouNaPartida(Partida partida, int? id, String nome) {
    return _participar.jaParticipa(partida, id, nome);
  }

  bool _timesCompletos(Partida partida) => _participar.timesCompletos(partida);

  Future<PartidaMembro?> _perguntarJogador(String equipe) {
    final c = TextEditingController();
    return showDialog<PartidaMembro>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar jogador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome do jogador'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final contato = await escolherContato();
                    if (contato == null || !mounted) return;
                    Navigator.pop(
                      context,
                      PartidaMembro(
                        equipe: equipe,
                        nome: contato.nome,
                        telefone: contato.telefone,
                      ),
                    );
                  },
                  icon: const Icon(Icons.contacts_outlined, size: 18),
                  label: const Text('Selecionar contato e convidar'),
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
            onPressed: () => Navigator.pop(
              context,
              PartidaMembro(equipe: equipe, nome: c.text.trim()),
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizar(Partida p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FinalizarPartidaPage(partida: p)),
    );
    if (ok == true) _recarregar();
  }

  Future<void> _abrirEscalacao(Partida p, bool podeAlterar) async {
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EscalacaoPage(
          partida: p,
          readOnly: !podeAlterar,
        ),
      ),
    );
    if (mudou == true) _recarregar();
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da partida')),
      body: FutureBuilder<Partida?>(
        future: _futuro!,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final p = snap.data;
          if (p == null) {
            return const EmptyState(
              icone: Icons.error_outline,
              titulo: 'Partida nao encontrada',
              mensagem:
                  'O convite pode ter expirado ou você precisa entrar com sua '
                  'conta Google para abrir partidas compartilhadas.',
            );
          }
          final podeAlterar = p.status == PartidaStatus.agendada ||
              p.status == PartidaStatus.emAndamento;
          final meuNome = _nomeJogador(null);
          final jaEstou = _jaEstouNaPartida(p, _meuId, meuNome);
          final podeEntrar = p.publica &&
              podeAlterar &&
              _meuId != null &&
              !jaEstou &&
              !_timesCompletos(p);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.estabelecimentoNome ??
                                p.quadraNome ??
                                'Partida #${p.id}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusBadge(p.status),
                      ],
                    ),
                    if (p.quadraNome != null &&
                        p.estabelecimentoNome != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.estabelecimentoNome!,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _info(
                      p.isVolei ? Icons.sports_volleyball : Icons.sports_soccer,
                      '${ModalidadePartida.label(p.modalidade)} · ${p.formato}',
                    ),
                    _info(
                      p.publica ? Icons.public : Icons.lock_outline,
                      '${VisibilidadePartida.label(p.visibilidade)} · '
                      '${p.publica ? 'visível para todos' : 'somente convidados'}',
                    ),
                    _info(Icons.tag_outlined, 'ID da partida: ${p.id}'),
                    _info(Icons.event, formatarDataHora(p.dataHora)),
                    if (p.duracao != null && p.duracao!.isNotEmpty)
                      _info(Icons.timer_outlined, 'Duracao: ${p.duracao}'),
                    if (p.preco > 0)
                      _info(Icons.payments_outlined, formatarMoeda(p.preco)),
                    if (p.temPlacar) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'PLACAR FINAL',
                              style: TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Equipe A  ',
                                  style: TextStyle(color: AppColors.inkMuted),
                                ),
                                Text(
                                  '${p.placarTime1}  x  ${p.placarTime2}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  '  Equipe B',
                                  style: TextStyle(color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CampoEscalacaoCard(
                partida: p,
                podeAlterar: podeAlterar,
                onTap: () => _abrirEscalacao(p, podeAlterar),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Time(
                      titulo: 'Equipe A',
                      cor: AppColors.info,
                      membros: p.time1,
                      mostrarGols: !p.isVolei,
                      onAdd: () => _adicionarMembro(p, Equipe.time1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Time(
                      titulo: 'Equipe B',
                      cor: AppColors.accent,
                      membros: p.time2,
                      mostrarGols: !p.isVolei,
                      onAdd: () => _adicionarMembro(p, Equipe.time2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _convidarWhatsApp(p),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Convidar via WhatsApp'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RateioPartidaPage(partida: p),
                  ),
                ),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Rateio e pagamentos'),
              ),
              if (podeEntrar) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _entrarNaPartida(p),
                  icon: const Icon(Icons.login_outlined),
                  label: const Text('Entrar nesta partida'),
                ),
              ],
              const SizedBox(height: 12),
              if (podeAlterar)
                OutlinedButton.icon(
                  onPressed: () => _finalizar(p),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Finalizar e cadastrar placar'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.inkMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(texto, style: const TextStyle(color: AppColors.ink)),
            ),
          ],
        ),
      );
}

class _CampoEscalacaoCard extends StatelessWidget {
  final Partida partida;
  final bool podeAlterar;
  final VoidCallback onTap;

  const _CampoEscalacaoCard({
    required this.partida,
    required this.podeAlterar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texto = podeAlterar
        ? 'Escalar time (${partida.formato})'
        : 'Ver escalacao (${partida.formato})';

    return Semantics(
      button: true,
      label: texto,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 14, 26, 38),
                      child: Image.asset(
                        partida.isVolei
                            ? 'lib/assets/img/volei.png'
                            : 'lib/assets/img/futebol.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xD90E2342),
                        ],
                        stops: [0.48, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            podeAlterar
                                ? Icons.grid_view_rounded
                                : Icons.visibility_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            texto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Time extends StatelessWidget {
  final String titulo;
  final Color cor;
  final List<PartidaMembro> membros;
  final bool mostrarGols;
  final VoidCallback onAdd;

  const _Time({
    required this.titulo,
    required this.cor,
    required this.membros,
    required this.mostrarGols,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${membros.length} jogador(es)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (membros.isEmpty)
            const Text(
              'Sem jogadores ainda.',
              style: TextStyle(color: AppColors.inkMuted),
            )
          else
            ...membros.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cor.withValues(alpha: 0.15),
                      child: Text(
                        m.nome.isNotEmpty ? m.nome[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (mostrarGols && m.gols > 0) ...[
                      const Icon(
                        Icons.sports_soccer,
                        size: 15,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${m.gols}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt),
            label: const Text(
              'Adicionar jogador',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
