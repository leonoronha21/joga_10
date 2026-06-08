import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result from TFLite model inference.
class TFLiteResult {
  const TFLiteResult({
    required this.isReal,
    required this.realScore,
    required this.spoofScore,
  });

  /// True when the model classifies this as a real/live face.
  final bool isReal;

  /// Confidence that input is a real face (0.0–1.0).
  final double realScore;

  /// Confidence that input is a spoofed face (0.0–1.0).
  final double spoofScore;

  @override
  String toString() =>
      'TFLiteResult(real: $isReal, realScore: ${realScore.toStringAsFixed(3)})';
}

// ══════════════════════════════════════════════════════════════════════════════
// Isolate message types — plain Dart data only (no native handles, no dart:ui)
// ══════════════════════════════════════════════════════════════════════════════

class _InitMsg {
  const _InitMsg(this.modelBytes, this.inputSize, this.replyPort, {
    this.realClassIndex = 0,
    this.cropScale = 1.4,
    this.useImageNetBgr = false,
  });
  final Uint8List modelBytes;
  final int inputSize;
  final SendPort replyPort;
  // Index in the output tensor that holds the "real" class score.
  // 0 = bundled FaceAntiSpoofing model, 1 = MiniFASNet format [spoof, real].
  final int realClassIndex;
  // Scale factor for the square crop around the face centre.
  // 1.4 = default (20% padding each side). 2.7 = MiniFASNet required scale.
  final double cropScale;
  // When true: output BGR channels with ImageNet normalization (MiniFASNet).
  // When false: output RGB channels with [-1, 1] normalization (default).
  final bool useImageNetBgr;
}

class _RunMsg {
  const _RunMsg({
    required this.id,
    required this.imageData,
    required this.imageWidth,
    required this.imageHeight,
    required this.bboxLeft,
    required this.bboxTop,
    required this.bboxRight,
    required this.bboxBottom,
    required this.sensorOrientation,
    required this.isIOS,
  });
  final int id;
  final TransferableTypedData imageData; // zero-copy transfer
  final int imageWidth, imageHeight;
  final double bboxLeft, bboxTop, bboxRight, bboxBottom;
  final int sensorOrientation;
  final bool isIOS;
}

class _ResultMsg {
  const _ResultMsg(this.id, {this.realScore, this.spoofScore, this.error});
  final int id;
  final double? realScore;
  final double? spoofScore;
  final String? error;
}

class _DisposeMsg {
  const _DisposeMsg();
}

// ══════════════════════════════════════════════════════════════════════════════
// Background isolate worker — owns the Interpreter, never blocks main thread
// ══════════════════════════════════════════════════════════════════════════════

void _tfliteWorker(_InitMsg init) {
  final receivePort = ReceivePort();
  init.replyPort.send(receivePort.sendPort); // handshake step 1: give main our port

  Interpreter? interp;
  int outCount = 1;

  try {
    interp = Interpreter.fromBuffer(init.modelBytes);
    try {
      interp.getOutputTensor(1);
      outCount = 2;
    } catch (_) {}
    interp.resizeInputTensor(0, [1, init.inputSize, init.inputSize, 3]);
    interp.allocateTensors();
    init.replyPort.send(true); // handshake step 2: ready
  } catch (e) {
    init.replyPort.send('ERROR:$e');
    return;
  }

  receivePort.listen((msg) {
    if (msg is _DisposeMsg) {
      interp?.close();
      receivePort.close();
      return;
    }
    if (msg is! _RunMsg) return;
    try {
      final bytes = msg.imageData.materialize().asUint8List();
      final input = msg.isIOS
          ? _bgraFloat32(bytes, msg.imageWidth, msg.imageHeight,
              msg.bboxLeft, msg.bboxTop, msg.bboxRight, msg.bboxBottom,
              init.inputSize, init.cropScale, init.useImageNetBgr)
          : _nv21Float32(bytes, msg.imageWidth, msg.imageHeight,
              msg.bboxLeft, msg.bboxTop, msg.bboxRight, msg.bboxBottom,
              msg.sensorOrientation, init.inputSize, init.cropScale, init.useImageNetBgr);

      interp!.getInputTensor(0).data = input.buffer.asUint8List();
      interp.invoke();

      final out0 = interp.getOutputTensor(0).data.buffer.asFloat32List();
      _ResultMsg result;
      if (outCount >= 2) {
        final out1 = interp.getOutputTensor(1).data.buffer.asFloat32List();
        result = _dualScore(msg.id, out0, out1);
      } else {
        result = _singleScore(msg.id, out0, init.realClassIndex);
      }
      init.replyPort.send(result);
    } catch (e) {
      init.replyPort.send(_ResultMsg(msg.id, error: e.toString()));
    }
  });
}

