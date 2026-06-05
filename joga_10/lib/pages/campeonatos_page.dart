import 'package:flutter/material.dart';

import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/Confronto.dart';
import 'package:joga_10/pages/agendar_confronto_page.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/services/sessao.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/format.dart';
import 'package:joga_10/widgets/common.dart';

class CampeonatosPage extends StatefulWidget {
  const CampeonatosPage({super.key});

  @override
  State<CampeonatosPage> createState() => _CampeonatosPageState();
}

class _CampeonatosPageState extends State<CampeonatosPage> {
  final _repo = CampeonatoRepository();
  bool _verTimes = true;
  List<Clube> _clubes = [];
  List<Confronto> _confrontos = [];
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
      final clubes = await _repo.listarClubes();
      final confrontos = await _repo.listarConfrontos();
      if (mounted) {
        setState(() {
          _clubes = clubes;
          _confrontos = confrontos;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
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
                  decoration: const InputDecoration(labelText: 'Nome do time'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cidade,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cor do escudo',
                      style: TextStyle(
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _cores.map((c) {
                    final selecionada = c == cor;
                    final color =
                        Color(0xFF000000 | int.parse(c.replaceAll('#', ''), radix: 16));
                    return GestureDetector(
                      onTap: () => setLocal(() => cor = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selecionada ? AppColors.ink : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selecionada
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
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
      await _repo.criarClube(
        nome: nome.text,
        cidade: cidade.text,
        cor: cor,
        donoId: Sessao.instance.atual?.id,
      );
      _carregar();
    }
  }

  Future<void> _agendar() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AgendarConfrontoPage()),
    );
    if (criou == true) _carregar();
  }

  Future<void> _opcoesConfronto(Confronto c) async {
    if (c.status != ConfrontoStatus.agendado) return;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.scoreboard_outlined),
              title: const Text('Registrar placar'),
              onTap: () {
                Navigator.pop(context);
                _registrarPlacar(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              title: const Text('Cancelar jogo'),
              onTap: () async {
                Navigator.pop(context);
                await _repo.cancelar(c.id);
                _carregar();
              },
            ),
          ],
        ),
      ),
    );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.clubeCasaNome, textAlign: TextAlign.center),
                  TextField(
                    controller: casa,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('x', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.clubeVisitanteNome, textAlign: TextAlign.center),
                  TextField(
                    controller: visitante,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ],
              ),
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
        c.id,
        int.tryParse(casa.text) ?? 0,
        int.tryParse(visitante.text) ?? 0,
      );
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _verTimes ? _criarTime : _agendar,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(_verTimes ? Icons.add : Icons.event_available),
        label: Text(_verTimes ? 'Novo time' : 'Agendar jogo'),
      ),
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Campeonatos',
            subtitulo: 'Times da cidade e amistosos',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _filtro('Times', _verTimes, () => setState(() => _verTimes = true)),
                const SizedBox(width: 10),
                _filtro('Jogos', !_verTimes, () => setState(() => _verTimes = false)),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _carregar,
              child: _carregando
                  ? const LoadingView()
                  : (_verTimes ? _listaTimes() : _listaJogos()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaTimes() {
    if (_clubes.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        EmptyState(
            icone: Icons.shield_outlined, titulo: 'Nenhum time cadastrado'),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _clubes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = _clubes[i];
        return AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.corValue,
                child: Text(
                  c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    if (c.cidade != null && c.cidade!.isNotEmpty)
                      Text(c.cidade!,
                          style: const TextStyle(
                              color: AppColors.inkMuted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _listaJogos() {
    if (_confrontos.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        EmptyState(
            icone: Icons.event_busy, titulo: 'Nenhum jogo agendado'),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _confrontos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ConfrontoCard(
        confronto: _confrontos[i],
        onTap: () => _opcoesConfronto(_confrontos[i]),
      ),
    );
  }

  Widget _filtro(String label, bool ativo, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: ativo ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: ativo ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _ConfrontoCard extends StatelessWidget {
  final Confronto confronto;
  final VoidCallback onTap;
  const _ConfrontoCard({required this.confronto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = confronto;
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.inkMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(c.tipo == 'OFICIAL' ? 'Oficial' : 'Amistoso',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              StatusBadgeGenerico(
                  texto: ConfrontoStatus.label(c.status),
                  cor: c.status == ConfrontoStatus.realizado
                      ? AppColors.success
                      : c.status == ConfrontoStatus.cancelado
                          ? AppColors.danger
                          : AppColors.info),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ladoClube(c.clubeCasaNome, c.corCasa),
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
              _ladoClube(c.clubeVisitanteNome, c.corVisitante),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 4),
              Text(formatarDataHora(c.dataHora),
                  style: const TextStyle(
                      color: AppColors.inkMuted, fontSize: 12)),
              if (c.local != null && c.local!.isNotEmpty) ...[
                const SizedBox(width: 10),
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(c.local!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _ladoClube(String nome, Color cor) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cor,
            child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Text(nome,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
