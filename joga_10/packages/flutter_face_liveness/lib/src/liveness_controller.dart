import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:math' show min;
import 'dart:ui' show Rect;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'models/face_data.dart';
import 'models/face_mesh_data.dart';
import 'models/liveness_action.dart';
import 'models/liveness_config.dart';
import 'models/liveness_result.dart';
import 'models/detection_status.dart';
import 'models/frame_quality.dart';
import 'camera/camera_service.dart';
import 'ml/face_detector_service.dart';
import 'ml/tflite_service.dart';
import 'ml/tflite_model_downloader.dart';
import 'ml/video_replay_model_downloader.dart';
import 'liveness/liveness_engine.dart';
import 'identity/face_identity_service.dart';
import 'analysis/replay_analyzer.dart';
import 'analysis/screen_artifact_detector.dart';
import 'analysis/optical_flow_analyzer.dart';
import 'analysis/face_geometry_analyzer.dart';

/// ChangeNotifier that drives the full liveness verification session.
///
/// Lifecycle: [initialize] → frames processed automatically → callbacks fired.
class LivenessController extends ChangeNotifier {
  LivenessController({
    required List<LivenessAction> actions,
    required this.onSuccess,
    required this.onFailed,
    LivenessConfig config = const LivenessConfig(),
  })  : _actions = actions,
        _config = config {
    _faceDetector = FaceDetectorService(enableFaceMesh: config.enableFaceMesh);
  }

  final List<LivenessAction> _actions;
  final LivenessConfig _config;
  final void Function(LivenessResult result) onSuccess;
  final void Function(String reason) onFailed;

  final CameraService _cameraService = CameraService();
  late final FaceDetectorService _faceDetector;
  TFLiteService? _tflite;
  TFLiteService? _videoReplay;
  FaceIdentityService? _faceIdentity;
  LivenessEngine? _engine;

  bool _isInitialized = false;
  bool _isDisposed = false;
  FaceData? _currentFace;
  FrameQuality? _lastQuality;
  RawFrameData? _lastRawFrame;
  FaceMeshData? _lastMeshData;

  // Up to 5 frontal frames collected during the session (|yaw|+|pitch| < 15°).
  // Their embeddings are averaged at session end for a stable identity estimate.
  static const int _maxFrontalFrames = 7;
  static const double _frontalAngleLimit = 20.0;
  final List<({RawFrameData raw, FaceData face})> _frontalFrames = [];
  // Best single frontal frame — fallback if no frames pass the angle limit.
  RawFrameData? _bestFrontalFrame;
  FaceData? _bestFrontalFace;
  double _bestFrontalScore = double.infinity;
  String? _error;
  double? _faceIdModelDownloadProgress;
  double? _tfliteModelDownloadProgress;
  String? _tfliteWarning;
  double? _lastTfliteScore;
  bool _isTfliteRunning = false;
  Future<void>? _tfliteFuture;

  double? _lastVideoReplayScore;
  bool _isVideoReplayRunning = false;
  Future<void>? _videoReplayFuture;

  // Temporal brightness variance history — secondary AEC-sensitive signal.
  final _faceCropBrightnessHistory = <double>[];
  double? _liveHeuristicScore;

  // Spatial Laplacian variance history — per-frame texture signal.
  final _faceCropLaplacianHistory = <double>[];
  double? _liveLaplacianScore;

  // Motion-heterogeneity tracker — 3×3 = 9 face-crop regions, each with its own
  // brightness history. The spatial CV of per-region temporal variances is
  // AEC-invariant: AEC scales all regions uniformly (low CV), while a real face
  // changes non-uniformly across regions (muscle/lighting asymmetry → high CV).
  static const _hetGridSize = 3;
  static const _hetRegions = _hetGridSize * _hetGridSize; // 9
  final _hetHistory = List.generate(_hetRegions, (_) => <double>[]);
  double? _liveHetScore;

  // ReplayAnalyzer — perceptual fingerprinting + angular micro-jitter + entropy + blink.
  final _replayAnalyzer = ReplayAnalyzer();
  double? _liveReplayScore;

  // ── New on-device anti-spoof analyzers ─────────────────────────────────────
  // S6 – Screen artifact detector (specular highlights, skin warmth, temporal stability)
  final _screenDetector = ScreenArtifactDetector();
  double? _liveScreenScore;

  // S7 – Optical flow (block-MAD stasis + spatial variance of block energies)
  final _flowAnalyzer = OpticalFlowAnalyzer();
  double? _liveFlowScore;

  // S8 – Face geometry (eye symmetry, eye ratio, 3-D depth consistency, landmark velocity)
  final _geoAnalyzer = FaceGeometryAnalyzer();
  double? _liveGeoScore;

  // ── Public getters ──────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;

  /// True when [LivenessConfig.enableTFLite] is set and the model loaded
  /// successfully. False means [LivenessResult.tfliteScore] will be null.
  bool get isTFLiteLoaded => _tflite != null;

  /// Non-null when [enableTFLite] is true but the model could not be loaded
  /// (download failed, model file missing, or corrupted cache).
  String? get tfliteWarning => _tfliteWarning;

  /// Non-null (0.0–1.0) while the TFLite anti-spoof model is being downloaded
  /// for the first time. Null when loading from cache or when complete.
  double? get tfliteModelDownloadProgress => _tfliteModelDownloadProgress;

