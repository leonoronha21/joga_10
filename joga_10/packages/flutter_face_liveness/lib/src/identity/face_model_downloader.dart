import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches the FaceNet TFLite model on first use.
///
/// The model is fetched once from the package's GitHub release, then stored
/// permanently in the app's documents directory. Subsequent calls return
/// instantly from the cache with no network activity.
class FaceModelDownloader {
  static const String _modelFileName = 'ffl_mobile_face_net_v1.tflite';

  /// GitHub Releases download URL for the bundled FaceNet model.
  static const String _modelUrl =
      'https://github.com/sanjaysharmajw/flutter_face_liveness/releases/download/v2.0.0-models/mobile_face_net.tflite';

  /// Fallback mirror (in case primary URL is unavailable).
  static const String _fallbackUrl =
      'https://github.com/shubham0204/FaceRecognition_With_FaceNet_Android/raw/master/app/src/main/assets/facenet.tflite';

  /// Minimum valid file size (sanity check against incomplete downloads).
  static const int _minValidBytes = 1024 * 1024; // 1 MB

  // Progress callback — value 0.0 to 1.0, null when complete
  final void Function(double progress)? onProgress;

  FaceModelDownloader({this.onProgress});

  /// Returns the local path to the cached model, downloading it if needed.
  ///
  /// Throws [FaceModelDownloadException] on failure.
  Future<String> ensureModel() async {
    final dir   = await getApplicationDocumentsDirectory();
    final path  = '${dir.path}/$_modelFileName';
    final file  = File(path);

    if (await _isValid(file)) {
      debugPrint('[FaceModelDownloader] Using cached model at $path');
      return path;
    }

    debugPrint('[FaceModelDownloader] Downloading FaceNet model (~23 MB)…');
    await _download(_modelUrl, file);

    if (!await _isValid(file)) {
      // Primary failed — try fallback
      debugPrint('[FaceModelDownloader] Primary download incomplete, trying fallback…');
      await _download(_fallbackUrl, file);
    }

    if (!await _isValid(file)) {
      throw const FaceModelDownloadException(
        'Failed to download the FaceNet model from both primary and fallback URLs.\n'
        'Check your internet connection and try again.',
      );
    }

    debugPrint('[FaceModelDownloader] Model ready: $path');
    return path;
  }

  Future<bool> _isValid(File file) async {
    if (!await file.exists()) return false;
    final size = await file.length();
    return size >= _minValidBytes;
  }

  Future<void> _download(String url, File dest) async {
    try {
      final request  = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        debugPrint('[FaceModelDownloader] HTTP ${response.statusCode} from $url');
        return;
      }

      final total   = response.contentLength ?? 0;
      int   received = 0;
      final sink    = dest.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
      onProgress?.call(1.0);
    } catch (e) {
      debugPrint('[FaceModelDownloader] Download error from $url: $e');
      if (await dest.exists()) await dest.delete();
    }
  }

  /// Delete the cached model (e.g. to force a re-download after an update).
  static Future<void> clearCache() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_modelFileName');
    if (await file.exists()) await file.delete();
    debugPrint('[FaceModelDownloader] Cache cleared');
  }
}

class FaceModelDownloadException implements Exception {
  const FaceModelDownloadException(this.message);
  final String message;

  @override
  String toString() => 'FaceModelDownloadException: $message';
}
