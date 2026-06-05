import 'package:flutter/material.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/common.dart';

class FinalizarPartidaPage extends StatefulWidget {
  final Partida partida;
  const FinalizarPartidaPage({super.key, required this.partida});

  @override
  State<FinalizarPartidaPage> createState() => _FinalizarPartidaPageState();
}

class _FinalizarPartidaPageState extends State<FinalizarPartidaPage> {
  final _repo = PartidaRepository();
  final Map<int, int> _gols = {}; // membroId -> gols
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    for (final m in widget.partida.membros) {
      if (m.id != null) _gols[m.id!] = m.gols;
    }
  }

  int _placar(String equipe) {
    var total = 0;
    for (final m in widget.partida.membros) {
      if (m.equipe == equipe && m.id != null) total += _gols[m.id!] ?? 0;
    }
    return total;
  }

  Future<void> _finalizar() async {
    setState(() => _salvando = true);
    try {
      await _repo.finalizarComPlacar(
        partidaId: widget.partida.id,
        placarTime1: _placar(Equipe.time1),
        placarTime2: _placar(Equipe.time2),
        golsPorMembro: _gols,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao finalizar a partida.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time1 =
        widget.partida.membros.where((m) => m.equipe == Equipe.time1).toList();
    final time2 =
        widget.partida.membros.where((m) => m.equipe == Equipe.time2).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar partida')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Placar ao vivo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ladoPlacar('Time 1', _placar(Equipe.time1), AppColors.accent),
                const Text('x',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                _ladoPlacar('Time 2', _placar(Equipe.time2), AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _secaoTime('Time 1', time1, AppColors.accent),
          const SizedBox(height: 16),
          _secaoTime('Time 2', time2, AppColors.warning),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _salvando ? null : _finalizar,
            icon: _salvando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4))
                : const Icon(Icons.flag),
            label: const Text('FINALIZAR PARTIDA'),
          ),
        ],
      ),
    );
  }

  Widget _ladoPlacar(String nome, int gols, Color cor) {
    return Column(
      children: [
        Text(nome,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
        const SizedBox(height: 4),
        Text('$gols',
            style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _secaoTime(String titulo, List<PartidaMembro> membros, Color cor) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          if (membros.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sem jogadores.',
                  style: TextStyle(color: AppColors.inkMuted)),
            )
          else
            ...membros.map((m) => _linhaJogador(m, cor)),
        ],
      ),
    );
  }

  Widget _linhaJogador(PartidaMembro m, Color cor) {
    final gols = m.id == null ? 0 : (_gols[m.id!] ?? 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cor.withValues(alpha: 0.15),
            child: Text(m.nome.isNotEmpty ? m.nome[0].toUpperCase() : '?',
                style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(m.nome)),
          _StepperGols(
            valor: gols,
            onChanged: m.id == null
                ? null
                : (v) => setState(() => _gols[m.id!] = v),
          ),
        ],
      ),
    );
  }
}

class _StepperGols extends StatelessWidget {
  final int valor;
  final ValueChanged<int>? onChanged;
  const _StepperGols({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: (onChanged == null || valor <= 0)
              ? null
              : () => onChanged!(valor - 1),
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.inkMuted,
        ),
        SizedBox(
          width: 28,
          child: Text('$valor',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onChanged == null ? null : () => onChanged!(valor + 1),
          icon: const Icon(Icons.add_circle),
          color: AppColors.primary,
        ),
      ],
    );
  }
}