  /// Non-null (0.0–1.0) while the FaceNet model is being downloaded for the
  /// first time. Null when loading from cache or when download is complete.
  double? get faceIdModelDownloadProgress => _faceIdModelDownloadProgress;
  FaceData? get currentFace => _currentFace;
  FrameQuality? get lastQuality => _lastQuality;
  double? get lastVideoReplayScore => _lastVideoReplayScore;
  double? get lastTfliteScore => _lastTfliteScore;
  double? get liveHeuristicScore => _liveHeuristicScore;
  double? get liveLaplacianScore => _liveLaplacianScore;
  double? get liveHetScore => _liveHetScore;
  double? get liveReplayScore => _liveReplayScore;
  double? get liveScreenScore => _liveScreenScore;
  double? get liveFlowScore => _liveFlowScore;
  double? get liveGeoScore => _liveGeoScore;

  /// 3-D depth plausibility from Face Mesh (0.0 = flat/spoof, 1.0 = real face).
  /// Non-null only when [LivenessConfig.enableFaceMesh] is true and a face is detected.
  double? get liveMeshDepthScore => _lastMeshData?.depth3DScore;
  String? get error => _error;
  CameraController? get cameraController => _cameraService.controller;

  DetectionStatus get status =>
      _isInitialized ? _engine!.status : DetectionStatus.initializing;
  LivenessAction? get currentAction =>
      _isInitialized ? _engine!.currentAction : null;
  double get progress => _isInitialized ? _engine!.progress : 0.0;
  int get completedCount =>
      _isInitialized ? _engine!.completedActions.length : 0;
  int get totalActions => _actions.length;
  bool get isComplete => _isInitialized && (_engine?.isComplete ?? false);
  String? get sessionId => _isInitialized ? _engine!.sessionId : null;
  LivenessConfig get config => _config;
  List<LivenessAction> get completedActions =>
      _isInitialized ? _engine!.completedActions : const [];
  List<LivenessAction> get remainingActions =>
      _isInitialized ? _engine!.remainingActions : _actions;

  // ── Initialisation ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      // TFLite anti-spoof model (optional)
      if (_config.enableTFLite) {
        try {
          String? modelPath = _config.tfliteModelPath;

          // Resolve download URL: prefer user-supplied, fall back to bundled default
          final downloadUrl =
              _config.tfliteModelUrl ?? TFLiteModelDownloader.bundledModelUrl;

          // Auto-download when no local path is set
          if (modelPath == null) {
            final downloader = TFLiteModelDownloader(
              modelUrl: downloadUrl,
              onProgress: (p) {
                _tfliteModelDownloadProgress = p;
                notifyListeners();
              },
            );
            modelPath = await downloader.ensureModel();
            if (_isDisposed) return;
            _tfliteModelDownloadProgress = null;
            notifyListeners();
          }

          // Resolve input size: prefer user-supplied, otherwise use bundled model's size
          final inputSize = _config.tfliteInputSize ??
              (_config.tfliteModelPath == null && _config.tfliteModelUrl == null
                  ? TFLiteModelDownloader.bundledInputSize
                  : 128);

          _tflite = TFLiteService(modelPath: modelPath, inputSize: inputSize);
          final loaded = await _tflite!.load();
          if (!loaded) {
            // Corrupted or wrong model — wipe the cache so next launch re-downloads
            if (!modelPath.startsWith('assets/')) {
              await TFLiteModelDownloader.clearCache();
              debugPrint(
                  '[LivenessController] Corrupted TFLite cache cleared — will re-download next launch');
            }
            _tfliteWarning =
                'Não foi possível preparar a verificação de segurança. Reinicie o app e tente novamente.';
            _tflite = null;
          }
        } catch (e) {
          debugPrint(
              '[LivenessController] TFLite unavailable this session: $e');
          _tfliteWarning =
              'A verificação de segurança está indisponível neste momento.';
          _tflite = null;
          _tfliteModelDownloadProgress = null;
        }
      }

      // MiniFASNet video-replay detection model (optional)
      if (_config.enableVideoReplayDetection) {
        try {
          String? modelPath = _config.videoReplayModelPath;
          final downloadUrl = _config.videoReplayModelUrl ??
              VideoReplayModelDownloader.bundledModelUrl;
          if (modelPath == null) {
            final downloader = VideoReplayModelDownloader(
              modelUrl: downloadUrl,
              onProgress: (p) {
                _tfliteModelDownloadProgress = p;
                notifyListeners();
              },
            );
            modelPath = await downloader.ensureModel();
            if (_isDisposed) return;
            _tfliteModelDownloadProgress = null;
            notifyListeners();
          }
          final inputSize = _config.videoReplayInputSize ??
              (_config.videoReplayModelPath == null &&
                      _config.videoReplayModelUrl == null
                  ? VideoReplayModelDownloader.bundledInputSize
                  : 80);
          final isCustomModel = _config.videoReplayModelPath != null ||
              _config.videoReplayModelUrl != null;
          _videoReplay = TFLiteService(
            modelPath: modelPath,
            inputSize: inputSize,
            realClassIndex: VideoReplayModelDownloader.bundledRealClassIndex,
            cropScale: isCustomModel
                ? 1.4
                : VideoReplayModelDownloader.bundledCropScale,
            useImageNetBgr: isCustomModel
                ? false
                : VideoReplayModelDownloader.bundledUseImageNetBgr,
          );
          final loaded = await _videoReplay!.load();
          if (!loaded) {
            if (!modelPath.startsWith('assets/')) {
              await VideoReplayModelDownloader.clearCache();
            }
            debugPrint(
                '[LivenessController] VideoReplay model FAILED to load — path=$modelPath');
            _videoReplay = null;
          } else {
            debugPrint(
                '[LivenessController] VideoReplay model loaded OK — path=$modelPath inputSize=$inputSize realClassIndex=${VideoReplayModelDownloader.bundledRealClassIndex}');
          }
        } catch (e) {
          debugPrint('[LivenessController] VideoReplay unavailable: $e');
          _videoReplay = null;
          _tfliteModelDownloadProgress = null;
        }
      }

