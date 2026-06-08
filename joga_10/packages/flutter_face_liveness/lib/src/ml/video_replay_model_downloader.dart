import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches the MiniFASNet-V2 video-replay detection model.
///
/// Auto-downloads on first use; subsequent sessions load from cache instantly.
class VideoReplayModelDownloader {
  static const String _modelFileName = 'ffl_video_replay_v1.tflite';
  static const int _minValidBytes = 256 * 1024; // 256 KB

  /// Default bundled model — MiniFASNet-V2-SE, input 80×80, output [spoof, real].
  static const String bundledModelUrl =
      'https://github.com/sanjaysharmajw/flutter_face_liveness/releases/download/v2.0.0-models/MiniFASNetV2.tflite';

  /// Input size expected by the bundled model (square).
  static const int bundledInputSize = 80;

  /// Output index for the "real" class: MiniFASNet outputs [spoof, real],
  /// so index 1 is the real-face score.
  static const int bundledRealClassIndex = 1;

  /// Crop scale for MiniFASNet: 2.7× the face bounding-box size.
  /// A larger crop is required so the model can see screen-reflection and
  /// moiré artefacts that indicate a replay attack.
  static const double bundledCropScale = 2.7;

  /// MiniFASNet was trained with BGR channels and ImageNet normalization.
  static const bool bundledUseImageNetBgr = true;

  final String modelUrl;
  final String? fallbackUrl;
  final void Function(double progress)? onProgress;

  VideoReplayModelDownloader({
    required this.modelUrl,
    this.fallbackUrl,
    this.onProgress,
  });

  Future<String> ensureModel() async {
    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_modelFileName';
    final file = File(path);

    if (await _isValid(file)) {
      debugPrint('[VideoReplayModelDownloader] Using cached model at $path');
      return path;
    }

    debugPrint('[VideoReplayModelDownloader] Downloading video-replay model…');
    await _download(modelUrl, file);

    if (!await _isValid(file) && fallbackUrl != null) {
      debugPrint('[VideoReplayModelDownloader] Primary failed, trying fallback…');
      await _download(fallbackUrl!, file);
    }

    if (!await _isValid(file)) {
      throw VideoReplayModelDownloadException(
        'Failed to download video-replay model.\n'
        'URL: $modelUrl\n'
        'Upload MiniFASNetV2.tflite to your GitHub releases or set videoReplayModelUrl.',
      );
    }

    debugPrint('[VideoReplayModelDownloader] Model ready: $path');
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
        debugPrint('[VideoReplayModelDownloader] HTTP ${response.statusCode} from $url');
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
      debugPrint('[VideoReplayModelDownloader] Error from $url: $e');
      if (await dest.exists()) await dest.delete();
    }
  }

  static Future<void> clearCache() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_modelFileName');
    if (await file.exists()) await file.delete();
    debugPrint('[VideoReplayModelDownloader] Cache cleared');
  }
}

class VideoReplayModelDownloadException implements Exception {
  const VideoReplayModelDownloadException(this.message);
  final String message;

  @override
  String toString() => 'VideoReplayModelDownloadException: $message';
}
