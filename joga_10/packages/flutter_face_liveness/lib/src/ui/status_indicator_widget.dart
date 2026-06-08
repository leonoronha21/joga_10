import 'package:flutter/material.dart';
import '../models/detection_status.dart';

/// Animated pill badge at the top of the camera view.
class StatusIndicatorWidget extends StatelessWidget {
  const StatusIndicatorWidget({super.key, required this.status});
  final DetectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.40)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 12,
                spreadRadius: 0),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == DetectionStatus.initializing)
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String label, Color color) _resolve() {
    switch (status) {
      case DetectionStatus.initializing:
        return ('INICIANDO', Colors.white54);
      case DetectionStatus.noFace:
        return ('POSICIONE O ROSTO', const Color(0xFFF59E0B));
      case DetectionStatus.multipleFaces:
        return ('APENAS UMA PESSOA', const Color(0xFFF59E0B));
      case DetectionStatus.faceTooFar:
        return ('APROXIME O ROSTO', const Color(0xFFF59E0B));
      case DetectionStatus.faceTooClose:
        return ('AFASTE O ROSTO', const Color(0xFFF59E0B));
      case DetectionStatus.faceNotCentered:
        return ('CENTRALIZE O ROSTO', const Color(0xFFF59E0B));
      case DetectionStatus.lowLight:
        return ('POUCA LUZ', const Color(0xFFF59E0B));
      case DetectionStatus.overExposed:
        return ('LUZ MUITO FORTE', const Color(0xFFF59E0B));
      case DetectionStatus.blurry:
        return ('FIQUE PARADO', const Color(0xFFF59E0B));
      case DetectionStatus.fakeDetected:
        return ('ROSTO NÃO CONFIRMADO', const Color(0xFFEF4444));
      case DetectionStatus.ready:
        return ('PREPARADO', const Color(0xFF4F6BF4));
      case DetectionStatus.actionInProgress:
        return ('VERIFICANDO', const Color(0xFF4F6BF4));
      case DetectionStatus.completed:
        return ('CONFIRMADO', const Color(0xFF10B981));
      case DetectionStatus.failed:
        return ('NÃO CONFIRMADO', const Color(0xFFEF4444));
    }
  }
}
