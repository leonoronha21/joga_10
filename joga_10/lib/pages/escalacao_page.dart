import 'package:flutter/material.dart';

import 'package:joga_10/model/Partida.dart';
import 'package:joga_10/model/PartidaMembro.dart';
import 'package:joga_10/repositories/partida_repository.dart';
import 'package:joga_10/theme/app_colors.dart';
import 'package:joga_10/util/formacoes.dart';

/// Jogador editável. x/y normalizados (0..1) quando em campo; < 0 = no banco.
class _Jogador {
  final int id;
  final String nome;
  String equipe;
  double x;
  double y;
  _Jogador({
    required this.id,
    required this.nome,
    required this.equipe,
    required this.x,
    required this.y,
  });

  bool get emCampo => x >= 0 && y >= 0;
}

class EscalacaoPage extends StatefulWidget {
  final Partida partida;
  final bool readOnly; // escalação congelada (partida finalizada/cancelada)
  const EscalacaoPage({
    super.key,
    required this.partida,
    this.readOnly = false,
  });

  @override
  State<EscalacaoPage> createState() => _EscalacaoPageState();
}

class _EscalacaoPageState extends State<EscalacaoPage> {
  final _repo = PartidaRepository();
  final _pitchKey = GlobalKey();

  late String _formato;
  late String _formacaoTime1;
  late String _formacaoTime2;
  late List<_Jogador> _jogadores;
  String _time = Equipe.time1;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.partida;
    _formato = p.formato;
    _formacaoTime1 =
        p.formacaoTime1 ?? Formacoes.doFormato(_formato).first.nome;
    _formacaoTime2 =
        p.formacaoTime2 ?? Formacoes.doFormato(_formato).first.nome;
    // Mantém posições salvas; quem não tem posição começa no banco (x/y = -1).
    _jogadores = p.membros
        .where((m) => m.id != null)
        .map((m) => _Jogador(
              id: m.id!,
              nome: m.nome,
              equipe: m.equipe,
              x: m.posX ?? -1,
              y: m.posY ?? -1,
            ))
        .toList();
  }

  List<_Jogador> get _campo =>
      _jogadores.where((j) => j.equipe == _time && j.emCampo).toList();
  List<_Jogador> get _banco =>
      _jogadores.where((j) => j.equipe == _time && !j.emCampo).toList();

  String get _formacaoAtual =>
      _time == Equipe.time1 ? _formacaoTime1 : _formacaoTime2;

  Color get _corTime =>
      _time == Equipe.time1 ? AppColors.accent : AppColors.warning;

  void _aplicarFormacao(String nome) {
    final formacao = Formacoes.buscar(_formato, nome);
    if (formacao == null) return;
    final jogadores = _jogadores.where((j) => j.equipe == _time).toList();
    setState(() {
      if (_time == Equipe.time1) {
        _formacaoTime1 = nome;
      } else {
        _formacaoTime2 = nome;
      }
      for (var i = 0; i < jogadores.length; i++) {
        if (i < formacao.posicoes.length) {
          jogadores[i].x = formacao.posicoes[i].dx;
          jogadores[i].y = formacao.posicoes[i].dy;
        } else {
          // excedentes voltam para o banco
          jogadores[i].x = -1;
          jogadores[i].y = -1;
        }
      }
    });
  }

  void _trocarFormato(String formato) {
    setState(() {
      _formato = formato;
      final presets = Formacoes.doFormato(formato).map((f) => f.nome).toList();
      if (!presets.contains(_formacaoTime1)) _formacaoTime1 = presets.first;
      if (!presets.contains(_formacaoTime2)) _formacaoTime2 = presets.first;
    });
  }

  void _menuJogador(_Jogador j) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (j.emCampo)
              ListTile(
                leading: const Icon(Icons.event_seat_outlined),
                title: const Text('Enviar para o banco'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    j.x = -1;
                    j.y = -1;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text('Mover para ${_outroTime(j.equipe)}'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  j.equipe =
                      j.equipe == Equipe.time1 ? Equipe.time2 : Equipe.time1;
                  j.x = -1;
                  j.y = -1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  String _outroTime(String eq) => eq == Equipe.time1 ? 'Time 2' : 'Time 1';

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final membros = _jogadores
          .map((j) => PartidaMembro(
                id: j.id,
                equipe: j.equipe,
                nome: j.nome,
                posX: j.emCampo ? j.x : null,
                posY: j.emCampo ? j.y : null,
              ))
          .toList();
      await _repo.salvarEscalacao(
        partidaId: widget.partida.id,
        formato: _formato,
        formacaoTime1: _formacaoTime1,
        formacaoTime2: _formacaoTime2,
        membros: membros,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar a escalação.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campo = _campo;
    final banco = _banco;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escalação'),
        actions: [
          if (widget.readOnly)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.lock_outline, color: AppColors.inkMuted),
              ),
            )
          else if (_salvando)
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
      body: Column(
        children: [
          if (widget.readOnly)
            Container(
              width: double.infinity,
              color: AppColors.warning.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('Escalação congelada — partida finalizada',
                      style: TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '5x5', label: Text('5x5')),
                    ButtonSegment(value: '7x7', label: Text('7x7')),
                  ],
                  selected: {_formato},
                  onSelectionChanged:
                      widget.readOnly ? null : (s) => _trocarFormato(s.first),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                              value: Equipe.time1, label: const Text('Time 1')),
                          ButtonSegment(
                              value: Equipe.time2, label: const Text('Time 2')),
                        ],
                        selected: {_time},
                        onSelectionChanged: (s) =>
                            setState(() => _time = s.first),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _formacaoAtual,
                      underline: const SizedBox.shrink(),
                      items: Formacoes.doFormato(_formato)
                          .map((f) => DropdownMenuItem(
                              value: f.nome, child: Text(f.nome)))
                          .toList(),
                      onChanged: widget.readOnly
                          ? null
                          : (v) => v == null ? null : _aplicarFormacao(v),
                    ),
                    IconButton(
                      tooltip: 'Aplicar formação',
                      onPressed: widget.readOnly
                          ? null
                          : () => _aplicarFormacao(_formacaoAtual),
                      icon: const Icon(Icons.auto_fix_high),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth, h = c.maxHeight;
                  return DragTarget<_Jogador>(
                    onAcceptWithDetails: (det) {
                      if (widget.readOnly) return;
                      final box = _pitchKey.currentContext?.findRenderObject()
                          as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(det.offset);
                      setState(() {
                        det.data.x = (local.dx / w).clamp(0.06, 0.94);
                        det.data.y = (local.dy / h).clamp(0.06, 0.94);
                      });
                    },
                    builder: (context, cand, rej) {
                      return Container(
                        key: _pitchKey,
                        foregroundDecoration: cand.isNotEmpty
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white, width: 3),
                              )
                            : null,
                        child: Stack(
                          children: [
                            Positioned.fill(
                                child: CustomPaint(painter: _CampoPainter())),
                            for (final j in campo)
                              Positioned(
                                left: (j.x * w) - 24,
                                top: (j.y * h) - 24,
                                child: GestureDetector(
                                  onLongPress: widget.readOnly
                                      ? null
                                      : () => _menuJogador(j),
                                  onPanUpdate: widget.readOnly
                                      ? null
                                      : (d) => setState(() {
                                            j.x = (j.x + d.delta.dx / w)
                                                .clamp(0.06, 0.94);
                                            j.y = (j.y + d.delta.dy / h)
                                                .clamp(0.06, 0.94);
                                          }),
                                  child:
                                      _ChipJogador(nome: j.nome, cor: _corTime),
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
          _BancoReservas(
            jogadores: banco,
            cor: _corTime,
            onLongPress: _menuJogador,
            readOnly: widget.readOnly,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              widget.readOnly
                  ? 'Escalação salva ao finalizar a partida (somente leitura).'
                  : 'Arraste do banco para o campo · arraste no campo para reposicionar · segure para mais opções',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _BancoReservas extends StatelessWidget {
  final List<_Jogador> jogadores;
  final Color cor;
  final void Function(_Jogador) onLongPress;
  final bool readOnly;
  const _BancoReservas({
    required this.jogadores,
    required this.cor,
    required this.onLongPress,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Text('Banco — ${jogadores.length}',
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          Expanded(
            child: jogadores.isEmpty
                ? const Center(
                    child: Text('Todos os jogadores estão em campo',
                        style:
                            TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: jogadores.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final j = jogadores[i];
                      final chip = _ChipJogador(nome: j.nome, cor: cor);
                      if (readOnly) return chip;
                      return Draggable<_Jogador>(
                        data: j,
                        dragAnchorStrategy: pointerDragAnchorStrategy,
                        feedback:
                            Material(color: Colors.transparent, child: chip),
                        childWhenDragging:
                            Opacity(opacity: 0.3, child: chip),
                        child: GestureDetector(
                          onLongPress: () => onLongPress(j),
                          child: chip,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChipJogador extends StatelessWidget {
  final String nome;
  final Color cor;
  const _ChipJogador({required this.nome, required this.cor});

  @override
  Widget build(BuildContext context) {
    final primeiro = nome.trim().isEmpty ? '?' : nome.trim().split(' ').first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(primeiro,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ],
    );
  }
}

class _CampoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final grama = Paint()..color = const Color(0xFF2E7D32);
    final faixa = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final linha = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(12));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, grama);
    for (var i = 0; i < 8; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(0, h / 8 * i, w, h / 8), faixa);
      }
    }
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(6, 6, w - 12, h - 12), const Radius.circular(8)),
      linha,
    );
    canvas.drawLine(Offset(6, h / 2), Offset(w - 6, h / 2), linha);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.13, linha);
    canvas.drawCircle(Offset(w / 2, h / 2), 3, Paint()..color = Colors.white);

    final areaW = w * 0.5, areaH = h * 0.16;
    canvas.drawRect(Rect.fromLTWH((w - areaW) / 2, 6, areaW, areaH), linha);
    canvas.drawRect(
        Rect.fromLTWH((w - areaW) / 2, h - 6 - areaH, areaW, areaH), linha);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
