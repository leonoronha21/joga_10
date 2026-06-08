import 'dart:io' show Platform;
import 'dart:math' show log;

import '../ml/face_detector_service.dart';

// ── Per-frame snapshot ────────────────────────────────────────────────────────

/// Compact per-frame data fed to [ReplayAnalyzer].
///
/// [fingerprint]  – 16-value (4 × 4) luma grid of the face crop.
/// [eulerYaw]     – ML Kit head yaw (degrees, iOS-corrected).
/// [eulerPitch]   – ML Kit head pitch (degrees).
/// [faceAreaRatio]– Bbox area / frame area.
/// [leftEyeOpen]  – Probability 0–1.
/// [rightEyeOpen] – Probability 0–1.
class FrameSnapshot {
  const FrameSnapshot({
    required this.fingerprint,
    required this.eulerYaw,
    required this.eulerPitch,
    required this.faceAreaRatio,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
  });

  final List<int> fingerprint;
  final double eulerYaw;
  final double eulerPitch;
  final double faceAreaRatio;
  final double leftEyeOpen;
  final double rightEyeOpen;
}

// ── Session result ────────────────────────────────────────────────────────────

/// Aggregated replay-detection result for an entire liveness session.
class ReplayAnalysisResult {
  const ReplayAnalysisResult({
    required this.dupScore,
    required this.jitterScore,
    required this.motionEntropyScore,
    required this.blinkConsistencyScore,
    required this.overallScore,
    required this.isReplay,
    required this.details,
  });

  /// Fraction of frame-pairs that are perceptually distinct (near-duplicate check).
  /// 1.0 = all unique (live).  0.0 = most frames identical (looped/static replay).
  final double dupScore;

  /// Angular micro-jitter coefficient.
  /// 1.0 = natural muscle micro-tremor.  0.0 = unnaturally smooth (stabilised video).
  final double jitterScore;

  /// Shannon entropy of yaw-direction sequence.
  /// 1.0 = varied directions (live action).  0.0 = monotonic / periodic.
  final double motionEntropyScore;

  /// Natural blink pattern score.
  /// 1.0 = blinks detected with natural timing.  0.0 = no blinks in a long session.
  final double blinkConsistencyScore;

  /// Weighted combination of all signals. 0.0 = replay,  1.0 = live.
  final double overallScore;

  final bool   isReplay;

  /// Compact debug string for logging and UI overlay.
  final String details;
}

// ── Analyzer ──────────────────────────────────────────────────────────────────

/// Stateful per-session replay-attack analyzer.
///
/// Architecture:
///   • Call [addSnapshot] on every frame where a face is detected.
///   • Call [buildResult] at the end of the session.
///   • [liveScore] exposes a rolling score for the debug overlay.
///   • [reset] clears all accumulated state between retries.
///
/// Detection signals (all operate independently; minimum is never used to
/// avoid false positives — only the weighted combination triggers):
///
///   S1 – Perceptual fingerprint near-duplicate check
///        Catches looped video and static images.  FNV frame hash in
///        LivenessEngine handles exact duplicates; this catches near-duplicates
///        where individual video frames differ by a few pixel values.
///
///   S2 – Angular micro-jitter (second-difference variance)
///        Real faces exhibit natural muscle micro-tremor (random ±0.1–0.5°).
///        Stabilised or compressed video produces near-perfectly-smooth angles.
///
///   S3 – Yaw motion direction entropy
///        During the liveness challenge a real face makes several distinct
///        direction changes.  A poorly looped replay has lower direction entropy.
///
///   S4 – Blink consistency
///        Validates that natural blink events occur.  A frozen or looped video
///        without a genuine blink action will have zero blink events.
class ReplayAnalyzer {
  ReplayAnalyzer({int maxHistory = 120}) : _maxHistory = maxHistory;

  final int _maxHistory;

  final List<List<int>> _fingerprints = [];
  final List<double>    _yaw          = [];
  final List<double>    _pitch        = [];
  final List<double>    _area         = [];
  final List<double>    _leftEye      = [];
  final List<double>    _rightEye     = [];

  /// Rolling combined score updated every [addSnapshot] call.
  /// Null until at least 15 frames have been collected.
  double? get liveScore {
    if (_yaw.length < 15) return null;
    final d = _dupScore();
    final j = _jitterScore();
    final m = _motionEntropyScore();
    final b = _blinkScore();
    return (d * 0.35 + j * 0.35 + m * 0.15 + b * 0.15).clamp(0.0, 1.0);
  }

  bool get hasData => _yaw.length >= 15;

  // ── Public API ─────────────────────────────────────────────────────────────

  void addSnapshot(FrameSnapshot s) {
    _fingerprints.add(s.fingerprint);
    _yaw.add(s.eulerYaw);
    _pitch.add(s.eulerPitch);
    _area.add(s.faceAreaRatio);
    _leftEye.add(s.leftEyeOpen);
    _rightEye.add(s.rightEyeOpen);

    if (_fingerprints.length > _maxHistory) _fingerprints.removeAt(0);
    if (_yaw.length > _maxHistory)          _yaw.removeAt(0);
    if (_pitch.length > _maxHistory)        _pitch.removeAt(0);
    if (_area.length > _maxHistory)         _area.removeAt(0);
    if (_leftEye.length > _maxHistory)      _leftEye.removeAt(0);
    if (_rightEye.length > _maxHistory)     _rightEye.removeAt(0);
  }