// ── Preprocessing (top-level, isolate-safe — no dart:ui) ─────────────────────

// No pre-computed normalization constants needed here.
// When useImageNetBgr=true the model receives BGR channels in the simple [-1,1]
// range, which is the expected input for MiniFASNet's NormalisedMiniFAS wrapper
// (the wrapper itself applies the (x+1)/2 and ImageNet mean/std operations).

/// Compute a centred square crop.
/// Returns [x0, y0, cropW, cropH].
List<int> _squareCrop(
    double bL, double bT, double bR, double bB,
    double cropScale, int imgW, int imgH) {
  final cx = (bL + bR) * 0.5;
  final cy = (bT + bB) * 0.5;
  final half = math.max(bR - bL, bB - bT) * cropScale * 0.5;
  final x0 = (cx - half).clamp(0.0, (imgW - 1).toDouble()).toInt();
  final y0 = (cy - half).clamp(0.0, (imgH - 1).toDouble()).toInt();
  final x1 = (cx + half).clamp(0.0, imgW.toDouble()).toInt();
  final y1 = (cy + half).clamp(0.0, imgH.toDouble()).toInt();
  return [x0, y0, (x1 - x0).clamp(1, imgW - x0), (y1 - y0).clamp(1, imgH - y0)];
}

Float32List _bgraFloat32(
  Uint8List bytes, int w, int h,
  double bL, double bT, double bR, double bB,
  int sz, double cropScale, bool useImageNetBgr,
) {
  final c = _squareCrop(bL, bT, bR, bB, cropScale, w, h);
  final x0 = c[0], y0 = c[1], cw = c[2], ch = c[3];
  final out = Float32List(sz * sz * 3);
  int i = 0;
  for (int dy = 0; dy < sz; dy++) {
    for (int dx = 0; dx < sz; dx++) {
      final sx = (x0 + dx * cw ~/ sz).clamp(0, w - 1);
      final sy = (y0 + dy * ch ~/ sz).clamp(0, h - 1);
      final p = (sy * w + sx) * 4;
      // BGRA layout: bytes[p]=B, [p+1]=G, [p+2]=R
      if (useImageNetBgr) {
        // BGR channel order, simple [-1,1] — NormalisedMiniFAS wrapper input.
        // The wrapper applies (x+1)/2 then ImageNet mean/std internally.
        out[i++] = bytes[p    ] / 127.5 - 1.0; // B → [-1, 1]
        out[i++] = bytes[p + 1] / 127.5 - 1.0; // G → [-1, 1]
        out[i++] = bytes[p + 2] / 127.5 - 1.0; // R → [-1, 1]
      } else {
        out[i++] = bytes[p + 2] / 127.5 - 1.0; // R → [-1, 1]
        out[i++] = bytes[p + 1] / 127.5 - 1.0; // G
        out[i++] = bytes[p    ] / 127.5 - 1.0; // B
      }
    }
  }
  return out;
}

