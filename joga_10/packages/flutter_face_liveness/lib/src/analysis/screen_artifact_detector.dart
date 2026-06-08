import 'dart:io' show Platform;

import '../ml/face_detector_service.dart';

// ignore_for_file: constant_identifier_names

/// On-device screen / display-surface attack detector.
///
/// Three independent signals computed purely from raw pixel data:
///
///   S1 – Specular highlight density
///        LCD/OLED screens and glass produce bright rectangular reflections.
///        Real face skin is matte-diffuse.
///        Metric: fraction of face-crop pixels with luma > 235.
///        Score 1.0 = no speculars (real face). Score 0.0 = many bright spots.
///
///   S2 – Skin chromatic warmth  (iOS BGRA only; skipped on Android)
///        Human skin is red-dominant (R > G > B in natural light).
///        LCD/OLED backlights have a characteristic blue boost.
///        Metric: mean (R − B) / R across face-crop pixels.
///        Score 1.0 = warm skin tone. Score 0.0 = cold/neutral (screen).
///
///   S3 – Temporal face-crop luma stability
///        Screen backlights are nearly perfectly constant.
///        Natural room lighting fluctuates from shadows, ambient changes,
///        background motion, and breathing-induced micro-shadowing.
///        Metric: temporal variance of mean face-crop luma over 12+ frames.
///        Score 1.0 = fluctuating (real). Score 0.0 = dead-stable (screen).
///
/// Usage:
///   ```dart
///   final detector = ScreenArtifactDetector();
///   // Call once per frame with a detected face:
///   detector.processFrame(rawFrame, faceData.boundingBox);
///   // Read rolling score (null until 12 frames collected):
///   final score = detector.liveScore; // 0.0 = screen, 1.0 = real
///   // Session end:
///   detector.reset();
///   ```
class ScreenArtifactDetector {
  static const int    _historySize      = 60;
  static const int    _minFrames        = 12;
  static const int    _sampleStep       = 4;   // sample every 4th pixel
  static const double _specularThresh   = 235;  // luma > this = specular
  static const double _specularMaxFrac  = 0.08; // >8% speculars → score 0
  static const double _warmthThreshold  = 0.12; // (R-B)/R expected for real skin
  static const double _stabilityTarget  = 0.001; // variance to map 0→1 range

  final List<double> _lumaHistory   = [];
  final List<double> _warmthHistory = [];

  double? _specularsScore;
  double? _warmthScore;
  double? _stabilityScore;

  // ── Public getters ──────────────────────────────────────────────────────────

  double? get specularsScore  => _specularsScore;
  double? get warmthScore     => _warmthScore;
  double? get stabilityScore  => _stabilityScore;

  /// Combined anti-screen score: 0.0 = screen/fake, 1.0 = real face.
  /// Returns null until [_minFrames] frames have been processed.
  double? get liveScore {
    final s = _specularsScore;
    if (s == null) return null;
    final b = _stabilityScore;
    final w = _warmthScore;
    double sum = s * 0.40;
    double wt  = 0.40;
    if (b != null) { sum += b * 0.40; wt += 0.40; }
    if (w != null) { sum += w * 0.20; wt += 0.20; }
    return (sum / wt).clamp(0.0, 1.0);
  }

  // ── Per-frame processing ────────────────────────────────────────────────────

  void processFrame(RawFrameData frame, ({double left, double top, double right, double bottom}) bbox) {
    if (Platform.isIOS) {
      _processIos(frame, bbox);
    } else {
      _processAndroid(frame, bbox);
    }
  }

  void reset() {
    _lumaHistory.clear();
    _warmthHistory.clear();
    _specularsScore = null;
    _warmthScore    = null;
    _stabilityScore = null;
  }

  // ── iOS – BGRA8888 ──────────────────────────────────────────────────────────

