import 'dart:math' show sqrt, cos, pi;

import '../models/face_data.dart';

// ignore_for_file: constant_identifier_names

/// Face-geometry consistency analyzer.
///
/// Uses ML Kit face landmarks (enabled via [FaceDetectorOptions.enableLandmarks])
/// and Euler angles to derive four independent signals:
///
///   S1 – Eye-open symmetry
///        Real faces have approximately balanced left/right eye open probabilities.
///        A flat printed photo or extreme-angle capture produces large asymmetry.
///
///   S2 – Inter-eye / face-width ratio (requires landmarks)
///        For a frontal real face the distance between eye centres is ~30–45%
///        of the face bounding-box width.  This ratio remains consistent across
///        frames.  Wild swings in the ratio indicate a flat surface at an angle
///        or landmark instability from a compressed video.
///
///   S3 – 3-D depth consistency via cosine law
///        When a real face rotates (non-zero yaw) its projected width shrinks
///        approximately as  W(yaw) ≈ W₀ × cos(yaw).
///        A flat surface (printed photo / screen) stays at constant width
///        regardless of yaw because it has no true depth.
///        Metric: Pearson correlation between observed face width and cos(yaw)
///        over the history window.  High positive correlation → real 3-D face.
///
///   S4 – Nose landmark velocity naturalness (requires landmarks)
///        Real facial micro-tremors produce small continuous displacements.
///        A completely static replay has zero displacement.
///        A looped video has periodic large displacements.
///        Score 1.0 = natural tremor present. Score 0.0 = no motion.
///
/// Combined score: weighted mean of available signals.
/// Returns null until sufficient frames are accumulated.
class FaceGeometryAnalyzer {
  static const int    _historySize    = 30;
  static const int    _minHistory     = 8;
  static const double _eyeRatioLo     = 0.22;  // min plausible eye-dist/face-w
  static const double _eyeRatioHi     = 0.52;  // max plausible eye-dist/face-w
  static const double _velocityScale  = 2.0;   // pixels/frame for score 1.0

  // History buffers
  final List<double> _faceWidthHistory  = [];
  final List<double> _yawHistory        = [];
  final List<double> _symmetryHistory   = [];
  final List<double> _eyeRatioHistory   = [];
  final List<({double x, double y})> _nosePosHistory = [];

  // Latest per-signal scores
  double? _symmetryScore;
  double? _eyeRatioScore;
  double? _depthScore;
  double? _velocityScore;

  // ── Public getters ──────────────────────────────────────────────────────────

  double? get symmetryScore => _symmetryScore;
  double? get eyeRatioScore => _eyeRatioScore;
  double? get depthScore    => _depthScore;
  double? get velocityScore => _velocityScore;

  /// Combined geometry liveness score: 0.0 = suspicious, 1.0 = natural.
  /// Null until sufficient frames accumulated.
  double? get liveScore {
    final s = _symmetryScore;
    if (s == null) return null;
    double sum = s * 0.25, wt = 0.25;
    final e = _eyeRatioScore;
    final d = _depthScore;
    final v = _velocityScore;
    if (e != null) { sum += e * 0.25; wt += 0.25; }
    if (d != null) { sum += d * 0.30; wt += 0.30; }
    if (v != null) { sum += v * 0.20; wt += 0.20; }
    return (sum / wt).clamp(0.0, 1.0);
  }

  // ── Per-frame processing ────────────────────────────────────────────────────