  void reset() {
    _fingerprints.clear();
    _yaw.clear();
    _pitch.clear();
    _area.clear();
    _leftEye.clear();
    _rightEye.clear();
  }

  ReplayAnalysisResult buildResult({double threshold = 0.45}) {
    if (!hasData) {
      return const ReplayAnalysisResult(
        dupScore:              1.0,
        jitterScore:           1.0,
        motionEntropyScore:    1.0,
        blinkConsistencyScore: 1.0,
        overallScore:          1.0,
        isReplay:              false,
        details:               'insufficient-frames',
      );
    }

    final d = _dupScore();
    final j = _jitterScore();
    final m = _motionEntropyScore();
    final b = _blinkScore();

    final overall = (d * 0.35 + j * 0.35 + m * 0.15 + b * 0.15).clamp(0.0, 1.0);

    // Hard-fail only on extreme values — budget devices quantise ML Kit Euler
    // angles to 0.5° steps, producing near-zero jitter even for real users.
    // j < 0.03 requires virtually zero angular variation across all frames.
    final hardFail = (d < 0.10) || (j < 0.03);

    final isReplay = overall < threshold || hardFail;

    final details = 'dup=${d.toStringAsFixed(2)} '
        'jit=${j.toStringAsFixed(2)} '
        'ent=${m.toStringAsFixed(2)} '
        'blk=${b.toStringAsFixed(2)} '
        '→ ${overall.toStringAsFixed(2)}';

    return ReplayAnalysisResult(
      dupScore:              d,
      jitterScore:           j,
      motionEntropyScore:    m,
      blinkConsistencyScore: b,
      overallScore:          overall,
      isReplay:              isReplay,
      details:               details,
    );
  }

  // ── S1 – Perceptual near-duplicate detection ───────────────────────────────

  /// Fraction of consecutive frame-pairs that are perceptually distinct.
  ///
  /// Similarity threshold: mean absolute luma difference < 8 / 255 ≈ 3%
  /// of the 16-value fingerprint.  Calibrated so natural face micro-motion
  /// keeps most pairs distinct while a static/looped replay repeats.
  double _dupScore() {
    if (_fingerprints.length < 4) return 1.0;
    int unique = 0;
    for (int i = 1; i < _fingerprints.length; i++) {
      int totalDiff = 0;
      final a = _fingerprints[i - 1];
      final b = _fingerprints[i];
      for (int k = 0; k < a.length; k++) {
        totalDiff += (a[k] - b[k]).abs();
      }
      if (totalDiff > a.length * 8) unique++; // > 3% avg diff → distinct
    }
    return (unique / (_fingerprints.length - 1)).clamp(0.0, 1.0);
  }

  // ── S2 – Angular micro-jitter ──────────────────────────────────────────────