Float32List _nv21Float32(
  Uint8List nv21, int origW, int origH,
  double bL, double bT, double bR, double bB,
  int sensorOri, int sz, double cropScale, bool useImageNetBgr,
) {
  // Reverse the rotation ML Kit applied → raw NV21 coordinate space
  late double nl, nt, nr, nb;
  switch (sensorOri) {
    case 270:
      nl = bT; nt = origH - 1 - bR; nr = bB; nb = origH - 1 - bL;
    case 90:
      nl = origW - 1 - bB; nt = bL; nr = origW - 1 - bT; nb = bR;
    case 180:
      nl = origW - 1 - bR; nt = origH - 1 - bB;
      nr = origW - 1 - bL; nb = origH - 1 - bT;
    default:
      nl = bL; nt = bT; nr = bR; nb = bB;
  }
  final c = _squareCrop(nl, nt, nr, nb, cropScale, origW, origH);
  final x0 = c[0], y0 = c[1], cw = c[2], ch = c[3];
  final out = Float32List(sz * sz * 3);
  int i = 0;
  for (int dy = 0; dy < sz; dy++) {
    for (int dx = 0; dx < sz; dx++) {
      final sx = (x0 + dx * cw ~/ sz).clamp(0, origW - 1);
      final sy = (y0 + dy * ch ~/ sz).clamp(0, origH - 1);
      final yVal   = nv21[sy * origW + sx] & 0xFF;
      final uvBase = origW * origH + (sy >> 1) * origW + (sx & ~1);
      final vVal   = nv21[uvBase    ] & 0xFF;
      final uVal   = nv21[uvBase + 1] & 0xFF;
      final r = (yVal + 1.402   * (vVal - 128)).round().clamp(0, 255);
      final g = (yVal - 0.34414 * (uVal - 128) - 0.71414 * (vVal - 128)).round().clamp(0, 255);
      final b = (yVal + 1.772   * (uVal - 128)).round().clamp(0, 255);
      if (useImageNetBgr) {
        // BGR channel order, simple [-1,1] — NormalisedMiniFAS wrapper input.
        out[i++] = b / 127.5 - 1.0; // B → [-1, 1]
        out[i++] = g / 127.5 - 1.0; // G → [-1, 1]
        out[i++] = r / 127.5 - 1.0; // R → [-1, 1]
      } else {
        out[i++] = r / 127.5 - 1.0; // normalised to [-1, 1]
        out[i++] = g / 127.5 - 1.0;
        out[i++] = b / 127.5 - 1.0;
      }
    }
  }
  return out;
}

_ResultMsg _singleScore(int id, Float32List out, int realIdx) {
  if (out.length < 2) return _ResultMsg(id, realScore: 0.5, spoofScore: 0.5);
  // Softmax handles both raw logits and pre-softmaxed outputs correctly
  final maxV = out.reduce(math.max);
  final e0   = math.exp(out[0] - maxV);
  final e1   = math.exp(out[1] - maxV);
  final sum  = e0 + e1;
  final r = (realIdx == 0 ? e0 : e1) / sum;
  final s = (realIdx == 0 ? e1 : e0) / sum;
  return _ResultMsg(id, realScore: r, spoofScore: s);
}

_ResultMsg _dualScore(int id, Float32List clss, Float32List leaf) {
  final maxV = clss.reduce(math.max);
  final expV = clss.map((v) => math.exp(v - maxV)).toList();
  final sumE = expV.reduce((a, b) => a + b);
  double spoofFraction = 0.0;
  for (int i = 0; i < clss.length; i++) {
    spoofFraction += (expV[i] / sumE) * leaf[i];
  }
  spoofFraction = spoofFraction.clamp(0.0, 1.0);
  // leaf[i]=1 means spoof vote, so spoofFraction = spoof score
  final realScore = 1.0 - spoofFraction;
  return _ResultMsg(id, realScore: realScore, spoofScore: spoofFraction);
}

// ══════════════════════════════════════════════════════════════════════════════
// Public service
// ══════════════════════════════════════════════════════════════════════════════

/// Loads and runs a TensorFlow Lite anti-spoof model in a background isolate.
///
/// All inference and preprocessing happens off the main thread — the camera
/// preview and blink/head-movement detection are never blocked.
class TFLiteService {
  TFLiteService({
    required this.modelPath,
    required this.inputSize,
    this.realClassIndex = 0,
    this.cropScale = 1.4,
    this.useImageNetBgr = false,
  });

  final String modelPath;
  final int inputSize;
  /// Index in the single-tensor output that holds the "real" class score.
  /// 0 = bundled FaceAntiSpoofing model (out[0]=real).
  /// 1 = MiniFASNet format (out[0]=spoof, out[1]=real).
  final int realClassIndex;
  /// Scale factor for the square crop around the face centre.
  /// 1.4 = default. 2.7 = MiniFASNet required scale for screen-artifact detection.
  final double cropScale;
  /// When true: BGR channels + ImageNet normalization (MiniFASNet).
  /// When false: RGB channels + [-1, 1] normalization (default).
  final bool useImageNetBgr;

  bool         _isLoaded   = false;
  Isolate?     _isolate;
  SendPort?    _workerPort;
  ReceivePort? _mainPort;
  int          _nextId     = 0;
  final Map<int, Completer<_ResultMsg>> _pending = {};

