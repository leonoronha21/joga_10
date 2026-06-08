import 'package:flutter/foundation.dart';
import 'liveness_action.dart';

/// Result returned when a liveness verification session ends.
@immutable
class LivenessResult {
  const LivenessResult({
    required this.isSuccess,
    required this.completedActions,
    required this.confidenceScore,
    this.isRealHuman = true,
    this.spoofDetected = false,
    this.deepfakeDetected = false,
    this.tfliteScore,
    this.videoReplayScore,
    this.videoReplayDetected = false,
    this.failureReason,
    this.sessionDurationMs,
    this.sessionId,
    this.faceId,
    this.isFaceIdNew,
    this.faceAlreadyRegistered,
    this.faceMatchScore,
  });

  /// Convenience constructor for a successful result.
  const LivenessResult.success({
    required List<LivenessAction> completedActions,
    required double confidenceScore,
    int? sessionDurationMs,
    String? sessionId,
    double? tfliteScore,
  }) : this(
          isSuccess: true,
          completedActions: completedActions,
          confidenceScore: confidenceScore,
          isRealHuman: true,
          spoofDetected: false,
          deepfakeDetected: false,
          sessionDurationMs: sessionDurationMs,
          sessionId: sessionId,
          tfliteScore: tfliteScore,
        );

  /// Convenience constructor for a failed result.
  const LivenessResult.failure({
    required String reason,
    List<LivenessAction> completedActions = const [],
    double confidenceScore = 0.0,
    bool spoofDetected = false,
    bool deepfakeDetected = false,
    String? sessionId,
  }) : this(
          isSuccess: false,
          completedActions: completedActions,
          confidenceScore: confidenceScore,
          isRealHuman: false,
          spoofDetected: spoofDetected,
          deepfakeDetected: deepfakeDetected,
          failureReason: reason,
          sessionId: sessionId,
        );

  // ── Core ────────────────────────────────────────────────────────────────
  final bool isSuccess;
  final List<LivenessAction> completedActions;

  /// Heuristic anti-spoof confidence: 0.0 (definitely fake) – 1.0 (real).
  final double confidenceScore;

  // ── Anti-spoof ──────────────────────────────────────────────────────────
  final bool isRealHuman;
  final bool spoofDetected;

  /// True if the FaceAntiSpoofing TFLite model flagged potential deepfake.
  final bool deepfakeDetected;

  /// Raw FaceAntiSpoofing model score (null when TFLite disabled).
  final double? tfliteScore;

  /// Raw MiniFASNet video-replay model score (null when disabled).
  final double? videoReplayScore;

  /// True if MiniFASNet flagged a video-replay attack.
  final bool videoReplayDetected;

  // ── Meta ────────────────────────────────────────────────────────────────
  final String? failureReason;
  final int? sessionDurationMs;
  final String? sessionId;

  // ── Face Identity ────────────────────────────────────────────────────────
  /// Persistent face ID — non-null only when [LivenessConfig.enableFaceId] is true.
  final String? faceId;

  /// True when [faceId] was newly registered in this session.
  /// False when an existing face was matched.
  final bool? isFaceIdNew;

  /// True when [LivenessConfig.faceIdMode] is [FaceIdMode.registrationOnly]
  /// and the face was found to already be registered.
  ///
  /// When this is true, [faceId] contains the existing face's ID and the
  /// session result will be a failure with reason "Face already registered".
  final bool? faceAlreadyRegistered;

  /// The cosine similarity score from the gallery search (0.0–1.0).
  /// Useful for debugging and UI feedback (e.g. "how confident is the match").
  /// Non-null when [enableFaceId] is true.
  final double? faceMatchScore;

  // ── Copy helpers ─────────────────────────────────────────────────────────

  LivenessResult withTfliteResult(double score, {required bool deepfakeDetected}) =>
      _copy(tfliteScore: score, deepfakeDetected: deepfakeDetected);

  LivenessResult withTfliteScore(double score) => _copy(tfliteScore: score);

  LivenessResult withVideoReplayResult(double score,
          {required bool videoReplayDetected}) =>
      _copy(videoReplayScore: score, videoReplayDetected: videoReplayDetected);

  LivenessResult withFaceId(
    String id, {
    required bool isNew,
    bool alreadyRegistered = false,
    double? matchScore,
  }) => _copy(
    faceId: id,
    isFaceIdNew: isNew,
    faceAlreadyRegistered: alreadyRegistered,
    faceMatchScore: matchScore,
  );

  LivenessResult _copy({
    double? tfliteScore,
    bool? deepfakeDetected,
    double? videoReplayScore,
    bool? videoReplayDetected,
    String? faceId,
    bool? isFaceIdNew,
    bool? faceAlreadyRegistered,
    double? faceMatchScore,
  }) =>
      LivenessResult(
        isSuccess: isSuccess,
        completedActions: completedActions,
        confidenceScore: confidenceScore,
        isRealHuman: isRealHuman,
        spoofDetected: spoofDetected,
        deepfakeDetected: deepfakeDetected ?? this.deepfakeDetected,
        tfliteScore: tfliteScore ?? this.tfliteScore,
        videoReplayScore: videoReplayScore ?? this.videoReplayScore,
        videoReplayDetected: videoReplayDetected ?? this.videoReplayDetected,
        failureReason: failureReason,
        sessionDurationMs: sessionDurationMs,
        sessionId: sessionId,
        faceId: faceId ?? this.faceId,
        isFaceIdNew: isFaceIdNew ?? this.isFaceIdNew,
        faceAlreadyRegistered: faceAlreadyRegistered ?? this.faceAlreadyRegistered,
        faceMatchScore: faceMatchScore ?? this.faceMatchScore,
      );

  @override
  String toString() => 'LivenessResult('
      'success: $isSuccess, '
      'score: ${confidenceScore.toStringAsFixed(2)}, '
      'spoof: $spoofDetected, '
      'deepfake: $deepfakeDetected, '
      'videoReplay: $videoReplayDetected, '
      'faceId: $faceId, '
      'faceAlreadyRegistered: $faceAlreadyRegistered, '
      'faceMatchScore: ${faceMatchScore?.toStringAsFixed(3)}, '
      'actions: $completedActions)';
}
