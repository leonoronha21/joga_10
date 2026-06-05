import 'package:flutter/material.dart';

import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/Confronto.dart';
import 'package:joga_10/model/Liga.dart';
import 'package:joga_10/model/LinhaClassificacao.dart';
import 'package:joga_10/pages/agendar_confronto_page.dart';
import 'package:joga_10/pages/clube_detalhe_page.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class LigaDetalhePage extends StatefulWidget {
  final Liga liga;
  const LigaDetalhePage({super.key, required this.liga});

  @override
  State<LigaDetalhePage> createState() => _LigaDetalhePageState();
}

class _LigaDetalhePageState extends State<LigaDetalhePage> {
  final _repo = CampeonatoRepository();

  List<LinhaClassificacao> _tabela = [];
  List<Clube> _times = [];
  List<Confronto> _jogos = [];
  bool _carregando = true;

  static const _cores = [
    '#1B3A6B', '#C0392B', '#27AE60', '#E67E22',
    '#8E44AD', '#16A085', '#2C3E50', '#D4AC0D',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final tabela = await _repo.classificacao(widget.liga.id);
      final times = await _repo.clubesDaLiga(widget.liga.id);
      final jogos = await _repo.confrontosDaLiga(widget.liga.id);
      if (!mounted) return;
      setState(() {
        _tabela = tabela;
        _times = times;
        _jogos = jogos;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ---------- Times ----------
  Future<void> _adicionarTime() async {
    final fora = await _repo.clubesForaDaLiga(widget.liga.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle, color: AppColors.primary),
              title: const Text('Criar novo time'),
              onTap: () {
                Navigator.pop(context);
                _criarTime();
              },
            ),
            if (fora.isNotEmpty) const Divider(height: 1),
            ...fora.map((c) => ListTile(
                  leading: CircleAvatar(
                      radius: 14, backgroundColor: c.corValue),
                  title: Text(c.nome),
                  subtitle: c.cidade != null ? Text(c.cidade!) : null,
                  trailing: const Icon(Icons.add),
                  onTap: () async {
                    Navigator.pop(context);
                    await _repo.adicionarClubeNaLiga(widget.liga.id, c.id);
                    _carregar();
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _criarTime() async {
    final nome = TextEditingController();
    final cidade = TextEditingController();
    String cor = _cores.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Novo time'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nome,
                    decoration:
                        const InputDecoration(labelText: 'Nome do time')),
                const SizedBox(height: 12),
                TextField(
                    controller: cidade,
                    decoration: const InputDecoration(labelText: 'Cidade')),
                const SizedBox(height: 16),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cor do escudo',
                        style: TextStyle(
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _cores.map((c) {
                    final sel = c == cor;
                    final color = Color(
                        0xFF000000 | int.parse(c.replaceAll('#', ''), radix: 16));
                    return GestureDetector(
                      onTap: () => setLocal(() => cor = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: sel ? AppColors.ink : Colors.transparent,
                              width: 3),
                        ),
                        child: sel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Criar')),
          ],
        ),
      ),
    );
    if (ok == true && nome.text.trim().isNotEmpty) {
      final id = await _repo.criarClube(
          nome: nome.text, cidade: cidade.text, cor: cor);
      await _repo.adicionarClubeNaLiga(widget.liga.id, id);
      _carregar();
    }
  }

  // ---------- Jogos ----------
  Future<void> _agendar() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AgendarConfrontoPage(liga: widget.liga)),
    );
    if (criou == true) _carregar();
  }

  Future<void> _registrarPlacar(Confronto c) async {
    final casa = TextEditingController();
    final visitante = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar placar'),
        content: Row(
          children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.clubeCasaNome, textAlign: TextAlign.center),
                TextField(
                    controller: casa,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '0')),
              ]),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child:
                    Text('x', style: TextStyle(fontWeight: FontWeight.w800))),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.clubeVisitanteNome, textAlign: TextAlign.center),
                TextField(
                    controller: visitante,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '0')),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.registrarPlacar(
          c.id, int.tryParse(casa.text) ?? 0, int.tryParse(visitante.text) ?? 0);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.liga.nome),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Classificação'),
              Tab(text: 'Times'),
              Tab(text: 'Jogos'),
            ],
          ),
        ),
        body: _carregando
            ? const LoadingView()
            : TabBarView(
                children: [
                  _abaClassificacao(),
                  _abaTimes(),
                  _abaJogos(),
                ],
              ),
      ),
    );
  }

  // ---------- Aba Classificação ----------
  Widget _abaClassificacao() {
    if (_tabela.isEmpty) {
      return const EmptyState(
          icone: Icons.table_chart_outlined,
          titulo: 'Sem classificação',
          mensagem: 'Adicione times e registre resultados de jogos.');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _linhaCabecalho(),
          ..._tabela.asMap().entries.map((e) => _linhaTabela(e.key + 1, e.value)),
        ],
      ),
    );
  }

  Widget _linhaCabecalho() {
    Widget c(String t, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(t,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(flex: 5, child: const SizedBox()),
          c('P'),
          c('J'),
          c('V'),
          c('E'),
          c('D'),
          c('SG'),
        ],
      ),
    );
  }

  Widget _linhaTabela(int pos, LinhaClassificacao l) {
    Widget num(int v, {bool bold = false}) => Expanded(
          child: Text('$v',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$posº',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.inkMuted)),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(radius: 10, backgroundColor: l.corValue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          num(l.pontos, bold: true),
          num(l.jogos),
          num(l.vitorias),
          num(l.empates),
          num(l.derrotas),
          num(l.saldo),
        ],
      ),
    );
  }

  // ---------- Aba Times ----------
  Widget _abaTimes() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addTime',
        onPressed: _adicionarTime,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add),
        label: const Text('Adicionar time'),
      ),
      body: _times.isEmpty
          ? const EmptyState(
              icone: Icons.shield_outlined,
              titulo: 'Nenhum time na liga',
              mensagem: 'Toque em "Adicionar time".')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: _times.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = _times[i];
                return AppCard(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClubeDetalhePage(clube: c)),
                    );
                    _carregar();
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: c.corValue,
                        child: Text(
                            c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            if (c.cidade != null && c.cidade!.isNotEmpty)
                              Text(c.cidade!,
                                  style: const TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover da liga',
                        onPressed: () async {
                          await _repo.removerClubeDaLiga(widget.liga.id, c.id);
                          _carregar();
                        },
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ---------- Aba Jogos ----------
  Widget _abaJogos() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addJogo',
        onPressed: _times.length < 2 ? null : _agendar,
        backgroundColor:
            _times.length < 2 ? AppColors.inkMuted : AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_available),
        label: const Text('Agendar jogo'),
      ),
      body: _jogos.isEmpty
          ? const EmptyState(
              icone: Icons.event_busy,
              titulo: 'Nenhum jogo',
              mensagem: 'Agende jogos entre os times da liga.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: _jogos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = _jogos[i];
                return _ConfrontoCard(
                  confronto: c,
                  onTap: c.status == ConfrontoStatus.agendado
                      ? () => _registrarPlacar(c)
                      : null,
                );
              },
            ),
    );
  }
}

class _ConfrontoCard extends StatelessWidget {
  final Confronto confronto;
  final VoidCallback? onTap;
  const _ConfrontoCard({required this.confronto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = confronto;
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              StatusBadgeGenerico(
                texto: ConfrontoStatus.label(c.status),
                cor: c.status == ConfrontoStatus.realizado
                    ? AppColors.success
                    : c.status == ConfrontoStatus.cancelado
                        ? AppColors.danger
                        : AppColors.info,
              ),
              const Spacer(),
              Text(formatarData(c.dataHora),
                  style:
                      const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _lado(c.clubeCasaNome, c.corCasa),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: c.temPlacar
                    ? Text('${c.placarCasa}  x  ${c.placarVisitante}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18))
                    : const Text('x',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkMuted)),
              ),
              _lado(c.clubeVisitanteNome, c.corVisitante),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lado(String nome, Color cor) => Expanded(
        child: Column(
          children: [
            CircleAvatar(
                radius: 18,
                backgroundColor: cor,
                child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800))),
            const SizedBox(height: 6),
            Text(nome,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}
