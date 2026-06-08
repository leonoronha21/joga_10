import 'dart:io';
import 'dart:math' as math;


import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_model_downloader.dart';

/// Wraps the FaceNet TFLite model (auto-downloaded on first use).
///
/// Architecture : FaceNet (float32)
/// Input        : [1, 160, 160, 3] — pixel values normalised to [-1, 1]
/// Output       : [1, 128]         — L2-normalised face embedding
class FaceEmbeddingModel {
  static const int inputSize    = 160;
  static const int embeddingSize = 128;

  Interpreter? _interpreter;

  bool get isLoaded => _interpreter != null;

  /// Downloads the model if needed, then loads it into the TFLite interpreter.
  ///
  /// [onProgress] receives 0.0–1.0 while downloading (null when loading from cache).
  Future<void> load({void Function(double)? onProgress}) async {
    final downloader = FaceModelDownloader(onProgress: onProgress);
    final modelPath  = await downloader.ensureModel();

    try {
      final opts = InterpreterOptions()..threads = 2;
      _interpreter = Interpreter.fromFile(File(modelPath), options: opts);
      _interpreter!.allocateTensors();
      debugPrint('[FaceEmbeddingModel] FaceNet loaded from $modelPath');
    } catch (e) {
      _interpreter = null;
      // Corrupted cache — delete and rethrow so the next call re-downloads
      await FaceModelDownloader.clearCache();
      throw Exception('[FaceEmbeddingModel] Load failed (cache cleared): $e');
    }
  }

  /// Returns an L2-normalised 128-dim face embedding, or `null` on error.
  ///
  /// [input] must be a [Float32List] of length `160 * 160 * 3`,
  /// with pixel values in the range [-1, 1].
  List<double>? infer(Float32List input) {
    if (_interpreter == null) return null;
    try {
      final inputTensor  = input.reshape([1, inputSize, inputSize, 3]);
      final outputBuffer = [List<double>.filled(embeddingSize, 0.0)];
      _interpreter!.run(inputTensor, outputBuffer);
      return _l2Normalize(outputBuffer[0]);
    } catch (e) {
      debugPrint('[FaceEmbeddingModel] Inference error: $e');
      return null;
    }
  }

  static List<double> _l2Normalize(List<double> v) {
    double norm = 0.0;
    for (final x in v) { norm += x * x; }
    norm = math.sqrt(norm);
    if (norm < 1e-10) return v;
    return v.map((x) => x / norm).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
