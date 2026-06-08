import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/liveness_config.dart';

/// Manages camera lifecycle, stream access, and frame throttling.
class CameraService {
  CameraController? _controller;
  bool _isProcessingFrame = false;
  int _lastProcessedMs = 0;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize({
    required CameraDescription camera,
    required LivenessConfig config,
    required Future<void> Function(CameraImage image) onFrame,
  }) async {
    await dispose();

    _controller = CameraController(
      camera,
      config.cameraResolution,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    // Attempt to set focus and exposure for optimal face capture
    try {
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (_) {
      // Not all devices support manual focus/exposure control
    }

    await _controller!.startImageStream(
      (image) => _onCameraImage(image, onFrame, config.frameThrottleMs),
    );
  }

  void _onCameraImage(
    CameraImage image,
    Future<void> Function(CameraImage) onFrame,
    int throttleMs,
  ) async {
    if (_controller == null || _isProcessingFrame) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastProcessedMs < throttleMs) return;

    _isProcessingFrame = true;
    _lastProcessedMs = nowMs;

    try {
      await onFrame(image);
    } catch (e) {
      debugPrint('[CameraService] Frame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<List<CameraDescription>> getAvailableCameras() =>
      availableCameras();

  Future<CameraDescription?> getFrontCamera() async {
    final cameras = await getAvailableCameras();
    try {
      return cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      return cameras.isNotEmpty ? cameras.first : null;
    }
  }

  Future<void> dispose() async {
    final ctrl = _controller;
    _controller = null;
    _isProcessingFrame = false;
    if (ctrl == null) return;
    try {
      if (ctrl.value.isStreamingImages) await ctrl.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));
      await ctrl.dispose();
    } catch (e) {
      debugPrint('[CameraService] Dispose error (ignored): $e');
    }
  }
}
