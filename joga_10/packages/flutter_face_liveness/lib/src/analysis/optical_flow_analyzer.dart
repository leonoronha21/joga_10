import 'dart:io' show Platform;

import '../ml/face_detector_service.dart';

// ignore_for_file: constant_identifier_names

/// Lightweight block-motion optical-flow analyzer for replay detection.
///
/// Algorithm (entirely on-device, no ML model required):
///
///   1. Each frame: extract a 32×32 luma thumbnail of the face crop.
///   2. Divide thumbnail into a 4×4 grid → 16 blocks of 8×8 pixels each.
///   3. For each block, compute Mean-Absolute-Difference (MAD) between
///      the current thumbnail and the previous one.  MAD ≈ motion energy.
///   4. Analyse the 16-element "motion energy" vector:
///
///   S1 – Stasis score
///        All blocks near zero → static image / frozen replay.
///        Score 1.0 = motion present. Score 0.0 = completely static.
///
///   S2 – Spatial variance of block energies
///        Real face: different facial regions (mouth, eyes, forehead, cheeks)
///        move with different amplitudes — HIGH spatial variance.
///        Rigid-body replay (phone held showing video): uniform motion across
///        all blocks — LOW spatial variance.
///        AEC-driven global brightness change: again uniform — LOW variance.
///
/// Combined score = weighted average of S1 and S2.
/// Returns null until at least 5 frame-pairs have been accumulated.
///
/// Usage:
///   ```dart
///   final analyzer = OpticalFlowAnalyzer();
///   analyzer.processFrame(rawFrame, faceData.boundingBox);
///   final score = analyzer.liveScore; // null | 0.0–1.0
///   analyzer.reset();
///   ```
class OpticalFlowAnalyzer {
  // Thumbnail dimensions
  static const int _tw = 32;
  static const int _th = 32;
  // Block grid
  static const int _bs   = 8;              // block side (pixels)
  static const int _bpR  = _tw ~/ _bs;     // blocks per row = 4
  static const int _nBlk = _bpR * (_th ~/ _bs); // total blocks = 16

  // Score mapping constants
  static const double _varScale    = 50.0;  // var ≥ 50 → varScore 1.0
  static const double _stasisThres = 2.0;   // MAD < 2 = near-static block

  List<int>? _prevThumb;
  final List<double> _varHistory    = [];
  final List<double> _stasisHistory = [];

  double? _liveScore;
  double? get liveScore => _liveScore;

  // ── Public API ──────────────────────────────────────────────────────────────

  void processFrame(RawFrameData frame,
      ({double left, double top, double right, double bottom}) bbox) {
    final thumb = _extractThumb(frame, bbox);
    if (_prevThumb == null) {
      _prevThumb = thumb;
      return;
    }

    final energies  = _blockEnergies(thumb, _prevThumb!);
    _prevThumb = thumb;

    final mean      = energies.reduce((a, b) => a + b) / energies.length;
    final variance  = energies
        .map((e) => (e - mean) * (e - mean))
        .reduce((a, b) => a + b) /
        energies.length;
    final stasisFrac =
        energies.where((e) => e < _stasisThres).length / energies.length;

    _varHistory.add(variance);
    _stasisHistory.add(stasisFrac);
    if (_varHistory.length   > 30) _varHistory.removeAt(0);
    if (_stasisHistory.length > 30) _stasisHistory.removeAt(0);

    if (_varHistory.length >= 5) {
      _liveScore = _score();
    }
  }

  void reset() {
    _prevThumb = null;
    _varHistory.clear();
    _stasisHistory.clear();
    _liveScore = null;
  }

  // ── Core algorithms ─────────────────────────────────────────────────────────

  /// Downsample the face crop to a [_tw]×[_th] luma thumbnail.
  List<int> _extractThumb(RawFrameData frame,
      ({double left, double top, double right, double bottom}) bbox) {
    final bytes = frame.imageBytes;
    final iw    = frame.imageWidth;
    final ih    = frame.imageHeight;

    double bL, bT, bR, bB;
    if (Platform.isIOS) {
      bL = bbox.left;  bT = bbox.top;
      bR = bbox.right; bB = bbox.bottom;
    } else {
      switch (frame.sensorOrientation) {
        case 270:
          bL = bbox.top;              bT = ih - 1 - bbox.right;
          bR = bbox.bottom;           bB = ih - 1 - bbox.left;
        case 90:
          bL = iw - 1 - bbox.bottom;  bT = bbox.left;
          bR = iw - 1 - bbox.top;     bB = bbox.right;
        case 180:
          bL = iw - 1 - bbox.right;   bT = ih - 1 - bbox.bottom;
          bR = iw - 1 - bbox.left;    bB = ih - 1 - bbox.top;
        default:
          bL = bbox.left;  bT = bbox.top;
          bR = bbox.right; bB = bbox.bottom;
      }
    }

    final x0 = bL.toInt().clamp(0, iw - 1);
    final y0 = bT.toInt().clamp(0, ih - 1);
    final fw = (bR - bL).toInt().clamp(4, iw - x0);
    final fh = (bB - bT).toInt().clamp(4, ih - y0);

    final thumb = List<int>.filled(_tw * _th, 128);
    for (int ty = 0; ty < _th; ty++) {
      for (int tx = 0; tx < _tw; tx++) {
        final sx = (x0 + fw * tx ~/ _tw).clamp(0, iw - 1);
        final sy = (y0 + fh * ty ~/ _th).clamp(0, ih - 1);
        int luma;
        if (Platform.isIOS) {
          final p = (sy * iw + sx) * 4;
          luma = (77 * bytes[p + 2] + 150 * bytes[p + 1] + 29 * bytes[p]) >> 8;
        } else {
          final idx = sy * iw + sx;
          luma = idx < iw * ih ? (bytes[idx] & 0xFF) : 128;
        }
        thumb[ty * _tw + tx] = luma;
      }
    }
    return thumb;
  }

  /// Mean-Absolute-Difference for each [_bs]×[_bs] block between two thumbnails.
  List<double> _blockEnergies(List<int> curr, List<int> prev) {
    final energies = List<double>.filled(_nBlk, 0.0);
    for (int by = 0; by < _th ~/ _bs; by++) {
      for (int bx = 0; bx < _tw ~/ _bs; bx++) {
        int sad = 0;
        for (int py = 0; py < _bs; py++) {
          for (int px = 0; px < _bs; px++) {
            final idx = (by * _bs + py) * _tw + (bx * _bs + px);
            sad += (curr[idx] - prev[idx]).abs();
          }
        }
        energies[by * _bpR + bx] = sad / (_bs * _bs);
      }
    }
    return energies;
  }

  double _score() {
    final avgVar   = _varHistory.reduce((a, b) => a + b) / _varHistory.length;
    final avgStasis = _stasisHistory.reduce((a, b) => a + b) / _stasisHistory.length;

    // S1: stasis — near-zero energy on all blocks = static photo or frozen replay
    final stasisScore = (1.0 - avgStasis).clamp(0.0, 1.0);

    // S2: spatial variance — real face regions move independently; rigid replay is uniform
    final varScore = (avgVar / _varScale).clamp(0.0, 1.0);

    return (stasisScore * 0.60 + varScore * 0.40).clamp(0.0, 1.0);
  }
}
