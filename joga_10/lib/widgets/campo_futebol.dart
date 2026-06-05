import 'package:flutter/material.dart';

/// Pinta um campo de futebol (vertical) com áreas, círculo e meio.
class CampoFutebolPainter extends CustomPainter {
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

/// Peça (chip) de jogador no campo/banco: avatar com inicial + nome.
class ChipCampo extends StatelessWidget {
  final String nome;
  final Color cor;
  final String? legenda; // ex.: número ou posição
  const ChipCampo({super.key, required this.nome, required this.cor, this.legenda});

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
              legenda ?? (nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
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
