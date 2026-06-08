
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/frame_quality.dart';

// ── Isolate-safe data transfer objects ───────────────────────────────────────

class _FrameInput {
  const _FrameInput({
    required this.width,
    required this.height,
    required this.yBytes,
    required this.yStride,
    required this.uBytes,
    required this.uStride,
    required this.uPixelStride,
    required this.vBytes,
    required this.isSinglePlane,
  });

  final int width;
  final int height;
  final Uint8List yBytes;
  final int yStride;
  final Uint8List uBytes;
  final int uStride;
  final int uPixelStride;
  final Uint8List vBytes;
  final bool isSinglePlane;
}

class ProcessedFrame {
  const ProcessedFrame({
    required this.nv21Bytes,
    required this.quality,
  });

  final Uint8List nv21Bytes;
  final FrameQuality quality;
}

// ── Top-level compute() function (runs in a background isolate) ────────────

ProcessedFrame _processFrame(_FrameInput input) {
  final width  = input.width;
  final height = input.height;

  // ── Step 1: Build NV21 bytes ─────────────────────────────────────────────
  Uint8List nv21;

  if (input.isSinglePlane) {
    nv21 = input.yBytes;
  } else {
    nv21 = Uint8List(width * height + width * (height ~/ 2));
    int idx = 0;

    // Y plane — strip row padding
    for (int row = 0; row < height; row++) {
      final start = row * input.yStride;
      for (int col = 0; col < width; col++) {
        nv21[idx++] = input.yBytes[start + col];
      }
    }

    // Interleaved VU (NV21)
    final uvHeight = height ~/ 2;
    final uvWidth  = width  ~/ 2;
    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        final off = row * input.uStride + col * input.uPixelStride;
        nv21[idx++] = input.vBytes[off]; // V first
        nv21[idx++] = input.uBytes[off]; // U second
      }
    }
  }

  // ── Step 2 & 3: Brightness + blur score ─────────────────────────────────
  // Android NV21 : Y plane (first width*height bytes) is already luminance.
  // iOS BGRA8888 : single plane with layout [B,G,R,A] per pixel — must
  //               compute BT.601 luminance manually to get correct brightness.
  const sampleStep = 8; // sample every 8th pixel for speed
  final pixelCount = width * height;
  double brightness;
  double blurScore;

  if (input.isSinglePlane) {
    // ── iOS BGRA8888 ──────────────────────────────────────────────────────
    int lumaSum = 0;
    int lumaSamples = 0;
    for (int p = 0; p < pixelCount; p += sampleStep) {
      final base = p * 4;
      if (base + 2 >= nv21.length) break;
      // BT.601: Y = (77*R + 150*G + 29*B) >> 8  (integer, avoids floats)
      lumaSum += (77 * nv21[base + 2] + 150 * nv21[base + 1] + 29 * nv21[base]) >> 8;
      lumaSamples++;
    }
    brightness = lumaSamples > 0 ? (lumaSum / lumaSamples) / 255.0 : 0.5;

    final lumaMean = lumaSamples > 0 ? lumaSum / lumaSamples : 127.0;
    double varSum = 0.0;
    for (int p = 0; p < pixelCount; p += sampleStep) {
      final base = p * 4;
      if (base + 2 >= nv21.length) break;
      final luma = (77 * nv21[base + 2] + 150 * nv21[base + 1] + 29 * nv21[base]) >> 8;
      final diff = luma - lumaMean;
      varSum += diff * diff;
    }
    blurScore = lumaSamples > 0 ? varSum / lumaSamples : 0.0;
  } else {
    // ── Android NV21 ─────────────────────────────────────────────────────
    int ySum = 0;
    int ySamples = 0;
    for (int i = 0; i < pixelCount; i += sampleStep) {
      ySum += nv21[i];
      ySamples++;
    }
    brightness = ySamples > 0 ? (ySum / ySamples) / 255.0 : 0.5;

    final yMean = ySamples > 0 ? ySum / ySamples : 127.0;
    double yVarSum = 0.0;
    for (int i = 0; i < pixelCount; i += sampleStep) {
      final diff = nv21[i] - yMean;
      yVarSum += diff * diff;
    }
    blurScore = ySamples > 0 ? yVarSum / ySamples : 0.0;
  }

  // ── Step 4: Frame hash (FNV-1a on every 16th pixel) ────────────────────
  int hash = 0x811c9dc5;
  final hashStride = input.isSinglePlane ? 64 : 16; // BGRA=4 bytes/pixel
  for (int i = 0; i < nv21.length; i += hashStride) {
    hash ^= nv21[i];
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }

  return ProcessedFrame(
    nv21Bytes: nv21,
    quality: FrameQuality(
      brightness: brightness,
      blurScore: blurScore,
      frameHash: hash,
    ),
  );
}

// ── Public service ────────────────────────────────────────────────────────────

/// Converts a [CameraImage] to NV21 bytes and computes [FrameQuality] metrics
/// in a background isolate via [compute()], keeping the UI thread free.
class FrameProcessor {
  /// Processes [image] off the main thread.
  /// Returns null if the image format is unsupported or conversion fails.
  static Future<ProcessedFrame?> process(CameraImage image) async {
    try {
      final input = _buildInput(image);
      if (input == null) return null;
      return await compute(_processFrame, input);
    } catch (e) {
      debugPrint('[FrameProcessor] Error: $e');
      return null;
    }
  }

  static _FrameInput? _buildInput(CameraImage image) {
    if (image.planes.isEmpty) return null;

    if (image.planes.length == 1) {
      return _FrameInput(
        width: image.width,
        height: image.height,
        yBytes: image.planes[0].bytes,
        yStride: image.planes[0].bytesPerRow,
        uBytes: Uint8List(0),
        uStride: 0,
        uPixelStride: 1,
        vBytes: Uint8List(0),
        isSinglePlane: true,
      );
    }

    if (image.planes.length < 3) return null;

    return _FrameInput(
      width: image.width,
      height: image.height,
      yBytes: image.planes[0].bytes,
      yStride: image.planes[0].bytesPerRow,
      uBytes: image.planes[1].bytes,
      uStride: image.planes[1].bytesPerRow,
      uPixelStride: image.planes[1].bytesPerPixel ?? 1,
      vBytes: image.planes[2].bytes,
      isSinglePlane: false,
    );
  }
}
