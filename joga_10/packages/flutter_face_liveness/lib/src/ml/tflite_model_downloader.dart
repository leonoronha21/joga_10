import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches a TFLite anti-spoof model on first use.
///
/// Mirrors the [FaceModelDownloader] pattern: the model is fetched once from
/// [modelUrl], stored permanently in the app documents directory, and returned
/// instantly from cache on all subsequent calls.
class TFLiteModelDownloader {
  static const String _modelFileName = 'ffl_anti_spoof_v1.tflite';

  /// Minimum valid file size — guards against incomplete downloads.
  static const int _minValidBytes = 512 * 1024; // 512 KB

  /// Default bundled anti-spoof model — used automatically when
  /// [LivenessConfig.enableTFLite] is true and no custom URL/path is set.
  static const String bundledModelUrl =
      'https://github.com/sanjaysharmajw/flutter_face_liveness/releases/download/v2.0.0-models/FaceAntiSpoofing.tflite';

  /// Input size required by the bundled model.
  static const int bundledInputSize = 256;

  /// Remote URL to download the model from.
  final String modelUrl;

  /// Optional fallback URL tried if [modelUrl] returns a bad response.
  final String? fallbackUrl;

  /// Called with 0.0–1.0 during download; not called when served from cache.
  final void Function(double progress)? onProgress;

  TFLiteModelDownloader({
    required this.modelUrl,
    this.fallbackUrl,
    this.onProgress,
  });

  /// Returns the absolute filesystem path to the cached model, downloading it
  /// first if it is missing or corrupted.
  ///
  /// Throws [TFLiteModelDownloadException] when both primary and fallback fail.
  Future<String> ensureModel() async {
    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_modelFileName';
    final file = File(path);

    if (await _isValid(file)) {
      debugPrint('[TFLiteModelDownloader] Using cached model at $path');
      return path;
    }

    debugPrint('[TFLiteModelDownloader] Downloading TFLite anti-spoof model…');
    await _download(modelUrl, file);

    if (!await _isValid(file) && fallbackUrl != null) {
      debugPrint('[TFLiteModelDownloader] Primary download incomplete, trying fallback…');
      await _download(fallbackUrl!, file);
    }

    if (!await _isValid(file)) {
      throw TFLiteModelDownloadException(
        'Failed to download TFLite anti-spoof model.\n'
        'Primary URL: $modelUrl\n'
        'Check your internet connection or set a valid tfliteModelUrl.',
      );
    }

    debugPrint('[TFLiteModelDownloader] Model ready: $path');
    return path;
  }

  Future<bool> _isValid(File file) async {
    if (!await file.exists()) return false;
    return await file.length() >= _minValidBytes;
  }

  Future<void> _download(String url, File dest) async {
    try {
      final request  = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        debugPrint('[TFLiteModelDownloader] HTTP ${response.statusCode} from $url');
        return;
      }

      final total    = response.contentLength ?? 0;
      int   received = 0;
      final sink     = dest.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
      onProgress?.call(1.0);
    } catch (e) {
      debugPrint('[TFLiteModelDownloader] Download error from $url: $e');
      if (await dest.exists()) await dest.delete();
    }
  }

  /// Delete the cached model to force a fresh download next time.
  static Future<void> clearCache() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_modelFileName');
    if (await file.exists()) await file.delete();
    debugPrint('[TFLiteModelDownloader] Cache cleared');
  }
}

class TFLiteModelDownloadException implements Exception {
  const TFLiteModelDownloadException(this.message);
  final String message;

  @override
  String toString() => 'TFLiteModelDownloadException: $message';
}