  void _processIos(RawFrameData frame, ({double left, double top, double right, double bottom}) bbox) {
    final bytes = frame.imageBytes;
    final w = frame.imageWidth;
    final h = frame.imageHeight;

    final x0 = bbox.left.toInt().clamp(0, w - 1);
    final y0 = bbox.top.toInt().clamp(0, h - 1);
    final x1 = bbox.right.toInt().clamp(0, w);
    final y1 = bbox.bottom.toInt().clamp(0, h);

    int    n         = 0;
    int    speculars = 0;
    double lumaSum   = 0.0;
    double redSum    = 0.0;
    double blueSum   = 0.0;

    for (int y = y0; y < y1; y += _sampleStep) {
      for (int x = x0; x < x1; x += _sampleStep) {
        final p  = (y * w + x) * 4;
        final bv = bytes[p    ];
        final gv = bytes[p + 1];
        final rv = bytes[p + 2];
        final luma = (77 * rv + 150 * gv + 29 * bv) >> 8;
        lumaSum  += luma;
        redSum   += rv;
        blueSum  += bv;
        if (luma > _specularThresh) speculars++;
        n++;
      }
    }
    if (n == 0) return;

    final meanLuma = lumaSum / n;
    final meanRed  = redSum  / n;
    final meanBlue = blueSum / n;

    // S1
    _specularsScore = (1.0 - (speculars / n / _specularMaxFrac).clamp(0.0, 1.0));

    // S2 – skin warmth (R − B) / R; real face ≥ 0.12
    final warmth = meanRed > 1.0 ? (meanRed - meanBlue) / meanRed : 0.0;
    _warmthHistory.add(warmth);
    if (_warmthHistory.length > _historySize) _warmthHistory.removeAt(0);
    if (_warmthHistory.length >= 5) {
      final avg = _warmthHistory.reduce((a, b) => a + b) / _warmthHistory.length;
      _warmthScore = (avg / _warmthThreshold).clamp(0.0, 1.0);
    }

    // S3
    _updateStability(meanLuma / 255.0);
  }

  // ── Android – NV21 ─────────────────────────────────────────────────────────

  void _processAndroid(RawFrameData frame, ({double left, double top, double right, double bottom}) bbox) {
    final bytes = frame.imageBytes;
    final iw    = frame.imageWidth;
    final ih    = frame.imageHeight;

    late double nl, nt, nr, nb;
    switch (frame.sensorOrientation) {
      case 270:
        nl = bbox.top;              nt = ih - 1 - bbox.right;
        nr = bbox.bottom;           nb = ih - 1 - bbox.left;
      case 90:
        nl = iw - 1 - bbox.bottom;  nt = bbox.left;
        nr = iw - 1 - bbox.top;     nb = bbox.right;
      case 180:
        nl = iw - 1 - bbox.right;   nt = ih - 1 - bbox.bottom;
        nr = iw - 1 - bbox.left;    nb = ih - 1 - bbox.top;
      default:
        nl = bbox.left;  nt = bbox.top;
        nr = bbox.right; nb = bbox.bottom;
    }

    final x0 = nl.toInt().clamp(0, iw - 1);
    final y0 = nt.toInt().clamp(0, ih - 1);
    final x1 = nr.toInt().clamp(0, iw);
    final y1 = nb.toInt().clamp(0, ih);

    int    n         = 0;
    int    speculars = 0;
    double lumaSum   = 0.0;

    for (int y = y0; y < y1; y += _sampleStep) {
      for (int x = x0; x < x1; x += _sampleStep) {
        final idx = y * iw + x;
        if (idx >= iw * ih) continue;
        final luma = bytes[idx] & 0xFF;
        lumaSum += luma;
        if (luma > _specularThresh) speculars++;
        n++;
      }
    }
    if (n == 0) return;

    _specularsScore = (1.0 - (speculars / n / _specularMaxFrac).clamp(0.0, 1.0));
    _updateStability(lumaSum / n / 255.0);
  }

  // ── Temporal stability helper ───────────────────────────────────────────────

  void _updateStability(double normLuma) {
    _lumaHistory.add(normLuma);
    if (_lumaHistory.length > _historySize) _lumaHistory.removeAt(0);
    if (_lumaHistory.length < _minFrames) return;
    final mean = _lumaHistory.reduce((a, b) => a + b) / _lumaHistory.length;
    final variance = _lumaHistory
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) /
        _lumaHistory.length;
    // Map [0, _stabilityTarget] → [0, 1]:
    // variance < 0.0002 → screen; > 0.0005 → natural room lighting
    _stabilityScore = (variance / _stabilityTarget).clamp(0.0, 1.0);
  }
}