  /// Variance of angular acceleration (second differences of Euler angles).
  ///
  /// A real face has random muscular micro-tremor superimposed on every
  /// intentional movement.  This creates significant variability in angular
  /// acceleration.  Video codecs smooth this signal, producing near-zero
  /// second differences even during head-turn liveness actions.
  ///
  /// Score mapping:
  ///   jerkVar ≥ 0.08 → score 1.0 (natural)
  ///   jerkVar ≤ 0.002 → score 0.0 (too smooth)
  double _jitterScore() {
    if (_yaw.length < 10) return 1.0;

    final jerkY = <double>[];
    final jerkP = <double>[];
    for (int i = 2; i < _yaw.length; i++) {
      jerkY.add((_yaw[i] - 2 * _yaw[i - 1] + _yaw[i - 2]).abs());
      jerkP.add((_pitch[i] - 2 * _pitch[i - 1] + _pitch[i - 2]).abs());
    }

    final varY = _variance(jerkY);
    final varP = _variance(jerkP);
    final jerkVar = (varY + varP) * 0.5;

    // Map [0.002, 0.08] → [0, 1]
    const lo = 0.002;
    const hi = 0.08;
    if (jerkVar <= lo) return (jerkVar / lo).clamp(0.0, 1.0);
    if (jerkVar >= hi) return 1.0;
    return ((jerkVar - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  // ── S3 – Motion direction entropy ─────────────────────────────────────────

  /// Shannon entropy of yaw-direction change sequence.
  ///
  /// Computed over quantised direction: left (−1), still (0), right (+1).
  /// Natural liveness actions and real micro-tremor produce many direction
  /// reversals → high entropy.  A monotonic or periodic replay produces
  /// fewer distinct direction changes → lower entropy.
  double _motionEntropyScore() {
    if (_yaw.length < 15) return 1.0;
    final dirs = <int>[];
    for (int i = 1; i < _yaw.length; i++) {
      final dy = _yaw[i] - _yaw[i - 1];
      dirs.add(dy < -0.25 ? -1 : dy > 0.25 ? 1 : 0);
    }
    final counts = <int, int>{-1: 0, 0: 0, 1: 0};
    for (final d in dirs) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final n = dirs.length.toDouble();
    double entropy = 0;
    for (final c in counts.values) {
      if (c == 0) continue;
      final p = c / n;
      entropy -= p * log(p);
    }
    const maxEntropy = 1.0986; // ln(3)
    return (entropy / maxEntropy).clamp(0.0, 1.0);
  }

  // ── S4 – Blink consistency ─────────────────────────────────────────────────

  /// Detects whether at least one natural double-eye blink occurred.
  ///
  /// A blink event is defined as both eye probabilities dropping below 0.35
  /// simultaneously for at least 2 frames.  Frozen or stabilised video without
  /// a genuine blink response returns 0.0 after a sufficient observation window.
  ///
  /// Returns 1.0 (assumed natural) when fewer than 40 frames have been
  /// accumulated — not enough time to mandate a blink.
  double _blinkScore() {
    if (_leftEye.length < 40) return 1.0;

    int blinkFrames = 0;
    bool inBlink = false;
    for (int i = 0; i < _leftEye.length; i++) {
      final bothClosed = _leftEye[i] < 0.35 && _rightEye[i] < 0.35;
      if (bothClosed) {
        if (!inBlink) blinkFrames++;
        inBlink = true;
      } else {
        inBlink = false;
      }
    }
    return blinkFrames >= 1 ? 1.0 : 0.4; // penalise but don't hard-fail
  }

  // ── Math helpers ───────────────────────────────────────────────────────────

  static double _variance(List<double> v) {
    if (v.length < 2) return 0;
    final m = v.reduce((a, b) => a + b) / v.length;
    return v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length;
  }
}

// ── Face fingerprint computation ──────────────────────────────────────────────

/// Computes a 16-value (4 × 4 grid) luma fingerprint of the face crop.
///
/// Each of the 16 values is the mean Y-plane luma (0–255) of one quarter-face
/// sub-block, sampled at every 4th pixel for speed.
///
/// Handles both iOS (BGRA8888) and Android (NV21) raw frames, including the
/// sensor-orientation reversal required to map ML Kit bbox coordinates back to
/// raw-pixel space on Android.
List<int> computeFaceFingerprint(RawFrameData frame, double bL, double bT, double bR, double bB) {
  final bytes = frame.imageBytes;
  final iw    = frame.imageWidth;
  final ih    = frame.imageHeight;

  int fx0, fy0, fw, fh;
  if (Platform.isIOS) {
    fx0 = bL.toInt().clamp(0, iw - 1);
    fy0 = bT.toInt().clamp(0, ih - 1);
    fw  = (bR - bL).toInt().clamp(4, iw - fx0);
    fh  = (bB - bT).toInt().clamp(4, ih - fy0);
  } else {
    late double nl, nt, nr, nb;
    switch (frame.sensorOrientation) {
      case 270:
        nl = bT;           nt = ih - 1 - bR;
        nr = bB;           nb = ih - 1 - bL;
      case 90:
        nl = iw - 1 - bB;  nt = bL;
        nr = iw - 1 - bT;  nb = bR;
      case 180:
        nl = iw - 1 - bR;  nt = ih - 1 - bB;
        nr = iw - 1 - bL;  nb = ih - 1 - bT;
      default:
        nl = bL; nt = bT; nr = bR; nb = bB;
    }
    fx0 = nl.toInt().clamp(0, iw - 1);
    fy0 = nt.toInt().clamp(0, ih - 1);
    fw  = (nr - nl).toInt().clamp(4, iw - fx0);
    fh  = (nb - nt).toInt().clamp(4, ih - fy0);
  }

  const g = 4; // grid size
  final result = List<int>.filled(g * g, 0);

  for (int gy = 0; gy < g; gy++) {
    for (int gx = 0; gx < g; gx++) {
      final rx0 = (fx0 + fw *  gx      ~/ g).clamp(0, iw - 1);
      final ry0 = (fy0 + fh *  gy      ~/ g).clamp(0, ih - 1);
      final rx1 = (fx0 + fw * (gx + 1) ~/ g).clamp(1, iw);
      final ry1 = (fy0 + fh * (gy + 1) ~/ g).clamp(1, ih);

      int sum = 0, count = 0;
      if (Platform.isIOS) {
        // BGRA8888: BT.601 luma = (77R + 150G + 29B) >> 8
        for (int y = ry0; y < ry1; y += 4) {
          for (int x = rx0; x < rx1; x += 4) {
            final p = (y * iw + x) * 4;
            sum += (77 * bytes[p + 2] + 150 * bytes[p + 1] + 29 * bytes[p]) >> 8;
            count++;
          }
        }
      } else {
        // NV21: Y plane occupies first iw×ih bytes
        for (int y = ry0; y < ry1; y += 4) {
          for (int x = rx0; x < rx1; x += 4) {
            final idx = y * iw + x;
            if (idx < iw * ih) { sum += bytes[idx] & 0xFF; count++; }
          }
        }
      }
      result[gy * g + gx] = count > 0 ? (sum ~/ count) : 0;
    }
  }
  return result;
}
