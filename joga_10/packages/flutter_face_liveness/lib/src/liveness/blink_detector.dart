import '../models/face_data.dart';
import '../models/face_mesh_data.dart';

/// Detects genuine eye blinks — fires as soon as both eyes close (not on re-open).
///
/// Firing on close instead of on re-open eliminates the 150–300 ms wait for the
/// full close→open cycle, making detection feel instant.
///
/// A "was recently open" guard prevents false positives from people with
/// naturally droopy eyelids: both eyes must have been seen clearly open
/// (probability > [_openThreshold]) within the last [_wasOpenWindowMs] before
/// a close event is accepted as a blink.
class BlinkDetector {
  // ML Kit probability thresholds (used when Face Mesh is unavailable)
  static const double _closedThreshold = 0.68; // raised 0.65→0.68: catches mid-blink earlier
  static const double _openThreshold   = 0.70; // hysteresis gap = 0.02
  // Face Mesh geometric eyelid-gap thresholds (eyelid gap / face height)
  // More reliable than ML Kit probability: device-independent, scale-invariant.
  // Open eye ≈ 0.03–0.06; closing ≈ 0.015–0.025; fully closed ≈ 0.00–0.015.
  static const double _meshClosedThreshold = 0.022; // raised 0.018→0.022: fires earlier in blink
  static const double _meshOpenThreshold   = 0.028; // hysteresis gap = 0.006
  // Shared timing constants
  static const int    _wasOpenWindowMs = 1500;
  static const int    _debounceMs      = 300;  // lowered 400→300ms: faster re-arm after blink
  static const int    _eyeSyncWindowMs = 250;  // raised 200→250ms: more forgiving L/R sync

  int _leftClosedAtMs  = 0;
  int _rightClosedAtMs = 0;
  int _leftOpenAtMs    = 0;
  int _rightOpenAtMs   = 0;
  int _lastBlinkMs     = 0;

  /// Call on every frame. Returns true exactly once per detected blink.
  ///
  /// When [meshData] is supplied, uses geometric eyelid-gap values instead of
  /// ML Kit IR-based probabilities. The mesh signal is device-independent and
  /// catches fast blinks reliably even on low-fps cameras.
  bool process(FaceData face, {FaceMeshData? meshData}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Always update from ML Kit — runs every frame, never misses a fast blink.
    // ML Kit is the primary source; mesh supplements it on devices where the
    // IR-based probability is unreliable.
    if (face.leftEyeOpenProbability  < _closedThreshold) _leftClosedAtMs  = nowMs;
    if (face.rightEyeOpenProbability < _closedThreshold) _rightClosedAtMs = nowMs;
    if (face.leftEyeOpenProbability  > _openThreshold)   _leftOpenAtMs    = nowMs;
    if (face.rightEyeOpenProbability > _openThreshold)   _rightOpenAtMs   = nowMs;

    // Face Mesh eyelid gap supplements ML Kit (OR logic: either source can
    // trigger). Mesh is throttled to every 3rd frame — without the ML Kit
    // pass above, fast blinks between mesh frames would be silently missed.
    if (meshData != null) {
      if (meshData.leftEyeOpenness  < _meshClosedThreshold) _leftClosedAtMs  = nowMs;
      if (meshData.rightEyeOpenness < _meshClosedThreshold) _rightClosedAtMs = nowMs;
      if (meshData.leftEyeOpenness  > _meshOpenThreshold)   _leftOpenAtMs    = nowMs;
      if (meshData.rightEyeOpenness > _meshOpenThreshold)   _rightOpenAtMs   = nowMs;
    }

    // Both eyes closed within the sync window (handles 1–2 frame L/R offset)
    final bothClosed = (nowMs - _leftClosedAtMs  < _eyeSyncWindowMs) &&
                       (nowMs - _rightClosedAtMs < _eyeSyncWindowMs);

    // Both eyes were clearly open recently (guards against droopy eyelids)
    final wasOpen = (nowMs - _leftOpenAtMs  < _wasOpenWindowMs) &&
                    (nowMs - _rightOpenAtMs < _wasOpenWindowMs);

    // Fire immediately on close — no waiting for re-open
    if (bothClosed && wasOpen && nowMs - _lastBlinkMs > _debounceMs) {
      _lastBlinkMs = nowMs;
      return true;
    }

    return false;
  }

  void reset() {
    _leftClosedAtMs  = 0;
    _rightClosedAtMs = 0;
    _leftOpenAtMs    = 0;
    _rightOpenAtMs   = 0;
    _lastBlinkMs     = 0;
  }
}
