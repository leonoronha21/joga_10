/// Detects static-image / replay attacks by tracking a sliding window of
/// recent frame hashes.
///
/// The FNV-1a hash is computed by [FrameProcessor] in the background isolate
/// and passed here via [FrameQuality.frameHash].
class FrameHasher {
  FrameHasher({this.windowSize = 10, this.maxDuplicates = 10});

  /// Number of recent hashes to keep.
  final int windowSize;

  /// How many consecutive identical hashes before flagging as duplicate.
  final int maxDuplicates;

  final List<int> _hashes = [];
  int _duplicateStreak = 0;

  /// Returns true if the current [hash] matches too many recent frames.
  ///
  /// A genuine video stream always has natural variation; a replayed static
  /// image or a paused screen produces the same hash every frame.
  bool isDuplicate(int hash) {
    if (_hashes.isNotEmpty && _hashes.last == hash) {
      _duplicateStreak++;
    } else {
      _duplicateStreak = 1;
    }

    _hashes.add(hash);
    if (_hashes.length > windowSize) _hashes.removeAt(0);

    return _duplicateStreak >= maxDuplicates;
  }

  void reset() {
    _hashes.clear();
    _duplicateStreak = 0;
  }
}
