import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Crops a face region from a raw camera frame and converts it to
/// a 160×160 Float32 RGB tensor (values in [-1, 1]) suitable as
/// MobileFaceNet / FaceNet input.
///
/// When eye positions are supplied, an eye-aligned similarity transform is
/// applied so that both eyes land at fixed target coordinates in every output
/// image. This dramatically reduces intra-person embedding variance and
/// separates same-person and different-person similarity distributions.
class FacePreprocessor {
  static const int targetSize = 160;

  // Target eye layout inside the 160×160 output tensor.
  // Left eye at (48, 60), right eye at (112, 60) — standard FaceNet alignment.
  static const double _tgtMidX    = 80.0;   // (48 + 112) / 2
  static const double _tgtMidY    = 60.0;
  static const double _tgtEyeDist = 64.0;   // 112 - 48

  /// Returns a [Float32List] of length `160 * 160 * 3`, or `null` on error.
  ///
  /// [imageBytes]       — NV21 bytes (Android) or BGRA8888 bytes (iOS).
  /// [imageWidth]       — original frame width (before any ML Kit rotation).
  /// [imageHeight]      — original frame height.
  /// [bbox]             — face bounding box in ML Kit output space.
  /// [sensorOrientation]— degrees (0, 90, 180, 270) as reported by the camera.
  /// [leftEyeX/Y]       — left-eye landmark in ML Kit output space (optional).
  /// [rightEyeX/Y]      — right-eye landmark in ML Kit output space (optional).
  ///
  /// When eye positions are provided, an eye-aligned crop is used (preferred).
  /// Falls back to padded-bbox crop when eye positions are absent.
  static Float32List? prepare({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required Rect bbox,
    required int sensorOrientation,
    double? leftEyeX,
    double? leftEyeY,
    double? rightEyeX,
    double? rightEyeY,
  }) {
    try {
      final hasEyes = leftEyeX != null && leftEyeY != null &&
                      rightEyeX != null && rightEyeY != null;

      if (Platform.isIOS) {
        // iOS: BGRA8888, all coordinates are already in display (frame) space.
        if (hasEyes) {
          final aligned = _alignedCropBgra(
            imageBytes, imageWidth, imageHeight,
            leftEyeX, leftEyeY, rightEyeX, rightEyeY,
          );
          if (aligned != null) return aligned;
        }
        return _fromBgra(imageBytes, imageWidth, imageHeight, bbox);
      }

      // Android: NV21, ML Kit landmarks are in rotated display space.
      if (hasEyes) {
        final le = _landmarkToSensor(leftEyeX, leftEyeY, imageWidth, imageHeight, sensorOrientation);
        final re = _landmarkToSensor(rightEyeX, rightEyeY, imageWidth, imageHeight, sensorOrientation);
        final aligned = _alignedCropNv21(
          imageBytes, imageWidth, imageHeight,
          le.$1, le.$2, re.$1, re.$2,
        );
        if (aligned != null) return aligned;
      }
      return _fromNv21(imageBytes, imageWidth, imageHeight, bbox, sensorOrientation);
    } catch (e) {
      debugPrint('[FacePreprocessor] $e');
      return null;
    }
  }

  // ── Eye-aligned crop (iOS / BGRA) ─────────────────────────────────────────

  static Float32List? _alignedCropBgra(
    Uint8List bytes, int w, int h,
    double lex, double ley, double rex, double rey,
  ) {
    return _alignedCrop(
      bytes, w, h, lex, ley, rex, rey,
      (sx, sy) {
        final p = (sy * w + sx) * 4;
        return [bytes[p + 2] & 0xFF, bytes[p + 1] & 0xFF, bytes[p] & 0xFF];
      },
    );
  }

  // ── Eye-aligned crop (Android / NV21) ────────────────────────────────────

  static Float32List? _alignedCropNv21(
    Uint8List nv21, int w, int h,
    double lex, double ley, double rex, double rey,
  ) {
    return _alignedCrop(
      nv21, w, h, lex, ley, rex, rey,
      (sx, sy) => _yuv2rgb(nv21, sx, sy, w, h),
    );
  }

