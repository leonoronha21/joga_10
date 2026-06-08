import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/detection_status.dart';
import '../models/face_data.dart';

/// Draws the animated face-guide oval, pulsing ring, and corner brackets.
class FaceOverlayPainter extends CustomPainter {
  const FaceOverlayPainter({
    required this.status,
    required this.animationValue,
    required this.isDark,
    this.faceData,
    this.previewSize,
    this.isFrontCamera = true,
  });

  final DetectionStatus status;
  final double animationValue;
  final bool isDark;
  final FaceData? faceData;
  final Size? previewSize;
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    _drawScrim(canvas, size);
    _drawPulseRing(canvas, size);
    _drawOvalBorder(canvas, size);
    _drawCornerBrackets(canvas, size);
  }

  void _drawScrim(Canvas canvas, Size size) {
    final oval = _ovalRect(size);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha:isDark ? 0.62 : 0.45)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawPulseRing(Canvas canvas, Size size) {
    if (status.isError) return;
    final oval    = _ovalRect(size);
    final expand  = 6.0 + animationValue * 16.0;
    final opacity = (1.0 - animationValue) * 0.45;
    canvas.drawOval(
      oval.inflate(expand),
      Paint()
        ..color = _borderColor().withValues(alpha:opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawOvalBorder(Canvas canvas, Size size) {
    final oval  = _ovalRect(size);
    final color = _borderColor();

    // Rotating sweep gradient gives a shimmer/scanning feel
    final shader = SweepGradient(
      colors: [
        color.withValues(alpha:0.9),
        color.withValues(alpha:0.3),
        color.withValues(alpha:0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(animationValue * math.pi * 2),
    ).createShader(oval);

    canvas.drawOval(
      oval,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawCornerBrackets(Canvas canvas, Size size) {
    final oval  = _ovalRect(size);
    final color = _borderColor();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const span = math.pi / 7;
    for (int i = 0; i < 4; i++) {
      final center = math.pi / 2 * i;
      canvas.drawArc(oval, center - span / 2, span, false, paint);
    }
  }

  Rect _ovalRect(Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final rx = size.width * 0.38;
    final ry = size.height * 0.24;
    return Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);
  }

  Color _borderColor() {
    if (status.isError)   return const Color(0xFFEF4444);
    if (status.isSuccess) return const Color(0xFF10B981);
    if (status == DetectionStatus.actionInProgress) {
      return Color.lerp(
        const Color(0xFF4F6BF4),
        const Color(0xFF06B6D4),
        animationValue,
      )!;
    }
    return Colors.white;
  }

  @override
  bool shouldRepaint(FaceOverlayPainter old) =>
      old.status != status ||
      old.animationValue != animationValue ||
      old.faceData != faceData ||
      old.isDark != isDark;
}
