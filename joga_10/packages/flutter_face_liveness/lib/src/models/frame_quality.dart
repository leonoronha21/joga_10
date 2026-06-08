import 'package:flutter/foundation.dart';

/// Quality metrics computed from a raw camera frame in a background isolate.
///
/// Computed once per frame alongside YUV→NV21 conversion so there is no extra
/// overhead on the main thread.
@immutable
class FrameQuality {
  const FrameQuality({
    required this.brightness,
    required this.blurScore,
    required this.frameHash,
  });

  /// Average Y-plane luminance, normalised to [0.0, 1.0].
  ///   < 0.12 → genuinely dark room
  ///   > 0.92 → over-exposed / direct sun
  final double brightness;

  /// Variance of Y-plane pixel values on a sub-sampled grid.
  /// Higher = sharper. < 80 is typically blurry.
  final double blurScore;

  /// Fast FNV-1a hash of sampled Y-plane bytes.
  /// Used for duplicate / static-image detection.
  final int frameHash;

  bool get isTooDark => brightness < 0.12;
  bool get isOverExposed => brightness > 0.92;
  bool get isBlurry => blurScore < 80.0;

  @override
  String toString() =>
      'FrameQuality(brightness: ${brightness.toStringAsFixed(2)}, '
      'blur: ${blurScore.toStringAsFixed(1)}, hash: $frameHash)';
}
