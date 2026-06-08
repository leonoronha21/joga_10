import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/detection_status.dart';
import '../models/face_data.dart';
import '../models/face_mesh_data.dart';
import '../models/frame_quality.dart';
import '../models/liveness_action.dart';
import '../models/liveness_config.dart';
import '../models/liveness_result.dart';
import '../ml/human_validator.dart';
import '../camera/camera_validator.dart';
import '../security/frame_hasher.dart';
import '../security/session_manager.dart';
import 'blink_detector.dart';
import 'head_movement_detector.dart';

/// Orchestrates all liveness checks and tracks challenge progress.
///
/// Usage: call [processFrame] on every camera frame.
class LivenessEngine extends ChangeNotifier {
  LivenessEngine({
    required List<LivenessAction> requiredActions,
    required LivenessConfig config,
    this.onActionCompleted,
    this.onAllActionsCompleted,
    this.onStatusChanged,
  })  : _config = config,
        _cameraValidator = CameraValidator(config) {
    _buildActionSequence(requiredActions);
  }

  final LivenessConfig _config;
  final CameraValidator _cameraValidator;

  final HumanValidator _humanValidator = HumanValidator();
  final BlinkDetector _blinkDetector = BlinkDetector();
  final HeadMovementDetector _headDetector = HeadMovementDetector();
  final FrameHasher _frameHasher = FrameHasher();
  final SessionManager _session = SessionManager();

  List<LivenessAction> _sequence = [];
  final List<LivenessAction> _completed = [];

  int _consecutiveNoFaceFrames = 0;
  int _consecutiveBadLightFrames = 0;
  double _lastConfidenceScore = 0.0;
  bool _isComplete = false;

  static const int _noFaceFrameLimit = 15;
  // Camera auto-exposure needs ~5 frames to settle on startup.
  // Only report low/over light after this many consecutive bad-quality frames.
  static const int _badLightFrameLimit = 6;

  final void Function(LivenessAction action)? onActionCompleted;
  final void Function(LivenessResult result)? onAllActionsCompleted;
  final void Function(DetectionStatus status)? onStatusChanged;

  DetectionStatus _status = DetectionStatus.initializing;

  // ── Public getters ──────────────────────────────────────────────────────
  String get sessionId => _session.sessionId;
  DetectionStatus get status => _status;
  List<LivenessAction> get completedActions => List.unmodifiable(_completed);
  List<LivenessAction> get remainingActions =>
      _sequence.where((a) => !_completed.contains(a)).toList();
  LivenessAction? get currentAction =>
      remainingActions.isNotEmpty ? remainingActions.first : null;

  double get progress =>
      _sequence.isEmpty ? 1.0 : _completed.length / _sequence.length;

  int get totalActions => _sequence.length;
  bool get isComplete => _isComplete;

  // ── Frame processing ────────────────────────────────────────────────────

  void processFrame(List<FaceData> faces,
      {FrameQuality? quality, FaceMeshData? meshData}) {
    if (_isComplete) return;
    _session.incrementFrame();

    if (_checkTimeout()) return;

    // ── Duplicate / static-image detection ─────────────────────────────────
    if (_config.enableDuplicateFrameDetection && quality != null) {
      if (_frameHasher.isDuplicate(quality.frameHash)) {
        _setStatus(DetectionStatus.fakeDetected);
        return;
      }
    }

    // ── Frame quality checks ───────────────────────────────────────────────
    if (quality != null) {
      final qualIssue = _cameraValidator.validateQuality(quality);
      if (qualIssue == DetectionStatus.lowLight ||
          qualIssue == DetectionStatus.overExposed) {
        // Debounce: camera auto-exposure takes several frames to settle.
        // Only block on persistent bad lighting, not a transient dark frame.
        _consecutiveBadLightFrames++;
        if (_consecutiveBadLightFrames >= _badLightFrameLimit) {
          _setStatus(qualIssue!);
        }
        return;
      }
      _consecutiveBadLightFrames = 0;
      if (qualIssue != null) {
        _setStatus(qualIssue);
        return;
      }
    }

    // ── Face count filter ──────────────────────────────────────────────────
    final significant =
        faces.where((f) => f.faceAreaRatio >= _config.faceTooFarRatio).toList();

    if (significant.isEmpty) {
      _consecutiveNoFaceFrames++;
      if (_consecutiveNoFaceFrames >= _noFaceFrameLimit) {
        _setStatus(DetectionStatus.noFace);
      }
      return;
    }
    _consecutiveNoFaceFrames = 0;

    if (significant.length > 1) {
      _setStatus(DetectionStatus.multipleFaces);
      return;
    }

    final face = significant.first;

    // ── Face geometry checks ───────────────────────────────────────────────
    final faceIssue = _cameraValidator.validateFace(face);
    if (faceIssue != null) {
      _setStatus(faceIssue);
      return;
    }

    // ── Anti-spoof ─────────────────────────────────────────────────────────
    if (_config.enableAntiSpoof) {
      final humanResult = _humanValidator.validate(face, quality: quality);
      _lastConfidenceScore = humanResult.confidence;
      if (!humanResult.isValid) {
        _setStatus(DetectionStatus.fakeDetected);
        return;
      }
    }

    // ── Active liveness challenge ──────────────────────────────────────────
    final action = currentAction;
    if (action == null) return;

    _setStatus(DetectionStatus.actionInProgress);
    _processAction(action, face, meshData: meshData);
  }

