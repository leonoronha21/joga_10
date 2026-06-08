import '../models/detection_status.dart';
import '../models/face_data.dart';
import '../models/frame_quality.dart';
import '../models/liveness_config.dart';

/// Validates per-frame camera quality and face geometry.
///
/// Returns a [DetectionStatus] issue, or null when everything is acceptable.
class CameraValidator {
  const CameraValidator(this.config);

  final LivenessConfig config;

  /// Check frame quality (brightness, blur) before face-level checks.
  DetectionStatus? validateQuality(FrameQuality quality) {
    if (config.enableBrightnessCheck) {
      if (quality.brightness < config.brightnessMin) {
        return DetectionStatus.lowLight;
      }
      if (quality.brightness > config.brightnessMax) {
        return DetectionStatus.overExposed;
      }
    }

    if (config.enableBlurDetection) {
      if (quality.blurScore < config.blurThreshold) {
        return DetectionStatus.blurry;
      }
    }

    return null;
  }

  /// Validate a single detected face.
  DetectionStatus? validateFace(FaceData face) {
    // Distance
    if (face.faceAreaRatio < config.faceTooFarRatio) {
      return DetectionStatus.faceTooFar;
    }
    if (face.faceAreaRatio > config.faceTooCloseRatio) {
      return DetectionStatus.faceTooClose;
    }

    // Centering — generous bounds to account for BoxFit.cover crop
    final norm = face.normalizedBoundingBox;
    final cx   = (norm.left + norm.right) / 2;
    final cy   = (norm.top + norm.bottom) / 2;
    if (cx < 0.10 || cx > 0.90 || cy < 0.05 || cy > 0.95) {
      return DetectionStatus.faceNotCentered;
    }

    return null;
  }
}
