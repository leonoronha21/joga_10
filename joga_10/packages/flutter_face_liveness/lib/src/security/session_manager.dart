import 'dart:math';

/// Manages per-session metadata for audit trails and replay-attack prevention.
class SessionManager {
  SessionManager() : _sessionId = _generateId();

  String _sessionId;
  int _createdAtMs = DateTime.now().millisecondsSinceEpoch;
  int _frameCount = 0;
  bool _isActive = true;

  String get sessionId => _sessionId;
  int get frameCount => _frameCount;
  bool get isActive => _isActive;

  int get elapsedMs => DateTime.now().millisecondsSinceEpoch - _createdAtMs;

  bool isTimedOut(int timeoutMs) => elapsedMs > timeoutMs;

  void incrementFrame() {
    if (_isActive) _frameCount++;
  }

  void close() {
    _isActive = false;
  }

  void reset() {
    _sessionId = _generateId();
    _createdAtMs = DateTime.now().millisecondsSinceEpoch;
    _frameCount = 0;
    _isActive = true;
  }

  // Format: LV-{timestamp_hex}-{8 random hex chars}
  // e.g.   LV-018F3A2B4C1D-A3F29E01
  // Timestamp part: milliseconds since epoch (unique per ms)
  // Random part:    cryptographically secure 32-bit value (unique within same ms)
  static String _generateId() {
    final ts   = DateTime.now().millisecondsSinceEpoch;
    final rand = Random.secure().nextInt(0xFFFFFFFF);
    final tsPart   = ts.toRadixString(16).toUpperCase().padLeft(12, '0');
    final randPart = rand.toRadixString(16).toUpperCase().padLeft(8, '0');
    return 'LV-$tsPart-$randPart';
  }
}
