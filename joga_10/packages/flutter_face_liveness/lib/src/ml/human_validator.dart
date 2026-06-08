import '../models/face_data.dart';
import '../models/frame_quality.dart';
import 'anti_spoof_engine.dart';

export 'anti_spoof_engine.dart' show AntiSpoofResult;

/// Thin facade that delegates to [AntiSpoofEngine].
/// Kept for backward compatibility — existing code using [HumanValidator]
/// continues to work unchanged.
class HumanValidationResult {
  const HumanValidationResult({
    required this.isValid,
    required this.confidence,
    this.rejectionReason,
  });

  final bool isValid;
  final double confidence;
  final String? rejectionReason;
}

class HumanValidator {
  final AntiSpoofEngine _engine = AntiSpoofEngine();

  HumanValidationResult validate(FaceData face, {FrameQuality? quality}) {
    final result = _engine.validate(face, quality: quality);
    return HumanValidationResult(
      isValid: result.isReal,
      confidence: result.confidence,
      rejectionReason: result.rejectionReason,
    );
  }

  void reset() => _engine.reset();
}
