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
import 'package:joga_10/services/firestore_compat_ids.dart';
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
    final id = await _sessao.usuarioId ?? usuario?.id;
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
    } on StateError catch (erro) {
      _msg(erro.message);
    } catch (_) {
      _msg('Nao foi possivel entrar na partida.');
    }
  }

  Future<void> _sairDaPartida(Partida partida, PartidaMembro membro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da partida?'),
        content: const Text(
          'Sua vaga sera liberada para outro jogador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true || membro.id == null) return;
    try {
      await _repo.removerMembro(
        partidaId: partida.id,
        membroId: membro.id!,
      );
      if (!mounted) return;
      _msg('Voce saiu da partida.');
      _recarregar();
    } on StateError catch (erro) {
      _msg(erro.message);
    } catch (_) {
      _msg('Nao foi possivel sair da partida.');
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

  bool _souOrganizador(Partida partida) {
    final uid = FirestoreCompatIds.usuarioUid;
    if (uid != null && partida.organizadorUid != null) {
      return partida.organizadorUid == uid;
    }
    return _meuId != null && partida.organizadorId == _meuId;
  }

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

  Future<void> _definirCapitao(Partida partida, String equipe) async {
    final candidatos = partida.membros
        .where(
          (membro) =>
              membro.equipe == equipe &&
              membro.id != null &&
              membro.idUser != null,
        )
        .toList();
    if (candidatos.isEmpty) {
      _msg('Adicione ao time um jogador cadastrado no app.');
      return;
    }
    final membroId = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          'Capitão do ${equipe == Equipe.time1 ? 'Time 1' : 'Time 2'}',
        ),
        children: candidatos
            .map(
              (membro) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, membro.id),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    membro.capitao
                        ? Icons.workspace_premium
                        : Icons.person_outline,
                    color:
                        membro.capitao ? AppColors.warning : AppColors.inkMuted,
                  ),
                  title: Text(membro.nome),
                  trailing: membro.capitao
                      ? const Text(
                          'Atual',
                          style: TextStyle(color: AppColors.inkMuted),
                        )
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    );
    if (membroId == null) return;
    try {
      await _repo.definirCapitao(
        partidaId: partida.id,
        equipe: equipe,
        membroId: membroId,
      );
      _msg('Capitão definido.');
      _recarregar();
    } on StateError catch (erro) {
      _msg(erro.message);
    } catch (_) {
      _msg('Não foi possível definir o capitão.');
    }
  }

  Future<void> _abrirEscalacao(
    Partida p, {
    required bool podeAlterar,
    String? equipeEditavel,
    required bool podeAlterarFormato,
  }) async {
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EscalacaoPage(
          partida: p,
          readOnly: !podeAlterar,
          equipeEditavel: equipeEditavel,
          podeAlterarFormato: podeAlterarFormato,
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
          final partidaAberta = p.status == PartidaStatus.agendada ||
              p.status == PartidaStatus.emAndamento;
          final meuNome = _nomeJogador(null);
          final jaEstou = _jaEstouNaPartida(p, _meuId, meuNome);
          final souOrganizador = _souOrganizador(p);
          final meuMembro = p.membroDoUsuario(_meuId);
          final equipeCapitao =
              meuMembro?.capitao == true ? meuMembro?.equipe : null;
          final souParticipante = souOrganizador || meuMembro != null;
          final visitantePublico = p.publica && !souParticipante;
          final podeEditarEscalacao =
              partidaAberta && (souOrganizador || equipeCapitao != null);
          final podeEntrar = p.publica &&
              partidaAberta &&
              _meuId != null &&
              !jaEstou &&
              !_timesCompletos(p);
          final podeSair =
              partidaAberta && !souOrganizador && meuMembro?.id != null;

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
                    _modalidadeInfo(p),
                    _info(
                      p.publica ? Icons.public : Icons.lock_outline,
                      '${VisibilidadePartida.label(p.visibilidade)} · '
                      '${p.publica ? 'visível para todos' : 'somente convidados'}',
                    ),
                    _info(
                      Icons.person_outline,
                      'Dono: ${p.organizadorNome ?? 'Organizador #${p.organizadorId}'}',
                    ),
                    _info(Icons.tag_outlined, 'ID da partida: ${p.id}'),
                    _info(Icons.event, formatarDataHora(p.dataHora)),
                    if (p.duracao != null && p.duracao!.isNotEmpty)
                      _info(Icons.timer_outlined, 'Duracao: ${p.duracao}'),
                    if (p.preco > 0)
                      _info(Icons.payments_outlined, formatarMoeda(p.preco)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _metaChip(
                          Icons.group_outlined,
                          '${p.membros.length}/${p.jogadoresPorTime * 2} jogadores',
                        ),
                        _metaChip(
                          p.publica
                              ? Icons.travel_explore
                              : Icons.verified_user,
                          p.publica ? 'Entrada aberta' : 'Acesso privado',
                        ),
                        _metaChip(
                          Icons.sports_score_outlined,
                          PartidaStatus.label(p.status),
                        ),
                      ],
                    ),
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
              if (!visitantePublico) ...[
                const SizedBox(height: 12),
                _CampoEscalacaoCard(
                  partida: p,
                  podeAlterar: podeEditarEscalacao,
                  equipeEditavel: souOrganizador ? null : equipeCapitao,
                  onTap: () => _abrirEscalacao(
                    p,
                    podeAlterar: podeEditarEscalacao,
                    equipeEditavel: souOrganizador ? null : equipeCapitao,
                    podeAlterarFormato: souOrganizador,
                  ),
                ),
              ],
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
                      onAdd: souOrganizador && partidaAberta
                          ? () => _adicionarMembro(p, Equipe.time1)
                          : null,
                      onDefinirCapitao: souOrganizador && partidaAberta
                          ? () => _definirCapitao(p, Equipe.time1)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Time(
                      titulo: 'Equipe B',
                      cor: AppColors.accent,
                      membros: p.time2,
                      mostrarGols: !p.isVolei,
                      onAdd: souOrganizador && partidaAberta
                          ? () => _adicionarMembro(p, Equipe.time2)
                          : null,
                      onDefinirCapitao: souOrganizador && partidaAberta
                          ? () => _definirCapitao(p, Equipe.time2)
                          : null,
                    ),
                  ),
                ],
              ),
              if (souOrganizador) ...[
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
              ],
              if (podeEntrar) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _entrarNaPartida(p),
                  icon: const Icon(Icons.login_outlined),
                  label: const Text('Entrar nesta partida'),
                ),
              ],
              if (podeSair) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _sairDaPartida(p, meuMembro!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Sair da partida'),
                ),
              ],
              const SizedBox(height: 12),
              if (souOrganizador && partidaAberta)
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

  Widget _modalidadeInfo(Partida partida) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            if (partida.isVolei)
              Image.asset(
                'lib/assets/img/voleibol.png',
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_volleyball,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
              )
            else
              Image.asset(
                'lib/assets/img/futebol.png',
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_soccer,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ModalidadePartida.label(partida.modalidade)} - ${partida.formato}',
                style: const TextStyle(color: AppColors.ink),
              ),
            ),
          ],
        ),
      );

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

  Widget _metaChip(IconData icon, String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              texto,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _CampoEscalacaoCard extends StatelessWidget {
  final Partida partida;
  final bool podeAlterar;
  final String? equipeEditavel;
  final VoidCallback onTap;

  const _CampoEscalacaoCard({
    required this.partida,
    required this.podeAlterar,
    required this.equipeEditavel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texto = podeAlterar
        ? equipeEditavel == null
            ? 'Escalar times (${partida.formato})'
            : 'Montar ${equipeEditavel == Equipe.time1 ? 'Time 1' : 'Time 2'}'
        : 'Ver escalação (${partida.formato})';

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
                            ? 'lib/assets/img/voleibol.png'
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
  final VoidCallback? onAdd;
  final VoidCallback? onDefinirCapitao;

  const _Time({
    required this.titulo,
    required this.cor,
    required this.membros,
    required this.mostrarGols,
    required this.onAdd,
    required this.onDefinirCapitao,
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
                    if (m.capitao)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: 'Capitão',
                          child: Icon(
                            Icons.workspace_premium,
                            size: 18,
                            color: AppColors.warning,
                          ),
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
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt),
              label: const Text(
                'Adicionar jogador',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (onDefinirCapitao != null)
            TextButton.icon(
              onPressed: onDefinirCapitao,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(
                membros.any((membro) => membro.capitao)
                    ? 'Trocar capitão'
                    : 'Definir capitão',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