      // FaceNet face identity — auto-downloads model on first run (optional).
      // Failure is isolated: a bad download or corrupted cache disables Face ID
      // for this session but does not block camera or liveness from starting.
      if (_config.enableFaceId) {
        try {
          _faceIdentity = FaceIdentityService(
            similarityThreshold: _config.faceIdSimilarityThreshold,
            registrationDuplicateThreshold:
                _config.registrationDuplicateThreshold,
            minEmbeddingQuality: _config.minEmbeddingQuality,
            mode: _config.faceIdMode,
          );
          await _faceIdentity!.initialize(
            onModelDownloadProgress: (p) {
              _faceIdModelDownloadProgress = p;
              notifyListeners();
            },
          );
          if (_isDisposed) return;
          _faceIdModelDownloadProgress = null;
          notifyListeners();
        } catch (e) {
          debugPrint(
              '[LivenessController] FaceId unavailable this session: $e');
          _faceIdentity = null;
          _faceIdModelDownloadProgress = null;
        }
      }

      _engine = LivenessEngine(
        requiredActions: _actions,
        config: _config,
        onActionCompleted: (_) => notifyListeners(),
        onStatusChanged: (_) => notifyListeners(),
        onAllActionsCompleted: (r) => _onEngineComplete(r),
      );

      if (_isDisposed) return;

      final camera = await _cameraService.getFrontCamera();
      if (camera == null) {
        _error = 'No front camera available';
        notifyListeners();
        return;
      }