  void processFrame(FaceData face) {
    final bbox   = face.boundingBox;
    final faceW  = bbox.width;
    final yaw    = face.headEulerAngleY;

    // Accumulate width + yaw for depth-consistency test
    _faceWidthHistory.add(faceW);
    _yawHistory.add(yaw);
    if (_faceWidthHistory.length > _historySize) _faceWidthHistory.removeAt(0);
    if (_yawHistory.length > _historySize) _yawHistory.removeAt(0);

    // ── S1: Eye symmetry ──────────────────────────────────────────────────────
    final lEye = face.leftEyeOpenProbability;
    final rEye = face.rightEyeOpenProbability;
    final symmetry = 1.0 - (lEye - rEye).abs().clamp(0.0, 1.0);
    _symmetryHistory.add(symmetry);
    if (_symmetryHistory.length > _historySize) _symmetryHistory.removeAt(0);
    if (_symmetryHistory.length >= 5) {
      _symmetryScore =
          (_symmetryHistory.reduce((a, b) => a + b) / _symmetryHistory.length)
              .clamp(0.0, 1.0);
    }

    // ── S2: Inter-eye / face-width ratio ──────────────────────────────────────
    final le = face.leftEyePosition;
    final re = face.rightEyePosition;
    if (le != null && re != null && faceW > 0) {
      final dx   = re.x - le.x;
      final dy   = re.y - le.y;
      final dist = sqrt(dx * dx + dy * dy);
      final ratio = dist / faceW;
      _eyeRatioHistory.add(ratio);
      if (_eyeRatioHistory.length > _historySize) _eyeRatioHistory.removeAt(0);
      if (_eyeRatioHistory.length >= _minHistory) {
        final avg = _eyeRatioHistory.reduce((a, b) => a + b) / _eyeRatioHistory.length;
        _eyeRatioScore = (avg >= _eyeRatioLo && avg <= _eyeRatioHi) ? 1.0 : 0.3;
      }
    }

    // ── S3: 3-D depth consistency ─────────────────────────────────────────────
    if (_faceWidthHistory.length >= _minHistory) {
      _depthScore = _computeDepthConsistency();
    }

    // ── S4: Nose landmark velocity ────────────────────────────────────────────
    final nose = face.noseBasePosition;
    if (nose != null) {
      _nosePosHistory.add(nose);
      if (_nosePosHistory.length > _historySize) _nosePosHistory.removeAt(0);
      if (_nosePosHistory.length >= _minHistory) {
        _velocityScore = _computeVelocityScore();
      }
    }
  }

  void reset() {
    _faceWidthHistory.clear();
    _yawHistory.clear();
    _symmetryHistory.clear();
    _eyeRatioHistory.clear();
    _nosePosHistory.clear();
    _symmetryScore = null;
    _eyeRatioScore = null;
    _depthScore    = null;
    _velocityScore = null;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Pearson correlation between normalized face width and cos(yaw).
  ///
  /// Real 3-D face: width decreases as yaw increases → positive correlation.
  /// Flat surface: width is constant regardless of yaw → correlation ≈ 0.
  double _computeDepthConsistency() {
    final n = _faceWidthHistory.length;
    final maxW = _faceWidthHistory.reduce((a, b) => a > b ? a : b);
    if (maxW < 1) return 1.0;

    final cosYaws   = List<double>.generate(n, (i) => _cosDeg(_yawHistory[i]));
    final normWidths = List<double>.generate(n, (i) => _faceWidthHistory[i] / maxW);

    final meanC = cosYaws.reduce((a, b) => a + b) / n;
    final meanW = normWidths.reduce((a, b) => a + b) / n;

    double cov = 0.0, varC = 0.0, varW = 0.0;
    for (int i = 0; i < n; i++) {
      final dc = cosYaws[i]   - meanC;
      final dw = normWidths[i] - meanW;
      cov  += dc * dw;
      varC += dc * dc;
      varW += dw * dw;
    }

    // Insufficient yaw variation to measure depth — return neutral score
    if (varC < 1e-6 || varW < 1e-6) return 0.70;

    final corr = (cov / sqrt(varC * varW)).clamp(-1.0, 1.0);
    // Map [-1, +1] → [0, 1]
    return ((corr + 1.0) / 2.0).clamp(0.0, 1.0);
  }

  /// Naturalness of landmark velocity:
  ///   - Near-zero displacement all the time → static / frozen replay → score 0.0
  ///   - Consistent micro-movement → natural tremor → score 1.0
  double _computeVelocityScore() {
    if (_nosePosHistory.length < 4) return 1.0;

    final displacements = <double>[];
    for (int i = 1; i < _nosePosHistory.length; i++) {
      final dx = _nosePosHistory[i].x - _nosePosHistory[i - 1].x;
      final dy = _nosePosHistory[i].y - _nosePosHistory[i - 1].y;
      displacements.add(sqrt(dx * dx + dy * dy));
    }

    final maxD = displacements.reduce((a, b) => a > b ? a : b);
    // Completely static → suspicious
    if (maxD < 0.5) return 0.2;

    // Jitter in the velocity sequence (second-difference of displacements)
    double jitterSum = 0.0;
    for (int i = 1; i < displacements.length; i++) {
      jitterSum += (displacements[i] - displacements[i - 1]).abs();
    }
    final avgJitter = jitterSum / (displacements.length - 1);
    return (avgJitter / _velocityScale).clamp(0.0, 1.0);
  }

  static double _cosDeg(double degrees) =>
      cos(degrees * pi / 180.0);
}
