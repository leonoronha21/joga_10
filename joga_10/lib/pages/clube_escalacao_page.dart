import 'package:flutter/material.dart';

import 'package:joga_10/model/Clube.dart';
import 'package:joga_10/model/ClubeJogador.dart';
import 'package:joga_10/repositories/campeonato_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/widgets/campo_futebol.dart';
import 'package:joga_10/widgets/common.dart';

class _Peca {
  final int id;
  final String nome;
  final String? legenda;
  double x;
  double y;
  _Peca({
    required this.id,
    required this.nome,
    this.legenda,
    required this.x,
    required this.y,
  });
  bool get emCampo => x >= 0 && y >= 0;
}

class ClubeEscalacaoPage extends StatefulWidget {
  final Clube clube;
  const ClubeEscalacaoPage({super.key, required this.clube});

  @override
  State<ClubeEscalacaoPage> createState() => _ClubeEscalacaoPageState();
}

class _ClubeEscalacaoPageState extends State<ClubeEscalacaoPage> {
  final _repo = CampeonatoRepository();
  final _pitchKey = GlobalKey();
  List<_Peca>? _pecas;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final elenco = await _repo.listarElenco(widget.clube.id);
    if (!mounted) return;
    setState(() {
      _pecas = elenco
          .map((j) => _Peca(
                id: j.id,
                nome: j.nome,
                legenda: j.numero?.toString(),
                x: j.posX ?? -1,
                y: j.posY ?? -1,
              ))
          .toList();
    });
  }

  Future<void> _salvar() async {
    final pecas = _pecas ?? [];
    setState(() => _salvando = true);
    try {
      final jogadores = pecas
          .map((p) => ClubeJogador(
                id: p.id,
                clubeId: widget.clube.id,
                nome: p.nome,
                posX: p.emCampo ? p.x : null,
                posY: p.emCampo ? p.y : null,
              ))
          .toList();
      await _repo.salvarEscalacaoClube(jogadores);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escalação do time salva!')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pecas = _pecas;
    final cor = widget.clube.corValue;
    return Scaffold(
      appBar: AppBar(
        title: Text('Escalação · ${widget.clube.nome}'),
        actions: [
          if (_salvando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _salvar, child: const Text('Salvar')),
        ],
      ),
      body: pecas == null
          ? const LoadingView()
          : pecas.isEmpty
              ? const EmptyState(
                  icone: Icons.groups_outlined,
                  titulo: 'Elenco vazio',
                  mensagem: 'Cadastre jogadores no elenco para escalá-los.',
                )
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth, h = c.maxHeight;
                            return DragTarget<_Peca>(
                              onAcceptWithDetails: (det) {
                                final box = _pitchKey.currentContext
                                    ?.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final local = box.globalToLocal(det.offset);
                                setState(() {
                                  det.data.x =
                                      (local.dx / w).clamp(0.06, 0.94);
                                  det.data.y =
                                      (local.dy / h).clamp(0.06, 0.94);
                                });
                              },
                              builder: (context, cand, rej) {
                                return Container(
                                  key: _pitchKey,
                                  foregroundDecoration: cand.isNotEmpty
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white, width: 3),
                                        )
                                      : null,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                          child: CustomPaint(
                                              painter: CampoFutebolPainter())),
                                      for (final p
                                          in pecas.where((p) => p.emCampo))
                                        Positioned(
                                          left: (p.x * w) - 24,
                                          top: (p.y * h) - 24,
                                          child: GestureDetector(
                                            onLongPress: () => setState(() {
                                              p.x = -1;
                                              p.y = -1;
                                            }),
                                            onPanUpdate: (d) => setState(() {
                                              p.x = (p.x + d.delta.dx / w)
                                                  .clamp(0.06, 0.94);
                                              p.y = (p.y + d.delta.dy / h)
                                                  .clamp(0.06, 0.94);
                                            }),
                                            child: ChipCampo(
                                                nome: p.nome,
                                                cor: cor,
                                                legenda: p.legenda),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    _banco(pecas.where((p) => !p.emCampo).toList(), cor),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Text(
                        'Arraste do banco para o campo · arraste para reposicionar · segure para tirar',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.inkMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _banco(List<_Peca> banco, Color cor) {
    return Container(
      height: 104,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Banco — ${banco.length}',
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          Expanded(
            child: banco.isEmpty
                ? const Center(
                    child: Text('Todos em campo',
                        style: TextStyle(
                            color: AppColors.inkMuted, fontSize: 12)),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: banco.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final p = banco[i];
                      final chip = ChipCampo(
                          nome: p.nome, cor: cor, legenda: p.legenda);
                      return Draggable<_Peca>(
                        data: p,
                        dragAnchorStrategy: pointerDragAnchorStrategy,
                        feedback:
                            Material(color: Colors.transparent, child: chip),
                        childWhenDragging: Opacity(opacity: 0.3, child: chip),
                        child: chip,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