  // ── Core aligned-crop logic (platform-agnostic) ───────────────────────────
  //
  // Applies a similarity transform (rotate + scale + translate) so that:
  //   left eye  → (48, 60)
  //   right eye → (112, 60)
  // in the 160×160 output, making every embedding orientation-invariant.
  //
  // Bilinear interpolation: each output pixel is a weighted average of the
  // 4 nearest source pixels. This eliminates nearest-neighbor aliasing, which
  // caused the same face crop to differ slightly between sessions.

  static Float32List? _alignedCrop(
    Uint8List bytes, int w, int h,
    double lex, double ley, double rex, double rey,
    List<int> Function(int sx, int sy) samplePixel,
  ) {
    final dx = rex - lex, dy = rey - ley;
    final srcDist = math.sqrt(dx * dx + dy * dy);
    if (srcDist < 8) return null; // eye landmarks too close — unreliable

    final srcAngle = math.atan2(dy, dx);
    final scale    = _tgtEyeDist / srcDist;
    final srcMx    = (lex + rex) / 2;
    final srcMy    = (ley + rey) / 2;
    // Inverse similarity transform: rotate by +srcAngle to undo the forward -srcAngle rotation.
    // Using R(srcAngle) = [[cos, -sin], [sin, cos]] applied to the scaled output offset.
    final cosA     = math.cos(srcAngle);
    final sinA     = math.sin(srcAngle);

    final out = Float32List(targetSize * targetSize * 3);
    int i = 0;

    for (int oy = 0; oy < targetSize; oy++) {
      for (int ox = 0; ox < targetSize; ox++) {
        // Inverse similarity transform: output pixel → fractional source coords
        final ddx = (ox - _tgtMidX) / scale;
        final ddy = (oy - _tgtMidY) / scale;
        final sxf = srcMx + ddx * cosA - ddy * sinA;
        final syf = srcMy + ddx * sinA + ddy * cosA;

        // Bilinear interpolation — 4 corner pixels + fractional weights
        final x0 = sxf.floor().clamp(0, w - 1);
        final y0 = syf.floor().clamp(0, h - 1);
        final x1 = (x0 + 1).clamp(0, w - 1);
        final y1 = (y0 + 1).clamp(0, h - 1);
        final fx = sxf - x0;   // horizontal fractional weight (0.0–1.0)
        final fy = syf - y0;   // vertical   fractional weight (0.0–1.0)

        final p00 = samplePixel(x0, y0);
        final p10 = samplePixel(x1, y0);
        final p01 = samplePixel(x0, y1);
        final p11 = samplePixel(x1, y1);

        final r = (1-fx)*(1-fy)*p00[0] + fx*(1-fy)*p10[0] + (1-fx)*fy*p01[0] + fx*fy*p11[0];
        final g = (1-fx)*(1-fy)*p00[1] + fx*(1-fy)*p10[1] + (1-fx)*fy*p01[1] + fx*fy*p11[1];
        final b = (1-fx)*(1-fy)*p00[2] + fx*(1-fy)*p10[2] + (1-fx)*fy*p01[2] + fx*fy*p11[2];

        out[i++] = (r / 128.0) - 1.0;
        out[i++] = (g / 128.0) - 1.0;
        out[i++] = (b / 128.0) - 1.0;
      }
    }
    return out;
  }

  // ── Coordinate transform: ML Kit display space → NV21 sensor space ────────

  static (double, double) _landmarkToSensor(
    double px, double py, int origW, int origH, int degrees,
  ) {
    switch (degrees) {
      case 270: return (py, origH - 1 - px);
      case 90:  return (origW - 1 - py, px);
      case 180: return (origW - 1 - px, origH - 1 - py);
      default:  return (px, py);
    }
  }

  // ── Fallback: bbox-padded crop (no eye positions) ─────────────────────────

  static Float32List _fromBgra(Uint8List bytes, int w, int h, Rect bbox) {
    final r = _padBbox(bbox, w.toDouble(), h.toDouble());
    return _resampleBgra(bytes, w, h, r);
  }