      await _cameraService.initialize(
        camera: camera,
        config: _config,
        onFrame: (image) => _processFrame(image, camera),
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error =
          'Não foi possível iniciar a câmera. Verifique a permissão da câmera e tente novamente.';
      notifyListeners();
    }
  }

  // ── Per-frame pipeline ──────────────────────────────────────────────────

  Future<void> _processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (_isDisposed || !_isInitialized) return;

    final result = await _faceDetector.processCameraImage(
      image,
      camera.sensorOrientation,
      camera.lensDirection,
      captureRawFrame: _config.enableFaceId ||
          _config.enableTFLite ||
          _config.enableVideoReplayDetection,
    );

    if (_isDisposed) return;

    _currentFace = result.faces.isNotEmpty ? result.faces.first : null;
    _lastQuality = result.quality;
    if (result.rawFrame != null) _lastRawFrame = result.rawFrame;
    if (result.meshData != null) _lastMeshData = result.meshData;

    // Collect frontal frames for Face ID — multiple frames are averaged at
    // session end for a stable embedding (single-frame embeddings are noisy).
    if (_config.enableFaceId &&
        _currentFace != null &&
        result.rawFrame != null) {
      final frontality = _currentFace!.headEulerAngleY.abs() +
          _currentFace!.headEulerAngleX.abs();
      // Best single frame (fallback)
      if (frontality < _bestFrontalScore) {
        _bestFrontalScore = frontality;
        _bestFrontalFrame = result.rawFrame;
        _bestFrontalFace = _currentFace;
      }
      // Only collect frames where eye landmarks are available — these produce
      // eye-aligned embeddings. Bbox-fallback embeddings are too noisy to average.
      if (frontality < _frontalAngleLimit &&
          _frontalFrames.length < _maxFrontalFrames &&
          _currentFace!.leftEyePosition != null &&
          _currentFace!.rightEyePosition != null) {
        _frontalFrames.add((raw: result.rawFrame!, face: _currentFace!));
      }
    }

    // Fire TFLite anti-spoof inference async; result is stored in _lastTfliteScore
    // and attached to LivenessResult at session end. Guard with _isTfliteRunning
    // so frames don't queue up if inference is slower than the camera rate.
    final rawForTflite = result.rawFrame ?? _lastRawFrame;
    final faceForTflite = _currentFace;
    if (_tflite != null && !_isTfliteRunning) {
      if (rawForTflite == null) {
        debugPrint('[LivenessController] TFLite skip — rawFrame null');
      } else if (faceForTflite == null) {
        debugPrint('[LivenessController] TFLite skip — no face detected');
      } else {
        _isTfliteRunning = true;
        _tfliteFuture = _tflite!
            .run(
          imageBytes: rawForTflite.imageBytes,
          imageWidth: rawForTflite.imageWidth,
          imageHeight: rawForTflite.imageHeight,
          faceBoundingBox: faceForTflite.boundingBox,
          sensorOrientation: rawForTflite.sensorOrientation,
        )
            .then((tfliteResult) {
          if (_isDisposed) return;
          _isTfliteRunning = false;
          if (tfliteResult != null) {
            _lastTfliteScore = tfliteResult.realScore;
            if (_tfliteWarning != null) {
              _tfliteWarning =
                  null; // clear stale warning once inference succeeds
              notifyListeners();
            }
          } else {
            _tfliteWarning =
                'Não foi possível concluir uma etapa da verificação de segurança.';
            notifyListeners();
          }
          _tfliteFuture = null;
        });
        unawaited(_tfliteFuture!);
      }
    }

    // Video-replay inference (MiniFASNet) — same guard pattern as TFLite
    if (_videoReplay != null && !_isVideoReplayRunning) {
      if (rawForTflite != null && faceForTflite != null) {
        _isVideoReplayRunning = true;
        _videoReplayFuture = _videoReplay!
            .run(
          imageBytes: rawForTflite.imageBytes,
          imageWidth: rawForTflite.imageWidth,
          imageHeight: rawForTflite.imageHeight,
          faceBoundingBox: faceForTflite.boundingBox,
          sensorOrientation: rawForTflite.sensorOrientation,
        )
            .then((r) {
          if (_isDisposed) return;
          _isVideoReplayRunning = false;
          if (r != null) _lastVideoReplayScore = r.realScore;
          _videoReplayFuture = null;
        });
        unawaited(_videoReplayFuture!);
      }
    }

    // Anti-replay heuristics — computed every frame with a detected face.
    if (_config.enableVideoReplayDetection &&
        rawForTflite != null &&
        faceForTflite != null) {
      // Signal 1: temporal brightness variance (secondary — AEC can neutralise this)
      final b = _faceCropBrightness(rawForTflite, faceForTflite.boundingBox);
      _faceCropBrightnessHistory.add(b);
      if (_faceCropBrightnessHistory.length > 60) {
        _faceCropBrightnessHistory.removeAt(0);
      }
      if (_faceCropBrightnessHistory.length >= 10) {
        final v = _faceCropBrightnessVariance();
        _liveHeuristicScore = (v / 0.0005).clamp(0.0, 1.0);
        debugPrint(
            '[VR-BRIGHT] brightVar=${v.toStringAsFixed(7)} score=${_liveHeuristicScore!.toStringAsFixed(3)}');
      }

      // Signal 2: spatial Laplacian variance (per-frame texture)
      // Real face: natural skin pores/wrinkles → high Laplacian variance.
      // Screen video: H.264 compression smooths micro-texture → low Laplacian variance.
      final lap =
          _faceCropLaplacianVariance(rawForTflite, faceForTflite.boundingBox);
      _faceCropLaplacianHistory.add(lap);
      if (_faceCropLaplacianHistory.length > 60) {
        _faceCropLaplacianHistory.removeAt(0);
      }
      if (_faceCropLaplacianHistory.isNotEmpty) {
        _liveLaplacianScore =
            _faceCropLaplacianHistory.reduce((a, b) => a + b) /
                _faceCropLaplacianHistory.length;
        debugPrint('[VR-LAP] lapVar=${_liveLaplacianScore!.toStringAsFixed(1)} '
            'score=${(_liveLaplacianScore! / 400.0).clamp(0.0, 1.0).toStringAsFixed(3)}');
      }

      // Signal 3: motion heterogeneity (AEC-invariant)
      // Tracks 9 face regions; CV of per-region temporal variances is high for
      // real faces (non-uniform motion) and low when AEC dominates (screen replay).
      _updateRegionBrightness(rawForTflite, faceForTflite.boundingBox);
      final het = _motionHeterogeneityScore();
      if (het != null) {
        _liveHetScore = het;
        debugPrint('[VR-HET] het=${het.toStringAsFixed(5)} '
            'score=${(het / 0.05).clamp(0.0, 1.0).toStringAsFixed(3)}');
      }

      // Signal 4: ReplayAnalyzer — perceptual fingerprint + angular micro-jitter
      //           + motion direction entropy + blink consistency.
      final fingerprint = computeFaceFingerprint(
        rawForTflite,
        faceForTflite.boundingBox.left,
        faceForTflite.boundingBox.top,
        faceForTflite.boundingBox.right,
        faceForTflite.boundingBox.bottom,
      );
      _replayAnalyzer.addSnapshot(FrameSnapshot(
        fingerprint: fingerprint,
        eulerYaw: faceForTflite.headEulerAngleY,
        eulerPitch: faceForTflite.headEulerAngleX,
        faceAreaRatio: faceForTflite.faceAreaRatio,
        leftEyeOpen: faceForTflite.leftEyeOpenProbability,
        rightEyeOpen: faceForTflite.rightEyeOpenProbability,
      ));
      _liveReplayScore = _replayAnalyzer.liveScore;

      // Signal 5: screen artifact detection (specular highlights, skin warmth, stability)
      final bbox = faceForTflite.boundingBox;
      final bboxRecord = (
        left: bbox.left,
        top: bbox.top,
        right: bbox.right,
        bottom: bbox.bottom,
      );
      _screenDetector.processFrame(rawForTflite, bboxRecord);
      _liveScreenScore = _screenDetector.liveScore;

      // Signal 6: optical flow (block-MAD stasis + spatial variance)
      _flowAnalyzer.processFrame(rawForTflite, bboxRecord);
      _liveFlowScore = _flowAnalyzer.liveScore;
    }

    // Signal 7: face geometry — runs on every face-detected frame,
    // not just when enableVideoReplayDetection is set (geometry is always cheap).
    if (_currentFace != null) {
      _geoAnalyzer.processFrame(_currentFace!);
      _liveGeoScore = _geoAnalyzer.liveScore;
    }

    _engine?.processFrame(result.faces,
        quality: result.quality, meshData: result.meshData);
    notifyListeners();
  }

  Future<void> _onEngineComplete(LivenessResult result) async {
    var finalResult = result;

    // If a TFLite inference is still running, wait for it before reading the score.
    // Without this await the score is always null (race condition: session completes
    // on the same frame that fired the last unawaited inference).
    if (_isTfliteRunning && _tfliteFuture != null) {
      await _tfliteFuture;
    }

    // Await any in-flight video-replay inference
    if (_isVideoReplayRunning && _videoReplayFuture != null) {
      await _videoReplayFuture;
    }

    // ── Multi-signal video-replay / presentation-attack detection ──────────
    // Three independent signals are combined; the most suspicious one wins.
    //
    //  S1 – Spatial Laplacian variance (PRIMARY, AEC-immune)
    //       Measures per-frame skin micro-texture richness.
    //       Real face  → high (natural pores/wrinkles/highlights).
    //       Screen/print → low (H.264 compression smooths fine detail).
    //
    //  S2 – Temporal brightness variance (SECONDARY)
    //       Screen backlight is very stable; natural room light fluctuates.
    //       Camera AEC can partially neutralise this, so it is not the sole signal.
    //
    //  S3 – MiniFASNet model (TERTIARY, only when non-degenerate score < 0.85)
    if (_config.enableVideoReplayDetection) {
      // S1 — Spatial Laplacian variance (texture richness per frame)
      final meanLap = _faceCropLaplacianHistory.isNotEmpty
          ? _faceCropLaplacianHistory.reduce((a, b) => a + b) /
              _faceCropLaplacianHistory.length
          : null;
      final lapScore = (meanLap != null && meanLap > 0)
          ? (meanLap / 400.0).clamp(0.0, 1.0)
          : null;

      // S2 — Temporal brightness variance
      final brightVar = _faceCropBrightnessVariance();
      final brightScore = (brightVar / 0.0005).clamp(0.0, 1.0);

      // S3 — Motion heterogeneity (AEC-invariant CV² of per-region variances)
      // Scale: CV² ≥ 0.05 → score 1.0 (real face); CV² < 0.01 → score < 0.2
      final hetCV2 = _motionHeterogeneityScore();
      final hetScore = hetCV2 != null ? (hetCV2 / 0.05).clamp(0.0, 1.0) : null;

      // S4 — MiniFASNet (skip degenerate ~0.94 outputs)
      final modelScore =
          (_lastVideoReplayScore != null && _lastVideoReplayScore! < 0.85)
              ? _lastVideoReplayScore!
              : null;

      // S5 — ReplayAnalyzer (perceptual fingerprint + micro-jitter + entropy + blink)
      final raResult =
          _replayAnalyzer.buildResult(threshold: _config.videoReplayThreshold);
      debugPrint('[VR-RA] ${raResult.details}');

      // S6 — Screen artifact (specular highlights + skin warmth + temporal stability)
      final screenScore = _screenDetector.liveScore;
      debugPrint('[VR-SCR] screen=${screenScore?.toStringAsFixed(3) ?? "n/a"}');

      // S7 — Optical flow (block-MAD stasis + spatial variance)
      final flowScore = _flowAnalyzer.liveScore;
      debugPrint('[VR-FLOW] flow=${flowScore?.toStringAsFixed(3) ?? "n/a"}');

      // S8 — Face geometry (eye symmetry, eye ratio, depth consistency, landmark velocity)
      final geoScore = _geoAnalyzer.liveScore;
      debugPrint('[VR-GEO] geo=${geoScore?.toStringAsFixed(3) ?? "n/a"}');

      // Combine — two-tier strategy to eliminate false positives on real humans:
      //
      //  SOFT signals (averaged): individually unreliable — stable LED room
      //   lighting keeps brightScore low for real humans; hetScore is low when
      //   the user holds still between actions.  Averaging prevents any single
      //   soft signal from vetoing the whole detection.
      //
      //  HARD signals (min): high-confidence discriminators that are almost
      //   never low for a real human — screenScore (skin warmth + no specular
      //   highlight matches a screen), flowScore (natural motion), geoScore
      //   (3-D face geometry).  A single hard-signal failure still vetoes.
      final softSignals = <double>[brightScore, raResult.overallScore];
      if (lapScore != null) softSignals.add(lapScore);
      if (hetScore != null) softSignals.add(hetScore);
      if (modelScore != null) softSignals.add(modelScore);
      final softScore =
          softSignals.reduce((a, b) => a + b) / softSignals.length;

      double finalScore = softScore;
      if (screenScore != null) finalScore = min(finalScore, screenScore);
      if (flowScore != null) finalScore = min(finalScore, flowScore);
      if (geoScore != null) finalScore = min(finalScore, geoScore);

      final isReplay = finalScore < _config.videoReplayThreshold;
      debugPrint('[LivenessController] VideoReplay — '
          'lap=${meanLap?.toStringAsFixed(1) ?? "n/a"}(${lapScore?.toStringAsFixed(2) ?? "n/a"}) '
          'bright=${brightVar.toStringAsFixed(6)}(${brightScore.toStringAsFixed(2)}) '
          'het=${hetCV2?.toStringAsFixed(5) ?? "n/a"}(${hetScore?.toStringAsFixed(2) ?? "n/a"}) '
          'model=${_lastVideoReplayScore?.toStringAsFixed(3) ?? "n/a"} '
          'final=${finalScore.toStringAsFixed(3)} isReplay=$isReplay');

      finalResult = finalResult.withVideoReplayResult(finalScore,
          videoReplayDetected: isReplay);
    }

    // Attach TFLite score + deepfake flag to the result
    if (_lastTfliteScore != null) {
      final isDeepfake = _lastTfliteScore! < _config.tfliteDeepfakeThreshold;
      finalResult = finalResult.withTfliteResult(
        _lastTfliteScore!,
        deepfakeDetected: isDeepfake,
      );
      if (isDeepfake) {
        debugPrint(
            '[LivenessController] Deepfake flagged — tfliteScore=${_lastTfliteScore!.toStringAsFixed(3)} < threshold=${_config.tfliteDeepfakeThreshold}');
      }
    }

    // Resolve persistent faceId after successful liveness.
    // Average embeddings from multiple frontal frames for a stable identity.
    if (result.isSuccess && _faceIdentity != null) {
      debugPrint(
          '[FaceId] frontalFrames=${_frontalFrames.length}  bestScore=${_bestFrontalScore.toStringAsFixed(1)}°');

      // Determine frames to process: collected frontal frames, or fallback to best single
      final framesToProcess = _frontalFrames.isNotEmpty
          ? _frontalFrames
          : () {
              final raw = _bestFrontalFrame ?? _lastRawFrame;
              final face = _bestFrontalFace ?? _currentFace;
              if (raw != null && face != null) return [(raw: raw, face: face)];
              return <({RawFrameData raw, FaceData face})>[];
            }();

      if (framesToProcess.isNotEmpty) {
        // Compute embedding for each frame in parallel sequence
        final embeddings = <List<double>>[];
        for (final f in framesToProcess) {
          final emb = await _faceIdentity!.computeEmbedding(
            imageBytes: f.raw.imageBytes,
            imageWidth: f.raw.imageWidth,
            imageHeight: f.raw.imageHeight,
            faceBoundingBox: f.face.boundingBox,
            sensorOrientation: f.raw.sensorOrientation,
            leftEyeX: f.face.leftEyePosition?.x,
            leftEyeY: f.face.leftEyePosition?.y,
            rightEyeX: f.face.rightEyePosition?.x,
            rightEyeY: f.face.rightEyePosition?.y,
          );
          if (emb != null) embeddings.add(emb);
        }

        if (embeddings.isNotEmpty) {
          final match = await _faceIdentity!.identifyFromEmbeddings(embeddings);
          if (match != null) {
            if (match.isDuplicate) {
              // registrationOnly mode: face already exists — block registration
              debugPrint(
                  '[FaceId] Registration blocked — duplicate face ${match.faceId}  '
                  'sim=${match.similarity.toStringAsFixed(3)}');
              finalResult = finalResult.withFaceId(
                match.faceId ?? '',
                isNew: false,
                alreadyRegistered: true,
                matchScore: match.similarity,
              );
            } else if (match.isNotFound) {
              // verificationOnly mode: no matching face — fail the session
              debugPrint('[FaceId] Verification failed — face not found  '
                  'bestSim=${match.similarity.toStringAsFixed(3)}');
              onFailed(
                  'Rosto não reconhecido. Faça o cadastro facial primeiro.');
              notifyListeners();
              return;
            } else if (match.faceId != null) {
              finalResult = finalResult.withFaceId(
                match.faceId!,
                isNew: match.isNew,
                matchScore: match.similarity,
              );
            }
          }
        }
      }
    }

    // Block duplicate registration (registrationOnly mode)
    if (finalResult.faceAlreadyRegistered == true) {
      onFailed('Este rosto já está cadastrado.');
      notifyListeners();
      return;
    }

    // Reject session if video replay attack detected, regardless of liveness result
    if (finalResult.videoReplayDetected) {
      final scoreStr = finalResult.videoReplayScore != null
          ? ' (${(finalResult.videoReplayScore! * 100).toStringAsFixed(1)}% real)'
          : '';
      onFailed('Não foi possível confirmar um rosto ao vivo$scoreStr');
      notifyListeners();
      return;
    }

    // Reject session if deepfake detected
    if (finalResult.deepfakeDetected) {
      final scoreStr = finalResult.tfliteScore != null
          ? ' (${(finalResult.tfliteScore! * 100).toStringAsFixed(1)}% real)'
          : '';
      onFailed('Não foi possível confirmar a autenticidade do rosto$scoreStr');
      notifyListeners();
      return;
    }

    if (finalResult.isSuccess) {
      onSuccess(finalResult);
    } else {
      onFailed(
        finalResult.failureReason ??
            'Não foi possível concluir a prova de vida.',
      );
    }
    notifyListeners();
  }

  // ── Face-crop brightness heuristic ─────────────────────────────────────

  /// Computes the mean luminance of the face bounding box in the raw frame.
  /// Sparse sampling (every 8th pixel) keeps this fast on the main thread.
  double _faceCropBrightness(RawFrameData frame, Rect bbox) {
    final bytes = frame.imageBytes;
    final w = frame.imageWidth;
    final h = frame.imageHeight;
    int sum = 0, count = 0;

    if (Platform.isIOS) {
      // BGRA8888 — ML Kit uses rotation 0 on iOS
      final x0 = bbox.left.toInt().clamp(0, w - 1);
      final y0 = bbox.top.toInt().clamp(0, h - 1);
      final x1 = bbox.right.toInt().clamp(0, w);
      final y1 = bbox.bottom.toInt().clamp(0, h);
      for (int y = y0; y < y1; y += 8) {
        for (int x = x0; x < x1; x += 8) {
          final p = (y * w + x) * 4;
          // BT.601 luminance
          sum += (77 * bytes[p + 2] + 150 * bytes[p + 1] + 29 * bytes[p]) >> 8;
          count++;
        }
      }
    } else {
      // NV21 — reverse ML Kit rotation to get sensor-space coordinates
      late double nl, nt, nr, nb;
      switch (frame.sensorOrientation) {
        case 270:
          nl = bbox.top;
          nt = h - 1 - bbox.right;
          nr = bbox.bottom;
          nb = h - 1 - bbox.left;
        case 90:
          nl = w - 1 - bbox.bottom;
          nt = bbox.left;
          nr = w - 1 - bbox.top;
          nb = bbox.right;
        case 180:
          nl = w - 1 - bbox.right;
          nt = h - 1 - bbox.bottom;
          nr = w - 1 - bbox.left;
          nb = h - 1 - bbox.top;
        default:
          nl = bbox.left;
          nt = bbox.top;
          nr = bbox.right;
          nb = bbox.bottom;
      }
      final x0 = nl.toInt().clamp(0, w - 1);
      final y0 = nt.toInt().clamp(0, h - 1);
      final x1 = nr.toInt().clamp(0, w);
      final y1 = nb.toInt().clamp(0, h);
      for (int y = y0; y < y1; y += 8) {
        for (int x = x0; x < x1; x += 8) {
          final idx = y * w + x;
          if (idx < w * h) {
            sum += bytes[idx] & 0xFF;
            count++;
          }
        }
      }
    }
    return count > 0 ? (sum / count) / 255.0 : 0.5;
  }

  /// Temporal variance of face-crop brightness over the last N frames.
  double _faceCropBrightnessVariance() {
    final hist = _faceCropBrightnessHistory;
    if (hist.length < 10) return 1.0; // not enough samples — assume live
    final mean = hist.reduce((a, b) => a + b) / hist.length;
    final variance =
        hist.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            hist.length;
    return variance;
  }

  /// Spatial Laplacian variance of the face crop — single-frame texture measure.
  ///
  /// Computes variance of 4-connected Laplacian responses, sampled every 4th pixel.
  /// This is immune to camera AEC because it measures relative pixel differences
  /// within one captured frame, not across frames.
  ///
  /// High value = texture-rich (real face skin pores / wrinkles / highlights).
  /// Low value  = smooth (H.264-compressed video on a screen, printed photo).
  double _faceCropLaplacianVariance(RawFrameData frame, Rect bbox) {
    final bytes = frame.imageBytes;
    final w = frame.imageWidth;
    final h = frame.imageHeight;

    double sumSq = 0.0, sum = 0.0;
    int count = 0;

    if (Platform.isIOS) {
      // BGRA8888 layout — convert to BT.601 luma
      final x0 = (bbox.left.toInt() + 1).clamp(1, w - 2);
      final y0 = (bbox.top.toInt() + 1).clamp(1, h - 2);
      final x1 = (bbox.right.toInt() - 1).clamp(x0, w - 1);
      final y1 = (bbox.bottom.toInt() - 1).clamp(y0, h - 1);

      int lumaAt(int px, int py) {
        final p = (py * w + px) * 4;
        return (77 * bytes[p + 2] + 150 * bytes[p + 1] + 29 * bytes[p]) >> 8;
      }

      for (int y = y0; y < y1; y += 4) {
        for (int x = x0; x < x1; x += 4) {
          final lap = (lumaAt(x, y) * 4 -
                  lumaAt(x - 1, y) -
                  lumaAt(x + 1, y) -
                  lumaAt(x, y - 1) -
                  lumaAt(x, y + 1))
              .toDouble();
          sum += lap;
          sumSq += lap * lap;
          count++;
        }
      }
    } else {
      // NV21 — Y plane is the first w*h bytes; reverse ML Kit rotation
      late double nl, nt, nr, nb;
      switch (frame.sensorOrientation) {
        case 270:
          nl = bbox.top;
          nt = h - 1 - bbox.right;
          nr = bbox.bottom;
          nb = h - 1 - bbox.left;
        case 90:
          nl = w - 1 - bbox.bottom;
          nt = bbox.left;
          nr = w - 1 - bbox.top;
          nb = bbox.right;
        case 180:
          nl = w - 1 - bbox.right;
          nt = h - 1 - bbox.bottom;
          nr = w - 1 - bbox.left;
          nb = h - 1 - bbox.top;
        default:
          nl = bbox.left;
          nt = bbox.top;
          nr = bbox.right;
          nb = bbox.bottom;
      }
      final x0 = (nl.toInt() + 1).clamp(1, w - 2);
      final y0 = (nt.toInt() + 1).clamp(1, h - 2);
      final x1 = (nr.toInt() - 1).clamp(x0, w - 1);
      final y1 = (nb.toInt() - 1).clamp(y0, h - 1);

      for (int y = y0; y < y1; y += 4) {
        for (int x = x0; x < x1; x += 4) {
          final c = bytes[y * w + x] & 0xFF;
          final l = bytes[y * w + (x - 1)] & 0xFF;
          final r = bytes[y * w + (x + 1)] & 0xFF;
          final u = bytes[(y - 1) * w + x] & 0xFF;
          final d = bytes[(y + 1) * w + x] & 0xFF;
          final lap = (c * 4 - l - r - u - d).toDouble();
          sum += lap;
          sumSq += lap * lap;
          count++;
        }
      }
    }

    if (count < 5) return 0.0;
    final mean = sum / count;
    return sumSq / count - mean * mean; // Var = E[x²] − E[x]²
  }

  // ── Motion-heterogeneity tracker ────────────────────────────────────────

  /// Samples mean luma for each of the 9 face-crop grid regions this frame.
  void _updateRegionBrightness(RawFrameData frame, Rect bbox) {
    final bytes = frame.imageBytes;
    final iw = frame.imageWidth;
    final ih = frame.imageHeight;
    final bw = bbox.width;
    final bh = bbox.height;

    for (int gy = 0; gy < _hetGridSize; gy++) {
      for (int gx = 0; gx < _hetGridSize; gx++) {
        final idx = gy * _hetGridSize + gx;
        // Sub-region bounds in face-crop space (then clamped to frame)
        final rx0 =
            (bbox.left + bw * gx / _hetGridSize).toInt().clamp(0, iw - 1);
        final ry0 =
            (bbox.top + bh * gy / _hetGridSize).toInt().clamp(0, ih - 1);
        final rx1 =
            (bbox.left + bw * (gx + 1) / _hetGridSize).toInt().clamp(1, iw);
        final ry1 =
            (bbox.top + bh * (gy + 1) / _hetGridSize).toInt().clamp(1, ih);

        int sum = 0, count = 0;
        if (Platform.isIOS) {
          for (int y = ry0; y < ry1; y += 6) {
            for (int x = rx0; x < rx1; x += 6) {
              final p = (y * iw + x) * 4;
              sum +=
                  (77 * bytes[p + 2] + 150 * bytes[p + 1] + 29 * bytes[p]) >> 8;
              count++;
            }
          }
        } else {
          // NV21 — use Y plane directly (orientation correction intentionally
          // skipped here because we care only about relative region changes,
          // not absolute spatial position)
          for (int y = ry0; y < ry1; y += 6) {
            for (int x = rx0; x < rx1; x += 6) {
              final i2 = y * iw + x;
              if (i2 < iw * ih) {
                sum += bytes[i2] & 0xFF;
                count++;
              }
            }
          }
        }

        final brightness = count > 0 ? (sum / count) / 255.0 : 0.5;
        final hist = _hetHistory[idx];
        hist.add(brightness);
        if (hist.length > 60) hist.removeAt(0);
      }
    }
  }

  /// Spatial CV² of per-region temporal variances — AEC-invariant.
  ///
  /// Returns null when any region has fewer than 10 samples.
  /// High value = heterogeneous motion = likely real face.
  /// Low value  = uniform motion (AEC dominance) = likely screen replay.
  double? _motionHeterogeneityScore() {
    if (_hetHistory.any((h) => h.length < 10)) return null;

    // Per-region temporal variance
    final vars = <double>[];
    for (final hist in _hetHistory) {
      final mean = hist.reduce((a, b) => a + b) / hist.length;
      final v =
          hist.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
              hist.length;
      vars.add(v);
    }

    final meanV = vars.reduce((a, b) => a + b) / vars.length;
    if (meanV < 1e-9) return 0.0; // all regions perfectly still

    // Spatial variance of temporal variances
    final spatialVar =
        vars.map((v) => (v - meanV) * (v - meanV)).reduce((a, b) => a + b) /
            vars.length;

    // CV² = spatial_var / meanV² — invariant to AEC gain changes
    return spatialVar / (meanV * meanV);
  }

  // ── Reset / Dispose ─────────────────────────────────────────────────────

  Future<void> reset() async {
    if (!_isInitialized) return;
    _engine?.reset(_actions);
    _currentFace = null;
    _lastQuality = null;
    _lastRawFrame = null;
    _lastMeshData = null;
    _frontalFrames.clear();
    _bestFrontalFrame = null;
    _bestFrontalFace = null;
    _bestFrontalScore = double.infinity;
    _lastTfliteScore = null;
    _isTfliteRunning = false;
    _tfliteFuture = null;
    _tfliteModelDownloadProgress = null;
    _lastVideoReplayScore = null;
    _isVideoReplayRunning = false;
    _videoReplayFuture = null;
    _faceCropBrightnessHistory.clear();
    _faceCropLaplacianHistory.clear();
    for (final h in _hetHistory) {
      h.clear();
    }
    _replayAnalyzer.reset();
    _screenDetector.reset();
    _flowAnalyzer.reset();
    _geoAnalyzer.reset();
    _liveHeuristicScore = null;
    _liveLaplacianScore = null;
    _liveHetScore = null;
    _liveReplayScore = null;
    _liveScreenScore = null;
    _liveFlowScore = null;
    _liveGeoScore = null;
    notifyListeners();
  }

  /// Clear all stored face embeddings on this device (e.g. on user logout).
  Future<void> clearFaceIdentities() async {
    await _faceIdentity?.clearAllFaces();
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await _cameraService.dispose();
    await _faceDetector.dispose();
    _tflite?.dispose();
    _videoReplay?.dispose();
    _faceIdentity?.dispose();
    _engine?.dispose();
    super.dispose();
  }
}
