import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../identity/face_identity_service.dart' show FaceIdMode;

/// Full configuration for the liveness verification session.
///
/// Pass to [FlutterFaceLiveness] or [LivenessController] to customise
/// detection thresholds, enabled features, UI appearance, and timeouts.
class LivenessConfig {
  const LivenessConfig({
    // ── Session ─────────────────────────────────────────────────────────
    this.sessionTimeoutMs = 60000,
    this.randomizeActions = true,

    // ── Camera ───────────────────────────────────────────────────────────
    this.cameraResolution = ResolutionPreset.high,
    this.targetFps = 20,

    // ── Anti-spoof ───────────────────────────────────────────────────────
    this.enableAntiSpoof = true,
    this.antiSpoofThreshold = 0.45,

    // ── Frame quality ────────────────────────────────────────────────────
    this.enableBrightnessCheck = true,
    this.enableBlurDetection = true,
    this.brightnessMin = 0.12,
    this.brightnessMax = 0.92,
    this.blurThreshold = 80.0,

    // ── TFLite (optional) ────────────────────────────────────────────────
    this.enableTFLite = false,
    this.tfliteModelPath,
    this.tfliteModelUrl,
    this.tfliteInputSize,
    this.tfliteDeepfakeThreshold = 0.40,

    // ── Video Replay Detection (optional) ───────────────────────────────
    this.enableVideoReplayDetection = false,
    this.videoReplayModelPath,
    this.videoReplayModelUrl,
    this.videoReplayInputSize,
    this.videoReplayThreshold = 0.50,

    // ── Face geometry ────────────────────────────────────────────────────
    this.faceTooFarRatio = 0.015,
    this.faceTooCloseRatio = 0.70,

    // ── Security ─────────────────────────────────────────────────────────
    this.enableDuplicateFrameDetection = true,
    this.duplicateFrameWindowSize = 8,

    this.enableFaceMesh = false,

    // ── Face Identity ────────────────────────────────────────────────────
    this.enableFaceId = false,
    this.faceIdMode = FaceIdMode.auto,
    this.faceIdSimilarityThreshold = 0.82,
    this.registrationDuplicateThreshold = 0.75,
    this.minEmbeddingQuality = 0.50,

    // ── UI ───────────────────────────────────────────────────────────────
    this.themeMode = ThemeMode.dark,
    this.showDebugOverlay = false,
  });

  // ── Session ──────────────────────────────────────────────────────────────
  /// Maximum session duration in milliseconds before automatic failure.
  final int sessionTimeoutMs;

  /// Shuffle the action sequence each session to prevent replay attacks.
  final bool randomizeActions;

  // ── Camera ───────────────────────────────────────────────────────────────
  final ResolutionPreset cameraResolution;

  /// Target frame processing rate (1–30). Higher = more responsive but more CPU.
  final int targetFps;

  // ── Anti-spoof ───────────────────────────────────────────────────────────
  /// Enable heuristic + ML-based anti-spoof validation.
  final bool enableAntiSpoof;

  /// Minimum composite confidence score (0.0–1.0) to accept a real face.
  final double antiSpoofThreshold;

  // ── Frame quality ─────────────────────────────────────────────────────────
  final bool enableBrightnessCheck;
  final bool enableBlurDetection;

  /// Normalised luminance below this triggers [DetectionStatus.lowLight].
  final double brightnessMin;

  /// Normalised luminance above this triggers [DetectionStatus.overExposed].
  final double brightnessMax;

  /// Y-plane variance below this triggers [DetectionStatus.blurry].
  final double blurThreshold;

  // ── TFLite ────────────────────────────────────────────────────────────────
  /// Enable TensorFlow Lite model for advanced anti-spoof inference.
  final bool enableTFLite;

  /// Flutter asset key (e.g. `'assets/anti_spoof.tflite'`) or absolute
  /// filesystem path for the .tflite model.
  final String? tfliteModelPath;

  /// HTTPS URL to auto-download the TFLite model from on first use.
  final String? tfliteModelUrl;

  /// Input image size expected by the TFLite model (square).
  final int? tfliteInputSize;

  /// TFLite real-score below this threshold flags [LivenessResult.deepfakeDetected].
  final double tfliteDeepfakeThreshold;

  // ── Video Replay Detection ────────────────────────────────────────────────
  /// Enable MiniFASNet-based video-replay attack detection (second TFLite model).
  final bool enableVideoReplayDetection;

  final String? videoReplayModelPath;
  final String? videoReplayModelUrl;
  final int? videoReplayInputSize;

  /// Real-score below this threshold flags [LivenessResult.videoReplayDetected].
  final double videoReplayThreshold;

  // ── Face geometry ─────────────────────────────────────────────────────────
  final double faceTooFarRatio;
  final double faceTooCloseRatio;

  // ── Security ──────────────────────────────────────────────────────────────
  /// Hash consecutive frames and reject static-image replay attacks.
  final bool enableDuplicateFrameDetection;

  /// Number of recent frame hashes kept for duplicate comparison.
  final int duplicateFrameWindowSize;

  /// Enable MediaPipe Face Mesh detection (468 3-D landmarks).
  final bool enableFaceMesh;

  // ── Face Identity ─────────────────────────────────────────────────────────
  /// Enable MobileFaceNet-based persistent face identity.
  ///
  /// When `true`, [LivenessResult.faceId] is populated after each successful
  /// session. Embeddings are stored encrypted on-device and persist across
  /// app restarts.
  final bool enableFaceId;