  void _processAction(LivenessAction action, FaceData face,
      {FaceMeshData? meshData}) {
    bool detected = false;

    switch (action) {
      case LivenessAction.blink:
        detected = _blinkDetector.process(face, meshData: meshData);
      case LivenessAction.turnLeft:
      case LivenessAction.turnRight:
      case LivenessAction.lookUp:
      case LivenessAction.lookDown:
        final moved = _headDetector.process(face, meshData: meshData);
        detected = moved == action;
      case LivenessAction.smile:
        // Face Mesh: lip corner lift > 0.014 of face height = genuine smile.
        // Fallback: ML Kit smilingProbability.
        detected = meshData != null
            ? meshData.smileRatio > 0.014
            : face.smilingProbability > 0.65;
      case LivenessAction.openMouth:
        detected = _detectMouthOpen(face, meshData: meshData);
    }

    if (detected) {
      _completed.add(action);
      onActionCompleted?.call(action);
      notifyListeners();

      if (remainingActions.isEmpty) {
        _complete();
      }
    }
  }

  // ── Mouth open detection ────────────────────────────────────────────────
  // Three independent signals — first available wins:
  //   S0 – Face Mesh lip gap (landmarks 13/14): direct geometric measure,
  //        unaffected by a hand in front of the mouth (preferred when mesh
  //        is available, as bbox and ML Kit signals can be fooled).
  //   S1 – Face bbox height growth vs. a stable rolling baseline (jaw drops
  //        when mouth opens, extending the bounding box downward).
  //        Upper bound rejects hand/occlusion (>20% bbox growth).
  //   S2 – smilingProbability: ML Kit fires this when teeth become visible.
  // Both S1 and S2 signals only need 2 consecutive frames above threshold.
  final List<double> _mouthBaseline = [];
  int _mouthOpenConsecutive = 0;
  static const double _mouthOpenRatio = 1.05; // S1: 5% above resting baseline
  static const double _mouthOpenRatioMax = 1.20; // S1: >20% = hand/occlusion
  static const double _meshMouthOpen =
      0.032; // S0: lowered 0.040→0.032: fires on smaller opening
  static const int _mouthOpenRequired =
      1; // 1 frame — baseline already filters noise

  bool _detectMouthOpen(FaceData face, {FaceMeshData? meshData}) {
    // S0: Face Mesh lip gap — immune to hand occlusion.
    // Fires immediately — the 3-frame baseline window below is bypassed.
    if (meshData != null) {
      return meshData.mouthOpenRatio > _meshMouthOpen;
    }

    // S1 + S2 fallback when Face Mesh is unavailable.
    final h = face.boundingBox.height;

    // Build a 2-frame baseline before evaluating (was 3 — 100 ms vs 150 ms).
    if (_mouthBaseline.length < 2) {
      _mouthBaseline.add(h);
      return false;
    }

    // Median of baseline — robust to outliers from head-bob frames.
    final sorted = List<double>.from(_mouthBaseline)..sort();
    final baseline = sorted[sorted.length ~/ 2];

    // S1: bbox height grew ≥5% but <20% above baseline.
    final ratio = h / baseline;
    final heightGrown = ratio > _mouthOpenRatio && ratio < _mouthOpenRatioMax;

    // S2: ML Kit's smilingProbability rises when teeth are visible.
    final teethVisible = face.smilingProbability > 0.65;

    if (heightGrown || teethVisible) {
      _mouthOpenConsecutive++;
    } else {
      _mouthOpenConsecutive = 0;
      // Refresh baseline only while mouth is confirmed closed.
      _mouthBaseline.removeAt(0);
      _mouthBaseline.add(h);
    }

    return _mouthOpenConsecutive >= _mouthOpenRequired;
  }

  // ── Completion ──────────────────────────────────────────────────────────

  bool _checkTimeout() {
    if (_session.isTimedOut(_config.sessionTimeoutMs)) {
      _isComplete = true;
      _session.close();
      _setStatus(DetectionStatus.failed);
      onAllActionsCompleted?.call(LivenessResult.failure(
        reason: 'O tempo para concluir acabou. Tente novamente.',
        completedActions: List.from(_completed),
        sessionId: _session.sessionId,
      ));
      return true;
    }
    return false;
  }

  void _complete() {
    _isComplete = true;
    _session.close();
    _setStatus(DetectionStatus.completed);
    onAllActionsCompleted?.call(LivenessResult.success(
      completedActions: List.from(_completed),
      confidenceScore: _lastConfidenceScore,
      sessionDurationMs: _session.elapsedMs,
      sessionId: _session.sessionId,
    ));
  }

  void _setStatus(DetectionStatus s) {
    if (_status != s) {
      _status = s;
      onStatusChanged?.call(s);
      notifyListeners();
    }
  }

  void _buildActionSequence(List<LivenessAction> actions) {
    final list = List<LivenessAction>.from(actions);
    if (_config.randomizeActions) {
      // Fisher-Yates shuffle for uniform random ordering
      final rng = math.Random();
      for (int i = list.length - 1; i > 0; i--) {
        final j = rng.nextInt(i + 1);
        final tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
      }
    }
    _sequence = list;
  }

  // ── Reset ───────────────────────────────────────────────────────────────

  void reset(List<LivenessAction> actions) {
    _completed.clear();
    _isComplete = false;
    _consecutiveNoFaceFrames = 0;
    _consecutiveBadLightFrames = 0;
    _lastConfidenceScore = 0.0;
    _mouthBaseline.clear();
    _mouthOpenConsecutive = 0;
    _humanValidator.reset();
    _blinkDetector.reset();
    _headDetector.reset();
    _frameHasher.reset();
    _session.reset();
    _buildActionSequence(actions);
    _setStatus(DetectionStatus.initializing);
  }

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }
}