  static Float32List _resampleBgra(Uint8List bytes, int w, int h, Rect crop) {
    final out = Float32List(targetSize * targetSize * 3);
    int i = 0;
    final x0 = crop.left.toInt().clamp(0, w - 1);
    final y0 = crop.top.toInt().clamp(0, h - 1);
    final cw = crop.width.toInt().clamp(1, w - x0);
    final ch = crop.height.toInt().clamp(1, h - y0);
    for (int dy = 0; dy < targetSize; dy++) {
      for (int dx = 0; dx < targetSize; dx++) {
        final sx = (x0 + dx * cw ~/ targetSize).clamp(0, w - 1);
        final sy = (y0 + dy * ch ~/ targetSize).clamp(0, h - 1);
        final p  = (sy * w + sx) * 4;
        out[i++] = (bytes[p + 2] / 128.0) - 1.0;
        out[i++] = (bytes[p + 1] / 128.0) - 1.0;
        out[i++] = (bytes[p    ] / 128.0) - 1.0;
      }
    }
    return out;
  }

  static Float32List _fromNv21(
    Uint8List nv21, int origW, int origH, Rect rotBbox, int sensorOri,
  ) {
    final origBbox = _bboxToOriginal(rotBbox, origW, origH, sensorOri);
    final x0 = origBbox.left.toInt().clamp(0, origW - 1);
    final y0 = origBbox.top.toInt().clamp(0, origH - 1);
    final cw = origBbox.width.toInt().clamp(1, origW - x0);
    final ch = origBbox.height.toInt().clamp(1, origH - y0);

    final out = Float32List(targetSize * targetSize * 3);
    int i = 0;
    for (int dy = 0; dy < targetSize; dy++) {
      for (int dx = 0; dx < targetSize; dx++) {
        final sx = (x0 + dx * cw ~/ targetSize).clamp(0, origW - 1);
        final sy = (y0 + dy * ch ~/ targetSize).clamp(0, origH - 1);
        final rgb = _yuv2rgb(nv21, sx, sy, origW, origH);
        out[i++] = (rgb[0] / 128.0) - 1.0;
        out[i++] = (rgb[1] / 128.0) - 1.0;
        out[i++] = (rgb[2] / 128.0) - 1.0;
      }
    }
    return out;
  }

  static Rect _bboxToOriginal(Rect r, int origW, int origH, int degrees) {
    final double l = r.left, t = r.top, ri = r.right, b = r.bottom;
    late final double nl, nt, nr, nb;
    switch (degrees) {
      case 270:
        nl = t; nt = origH - 1 - ri; nr = b; nb = origH - 1 - l;
        break;
      case 90:
        nl = origW - 1 - b; nt = l; nr = origW - 1 - t; nb = ri;
        break;
      case 180:
        nl = origW - 1 - ri; nt = origH - 1 - b; nr = origW - 1 - l; nb = origH - 1 - t;
        break;
      default:
        nl = l; nt = t; nr = ri; nb = b;
    }
    return _padBbox(Rect.fromLTRB(nl, nt, nr, nb), origW.toDouble(), origH.toDouble());
  }

  static Rect _padBbox(Rect box, double maxW, double maxH) {
    final px = box.width  * 0.20;
    final py = box.height * 0.20;
    return Rect.fromLTRB(
      math.max(0, box.left   - px),
      math.max(0, box.top    - py),
      math.min(maxW, box.right  + px),
      math.min(maxH, box.bottom + py),
    );
  }

  static List<int> _yuv2rgb(Uint8List nv21, int x, int y, int w, int h) {
    final yVal   = nv21[y * w + x] & 0xFF;
    final uvBase = w * h + (y >> 1) * w + (x & ~1);
    final vVal   = nv21[uvBase    ] & 0xFF;
    final uVal   = nv21[uvBase + 1] & 0xFF;

    final r = (yVal + 1.402   * (vVal - 128)).round().clamp(0, 255);
    final g = (yVal - 0.34414 * (uVal - 128) - 0.71414 * (vVal - 128)).round().clamp(0, 255);
    final b = (yVal + 1.772   * (uVal - 128)).round().clamp(0, 255);
    return [r, g, b];
  }
}
