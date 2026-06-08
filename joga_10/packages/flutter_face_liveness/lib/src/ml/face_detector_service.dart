import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

import '../models/face_data.dart';
import '../models/face_mesh_data.dart';
import '../models/frame_quality.dart';
import 'frame_processor.dart';

/// Raw frame metadata forwarded to FaceIdentityService when enableFaceId is on.
///
/// [imageBytes] contains NV21 bytes on Android, BGRA8888 bytes on iOS —
/// matching exactly what [FacePreprocessor.prepare] expects for each platform.
class RawFrameData {
  const RawFrameData({
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.sensorOrientation,
  });
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final int sensorOrientation;
}

/// Result bundle returned per camera frame.
class FaceDetectionResult {
  const FaceDetectionResult({
    required this.faces,
    required this.quality,
    this.rawFrame,
    this.meshData,
  });

  final List<FaceData> faces;
  final FrameQuality quality;

  /// Present only when [LivenessConfig.enableFaceId] is true.
  final RawFrameData? rawFrame;

  /// Present only when [LivenessConfig.enableFaceMesh] is true.
  /// Refreshed every 3rd frame; holds the previous result on skip frames.
  final FaceMeshData? meshData;
}

/// Wraps Google ML Kit face detection and optionally Face Mesh detection.
///
/// Heavy per-frame work (YUV→NV21 conversion + brightness/blur/hash analysis)
/// runs in a background isolate via [FrameProcessor] so the UI thread stays
/// free for 60 fps rendering.
///
/// When [enableFaceMesh] is true, a [FaceMeshDetector] runs every 3rd frame
/// alongside face detection, populating [FaceDetectionResult.meshData].
/// The 3-frame cadence keeps CPU load low while still refreshing accessory
/// and depth signals at ~7 fps (at a 20 fps camera rate).
class FaceDetectorService {
  late final FaceDetector _detector;
  FaceMeshDetector? _meshDetector;
  bool _isDisposed  = false;
  int  _frameCount  = 0;
  FaceMeshData? _lastMeshData;

  FaceDetectorService({bool enableFaceMesh = false}) {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        enableLandmarks: true,  // needed for eye/nose positions in FaceGeometryAnalyzer
        enableContours: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    if (enableFaceMesh) {
      // FaceMeshDetectorOptions is an enum — .faceMesh gives 468 3-D points.
      _meshDetector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
    }
  }

  /// Process one camera frame.
  ///
  /// Set [captureRawFrame] to `true` (when FaceId is enabled) to attach the
  /// NV21 bytes to the result so the identity service can run the embedding.
  ///
  /// Returns an empty result on error or after dispose.
  Future<FaceDetectionResult> processCameraImage(
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection, {
    bool captureRawFrame = false,
  }) async {
    if (_isDisposed) {
      return const FaceDetectionResult(
        faces: [],
        quality: FrameQuality(brightness: 0.5, blurScore: 200, frameHash: 0),
      );
    }

    try {
      // ── Background isolate: YUV conversion + frame quality ───────────────
      final processed = await FrameProcessor.process(image);
      if (processed == null) {
        return const FaceDetectionResult(
          faces: [],
          quality: FrameQuality(brightness: 0.5, blurScore: 200, frameHash: 0),
        );
      }

      // ── Main thread: ML Kit face detection ───────────────────────────────
      final inputImage = _buildInputImage(
        processed.nv21Bytes,
        image,
        sensorOrientation,
        lensDirection,
      );
      if (inputImage == null) {
        return FaceDetectionResult(faces: [], quality: processed.quality);
      }

      final faces = await _detector.processImage(inputImage);
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final faceData = faces
          .map((f) => FaceData.fromFace(f, imageSize))
          .toList();

      // ── Face Mesh (optional, every 3rd frame) ────────────────────────────
      // Runs after face detection so we skip heavy mesh work on empty frames.
      FaceMeshData? meshData = _lastMeshData;
      if (_meshDetector != null && faceData.isNotEmpty) {
        _frameCount++;
        if (_frameCount % 3 == 0) {
          try {
            final meshes = await _meshDetector!.processImage(inputImage);
            if (meshes.isNotEmpty) {
              _lastMeshData = FaceMeshData.tryFromMesh(meshes.first);
              meshData      = _lastMeshData;
            }
          } catch (e) {
            debugPrint('[FaceDetectorService] FaceMesh error: $e');
          }
        }
      } else if (faceData.isEmpty) {
        // Reset cache when face disappears so stale data isn't applied on re-entry.
        _lastMeshData = null;
        meshData      = null;
      }

      // iOS camera provides BGRA8888; Android provides NV21 (via FrameProcessor).
      // FacePreprocessor.prepare() branches on Platform.isIOS so the bytes must
      // match what each platform branch expects.
      final rawFrame = captureRawFrame
          ? RawFrameData(
              imageBytes: Platform.isIOS
                  ? image.planes[0].bytes   // original BGRA8888 from iOS camera
                  : processed.nv21Bytes,    // NV21 converted by FrameProcessor
              imageWidth:        image.width,
              imageHeight:       image.height,
              sensorOrientation: sensorOrientation,
            )
          : null;

      return FaceDetectionResult(faces: faceData, quality: processed.quality, rawFrame: rawFrame, meshData: meshData);
    } catch (e) {
      debugPrint('[FaceDetectorService] Error: $e');
      return const FaceDetectionResult(
        faces: [],
        quality: FrameQuality(brightness: 0.5, blurScore: 200, frameHash: 0),
      );
    }
  }

  InputImage? _buildInputImage(
    Uint8List nv21Bytes,
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection,
  ) {
    if (Platform.isIOS) {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    return InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotation(sensorOrientation),
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  InputImageRotation _rotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _detector.close();
      await _meshDetector?.close();
    }
  }
}