  /// Load the model and spin up the background worker isolate.
  /// Accepts a Flutter asset key or an absolute filesystem path.
  Future<bool> load() async {
    if (_isLoaded) return true;
    try {
      // Load model bytes on main isolate (asset bundle / filesystem)
      final Uint8List modelBytes;
      if (modelPath.startsWith('/')) {
        modelBytes = await File(modelPath).readAsBytes();
      } else {
        final bd = await rootBundle.load(modelPath);
        modelBytes = bd.buffer.asUint8List();
      }

      _mainPort = ReceivePort();
      bool handshakeDone = false;
      final readyCompleter = Completer<bool>();

      // Single listener handles both the handshake and ongoing inference results
      _mainPort!.listen((msg) {
        if (!handshakeDone) {
          if (msg is SendPort) {
            _workerPort = msg;
          } else if (msg == true) {
            handshakeDone = true;
            if (!readyCompleter.isCompleted) readyCompleter.complete(true);
          } else if (msg is String && msg.startsWith('ERROR:')) {
            debugPrint('[TFLiteService] Worker init error: $msg');
            if (!readyCompleter.isCompleted) readyCompleter.complete(false);
          }
        } else {
          if (msg is _ResultMsg) {
            _pending.remove(msg.id)?.complete(msg);
          }
        }
      });

      _isolate = await Isolate.spawn(
        _tfliteWorker,
        _InitMsg(modelBytes, inputSize, _mainPort!.sendPort,
            realClassIndex: realClassIndex,
            cropScale: cropScale,
            useImageNetBgr: useImageNetBgr),
      );

      final ready = await readyCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );

      if (!ready) {
        debugPrint('[TFLiteService] Worker failed to become ready');
        _disposeWorker();
        return false;
      }

      _isLoaded = true;
      debugPrint('[TFLiteService] Worker isolate ready — $modelPath');
      return true;
    } catch (e) {
      debugPrint('[TFLiteService] Failed to load: $e');
      _disposeWorker();
      return false;
    }
  }

  /// Run inference on a camera frame. Returns null when not loaded or on error.
  ///
  /// Execution is fully off the main thread — calling this never blocks
  /// the camera preview or face-detection pipeline.
  Future<TFLiteResult?> run({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required Rect faceBoundingBox,
    required int sensorOrientation,
  }) async {
    if (!_isLoaded || _workerPort == null) {
      debugPrint('[TFLiteService] run() skipped — not loaded');
      return null;
    }
    try {
      final id = _nextId++;
      final completer = Completer<_ResultMsg>();
      _pending[id] = completer;

      _workerPort!.send(_RunMsg(
        id:                id,
        imageData:         TransferableTypedData.fromList([imageBytes]),
        imageWidth:        imageWidth,
        imageHeight:       imageHeight,
        bboxLeft:          faceBoundingBox.left,
        bboxTop:           faceBoundingBox.top,
        bboxRight:         faceBoundingBox.right,
        bboxBottom:        faceBoundingBox.bottom,
        sensorOrientation: sensorOrientation,
        isIOS:             Platform.isIOS,
      ));

      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _pending.remove(id);
          return _ResultMsg(id, error: 'timeout');
        },
      );

      if (result.error != null) {
        debugPrint('[TFLiteService] Inference error: ${result.error}');
        return null;
      }
      if (result.realScore == null) return null;

      final r = result.realScore!;
      debugPrint('[TFLiteService] Inference OK — realScore: ${r.toStringAsFixed(3)}');
      return TFLiteResult(
        isReal:     r > 0.5,
        realScore:  r,
        spoofScore: result.spoofScore ?? (1.0 - r),
      );
    } catch (e, st) {
      debugPrint('[TFLiteService] run() error: $e\n$st');
      return null;
    }
  }

  void dispose() => _disposeWorker();

  void _disposeWorker() {
    _workerPort?.send(const _DisposeMsg()); // graceful shutdown
    _isolate?.kill(priority: Isolate.immediate);
    _mainPort?.close();
    _isolate    = null;
    _workerPort = null;
    _mainPort   = null;
    _isLoaded   = false;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('TFLiteService disposed'));
    }
    _pending.clear();
  }
}