  /// How the identity service handles new face embeddings.
  ///
  /// - [FaceIdMode.auto] (default) — match existing or register new.
  /// - [FaceIdMode.registrationOnly] — reject if face already registered
  ///   (sets [LivenessResult.faceAlreadyRegistered] = true); register if new.
  ///   Use this mode to guarantee one registration per person.
  /// - [FaceIdMode.verificationOnly] — only match; never register unknown faces.
  ///   Use for pure login flows where enrolment happens separately.
  final FaceIdMode faceIdMode;

  /// Cosine-similarity threshold (0.0–1.0) for matching in [FaceIdMode.auto]
  /// and [FaceIdMode.verificationOnly].
  /// Default 0.82 — gallery-based best-of-5 matching.
  /// Raise toward 0.86 for stricter matching; lower toward 0.78 if misses occur.
  final double faceIdSimilarityThreshold;

  /// Similarity at or above which a registration attempt is blocked as a
  /// duplicate in [FaceIdMode.registrationOnly].
  /// Default 0.75 — intentionally lower than [faceIdSimilarityThreshold] to
  /// be conservative: borderline cases are rejected rather than double-registered.
  final double registrationDuplicateThreshold;

  /// Discard face embeddings with quality score below this value before
  /// averaging. Range 0.0–1.0. Default 0.50.
  /// Rejects degenerate embeddings (all-zero, wrong norm, etc.) caused by
  /// low-light, motion blur, or partial face crops.
  final double minEmbeddingQuality;

  // ── UI ────────────────────────────────────────────────────────────────────
  final ThemeMode themeMode;
  final bool showDebugOverlay;

  // ── Derived helpers ───────────────────────────────────────────────────────
  int get frameThrottleMs => (1000 / targetFps.clamp(1, 60)).round();

  bool get isDark => themeMode == ThemeMode.dark ||
      (themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  LivenessConfig copyWith({
    int? sessionTimeoutMs,
    bool? randomizeActions,
    ResolutionPreset? cameraResolution,
    int? targetFps,
    bool? enableAntiSpoof,
    double? antiSpoofThreshold,
    bool? enableBrightnessCheck,
    bool? enableBlurDetection,
    double? brightnessMin,
    double? brightnessMax,
    double? blurThreshold,
    bool? enableTFLite,
    String? tfliteModelPath,
    String? tfliteModelUrl,
    int? tfliteInputSize,
    double? tfliteDeepfakeThreshold,
    bool? enableVideoReplayDetection,
    String? videoReplayModelPath,
    String? videoReplayModelUrl,
    int? videoReplayInputSize,
    double? videoReplayThreshold,
    double? faceTooFarRatio,
    double? faceTooCloseRatio,
    bool? enableDuplicateFrameDetection,
    int? duplicateFrameWindowSize,
    bool? enableFaceMesh,
    bool? enableFaceId,
    FaceIdMode? faceIdMode,
    double? faceIdSimilarityThreshold,
    double? registrationDuplicateThreshold,
    double? minEmbeddingQuality,
    ThemeMode? themeMode,
    bool? showDebugOverlay,
  }) {
    return LivenessConfig(
      sessionTimeoutMs: sessionTimeoutMs ?? this.sessionTimeoutMs,
      randomizeActions: randomizeActions ?? this.randomizeActions,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      targetFps: targetFps ?? this.targetFps,
      enableAntiSpoof: enableAntiSpoof ?? this.enableAntiSpoof,
      antiSpoofThreshold: antiSpoofThreshold ?? this.antiSpoofThreshold,
      enableBrightnessCheck: enableBrightnessCheck ?? this.enableBrightnessCheck,
      enableBlurDetection: enableBlurDetection ?? this.enableBlurDetection,
      brightnessMin: brightnessMin ?? this.brightnessMin,
      brightnessMax: brightnessMax ?? this.brightnessMax,
      blurThreshold: blurThreshold ?? this.blurThreshold,
      enableTFLite: enableTFLite ?? this.enableTFLite,
      tfliteModelPath: tfliteModelPath ?? this.tfliteModelPath,
      tfliteModelUrl: tfliteModelUrl ?? this.tfliteModelUrl,
      tfliteInputSize: tfliteInputSize ?? this.tfliteInputSize,
      tfliteDeepfakeThreshold: tfliteDeepfakeThreshold ?? this.tfliteDeepfakeThreshold,
      enableVideoReplayDetection: enableVideoReplayDetection ?? this.enableVideoReplayDetection,
      videoReplayModelPath: videoReplayModelPath ?? this.videoReplayModelPath,
      videoReplayModelUrl: videoReplayModelUrl ?? this.videoReplayModelUrl,
      videoReplayInputSize: videoReplayInputSize ?? this.videoReplayInputSize,
      videoReplayThreshold: videoReplayThreshold ?? this.videoReplayThreshold,
      faceTooFarRatio: faceTooFarRatio ?? this.faceTooFarRatio,
      faceTooCloseRatio: faceTooCloseRatio ?? this.faceTooCloseRatio,
      enableDuplicateFrameDetection:
          enableDuplicateFrameDetection ?? this.enableDuplicateFrameDetection,
      duplicateFrameWindowSize: duplicateFrameWindowSize ?? this.duplicateFrameWindowSize,
      enableFaceMesh: enableFaceMesh ?? this.enableFaceMesh,
      enableFaceId: enableFaceId ?? this.enableFaceId,
      faceIdMode: faceIdMode ?? this.faceIdMode,
      faceIdSimilarityThreshold:
          faceIdSimilarityThreshold ?? this.faceIdSimilarityThreshold,
      registrationDuplicateThreshold:
          registrationDuplicateThreshold ?? this.registrationDuplicateThreshold,
      minEmbeddingQuality: minEmbeddingQuality ?? this.minEmbeddingQuality,
      themeMode: themeMode ?? this.themeMode,
      showDebugOverlay: showDebugOverlay ?? this.showDebugOverlay,
    );
  }
}
