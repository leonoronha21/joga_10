import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'face_embedding_model.dart';
import 'face_preprocessor.dart';

// ── Mode / outcome types ──────────────────────────────────────────────────────

/// Controls how [FaceIdentityService] behaves when a new embedding arrives.
enum FaceIdMode {
  /// Match existing face → return its ID. Unknown face → register and return new ID.
  /// Default for combined login/registration flows.
  auto,

  /// Reject if a similar face already exists (duplicate prevention).
  /// Returns [FaceMatchOutcome.alreadyExists] so the caller can show
  /// "Face already registered – please log in instead."
  /// Unknown face → register new ID.
  registrationOnly,

  /// Never register. Returns [FaceMatchOutcome.notFound] for unknown faces.
  /// Use for pure authentication flows where only enrolled users are accepted.
  verificationOnly,
}

/// Outcome of a single [FaceIdentityService.identifyFromEmbeddings] call.
enum FaceMatchOutcome {
  /// An existing face was matched with similarity ≥ threshold.
  matched,

  /// New face registered — was not previously known.
  registered,

  /// [FaceIdMode.registrationOnly]: face already exists, registration rejected.
  alreadyExists,

  /// [FaceIdMode.verificationOnly]: no matching face found in the gallery.
  notFound,
}

/// Rich result returned by [FaceIdentityService.identifyFromEmbeddings].
class FaceMatchResult {
  const FaceMatchResult({
    required this.outcome,
    this.faceId,
    required this.similarity,
    this.qualityScore,
  });

  final FaceMatchOutcome outcome;

  /// Matched or newly-registered face ID. Null only when [outcome] is [FaceMatchOutcome.notFound].
  final String? faceId;

  /// Best cosine similarity found in the gallery (-1.0 when gallery is empty).
  final double similarity;

  /// Embedding quality score (0.0–1.0). Null when quality check is skipped.
  final double? qualityScore;

  bool get isMatched    => outcome == FaceMatchOutcome.matched;
  bool get isRegistered => outcome == FaceMatchOutcome.registered;
  bool get isDuplicate  => outcome == FaceMatchOutcome.alreadyExists;
  bool get isNotFound   => outcome == FaceMatchOutcome.notFound;

  // Legacy helpers for callers that used the old ({faceId, isNew}) record
  bool get isNew => outcome == FaceMatchOutcome.registered;
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Persistent face-identity service.
///
/// Stores a gallery of up to [maxEmbeddingsPerFace] L2-normalised embeddings
/// per face, encrypted with a per-installation XOR key. Matching uses the
/// maximum cosine similarity across all stored embeddings for a face, which
/// handles within-class variance across sessions.
///
/// Enable via [LivenessConfig.enableFaceId].
class FaceIdentityService {
  FaceIdentityService({
    this.similarityThreshold        = 0.82,
    this.registrationDuplicateThreshold = 0.75,
    this.minEmbeddingQuality        = 0.50,
    this.mode                       = FaceIdMode.auto,
    this.maxEmbeddingsPerFace       = 5,
  });

  /// Minimum cosine similarity to consider two embeddings the same face.
  /// Used for matching in [FaceIdMode.auto] and [FaceIdMode.verificationOnly].
  /// Default 0.82 — calibrated against MobileFaceNet gallery approach.
  final double similarityThreshold;

  /// Similarity at or above which a registration attempt is rejected as a
  /// duplicate in [FaceIdMode.registrationOnly].
  /// Default 0.75 — intentionally lower than [similarityThreshold] to be
  /// conservative: better to block a borderline registration than to allow
  /// a duplicate entry.
  final double registrationDuplicateThreshold;

  /// Embeddings with quality score below this value are discarded before
  /// averaging. Range 0.0–1.0. Default 0.50.
  final double minEmbeddingQuality;

  final FaceIdMode mode;

  /// Maximum embeddings stored per face (rolling window, oldest dropped first).
  final int maxEmbeddingsPerFace;

  final FaceEmbeddingModel _model = FaceEmbeddingModel();

  // Gallery: faceId → list of L2-normalised embeddings (in-memory, clear text).
  // Stored on disk as XOR-encrypted float32 bytes encoded to base64.
  final Map<String, List<List<double>>> _gallery = {};

  // Per-installation XOR key — 64 random bytes generated on first run.
  Uint8List? _encKey;

  // Storage keys
  static const _kPrefsKey    = 'ffl_known_faces_v4'; // encrypted gallery
  static const _kEncKeyPrefs = 'ffl_enc_key_v1';     // device encryption key

  bool get isReady => _model.isLoaded;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize({
    void Function(double progress)? onModelDownloadProgress,
  }) async {
    await _model.load(onProgress: onModelDownloadProgress);
    await _loadStoredFaces();
  }

  void dispose() => _model.dispose();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Compute a single face embedding (does not match or register).
  ///
  /// Pass eye positions when available — they enable eye-aligned crops that
  /// significantly reduce embedding variance across sessions.
  Future<List<double>?> computeEmbedding({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required Rect faceBoundingBox,
    required int sensorOrientation,
    double? leftEyeX,
    double? leftEyeY,
    double? rightEyeX,
    double? rightEyeY,
  }) async {
    if (!isReady) return null;
    final eyeAligned = leftEyeX != null && leftEyeY != null &&
                       rightEyeX != null && rightEyeY != null;
    debugPrint('[FaceId] computeEmbedding eyeAligned=$eyeAligned');
    final input = await compute(_runPreprocess, _PreprocessInput(
      imageBytes: imageBytes, imageWidth: imageWidth, imageHeight: imageHeight,
      bbox: faceBoundingBox, sensorOrientation: sensorOrientation,
      leftEyeX: leftEyeX, leftEyeY: leftEyeY,
      rightEyeX: rightEyeX, rightEyeY: rightEyeY,
    ));
    if (input == null) return null;
    return _model.infer(input);
  }

  /// Average multiple session embeddings and run them through the gallery.
  ///
  /// Only embeddings that pass the [minEmbeddingQuality] check are included
  /// in the average. Returns null if all embeddings are rejected as low-quality
  /// or if no embeddings are provided.
  Future<FaceMatchResult?> identifyFromEmbeddings(
    List<List<double>> embeddings, {
    FaceIdMode? modeOverride,
  }) async {
    if (embeddings.isEmpty) return null;

    // Quality filter — discard degenerate embeddings before averaging
    final good = embeddings
        .where((e) => embeddingQuality(e) >= minEmbeddingQuality)
        .toList();

    final toUse = good.isNotEmpty ? good : embeddings;
    debugPrint('[FaceId] embeddings=${embeddings.length}  '
        'passed_quality=${good.length}  using=${toUse.length}');

    List<double> averaged;
    if (toUse.length == 1) {
      averaged = toUse.first;
    } else {
      final len = toUse.first.length;
      final avg = List<double>.filled(len, 0.0);
      for (final e in toUse) {
        for (int i = 0; i < len; i++) { avg[i] += e[i]; }
      }
      double norm = 0.0;
      for (final v in avg) { norm += v * v; }
      norm = math.sqrt(norm);
      averaged = norm < 1e-10 ? avg : avg.map((v) => v / norm).toList();
      debugPrint('[FaceId] Averaged ${toUse.length} embeddings '
          '(quality=${embeddingQuality(averaged).toStringAsFixed(2)})');
    }

    return _matchOrRegister(averaged, modeOverride: modeOverride);
  }

  /// Identify from a single frame (convenience wrapper — prefer multi-frame).
  Future<FaceMatchResult?> identifyFromFrame({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    required Rect faceBoundingBox,
    required int sensorOrientation,
    double? leftEyeX, double? leftEyeY,
    double? rightEyeX, double? rightEyeY,
    FaceIdMode? modeOverride,
  }) async {
    final emb = await computeEmbedding(
      imageBytes: imageBytes, imageWidth: imageWidth, imageHeight: imageHeight,
      faceBoundingBox: faceBoundingBox, sensorOrientation: sensorOrientation,
      leftEyeX: leftEyeX, leftEyeY: leftEyeY,
      rightEyeX: rightEyeX, rightEyeY: rightEyeY,
    );
    if (emb == null) return null;
    return _matchOrRegister(emb, modeOverride: modeOverride);
  }

  /// Delete all stored face embeddings (e.g. on logout or factory reset).
  Future<void> clearAllFaces() async {
    _gallery.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsKey);
    debugPrint('[FaceIdentityService] All face data cleared');
  }

  /// Remove a single face by ID.
  Future<void> removeFace(String faceId) async {
    _gallery.remove(faceId);
    await _flushToPrefs();
  }

  /// All registered face IDs on this device.
  List<String> get registeredFaceIds => List.unmodifiable(_gallery.keys);

  /// Total number of stored embeddings across all faces.
  int get totalEmbeddingCount =>
      _gallery.values.fold(0, (s, l) => s + l.length);

  /// Check if any face in the gallery has similarity ≥ [registrationDuplicateThreshold]
  /// to [embedding] WITHOUT modifying the gallery. Use to pre-validate before
  /// committing a registration.
  ///
  /// Returns the matching face ID and similarity, or null if no duplicate found.
  ({String faceId, double similarity})? checkDuplicate(List<double> embedding) {
    String? bestId;
    double  bestSim = -1.0;
    for (final entry in _gallery.entries) {
      for (final stored in entry.value) {
        final sim = cosineSimilarity(embedding, stored);
        if (sim > bestSim) { bestSim = sim; bestId = entry.key; }
      }
    }
    if (bestId != null && bestSim >= registrationDuplicateThreshold) {
      return (faceId: bestId, similarity: bestSim);
    }
    return null;
  }

  // ── Matching / registration ───────────────────────────────────────────────

  Future<FaceMatchResult> _matchOrRegister(
    List<double> embedding, {
    FaceIdMode? modeOverride,
  }) async {
    final effectiveMode = modeOverride ?? mode;
    final quality = embeddingQuality(embedding);

    String? bestId;
    double  bestSim = -1.0;

    // Gallery search: max similarity across all stored embeddings per face.
    // O(N × K) where N = faces, K = embeddings per face (≤ maxEmbeddingsPerFace).
    for (final entry in _gallery.entries) {
      for (final stored in entry.value) {
        final sim = cosineSimilarity(embedding, stored);
        if (sim > bestSim) { bestSim = sim; bestId = entry.key; }
      }
    }

    debugPrint('[FaceId] mode=$effectiveMode  gallery=${_gallery.length}  '
        'bestSim=${bestId != null ? bestSim.toStringAsFixed(3) : "n/a"}  '
        'quality=${quality.toStringAsFixed(2)}  '
        'threshold=$similarityThreshold  dupThreshold=$registrationDuplicateThreshold');

    switch (effectiveMode) {

      // ── Verification only ─────────────────────────────────────────────────
      case FaceIdMode.verificationOnly:
        if (bestId != null && bestSim >= similarityThreshold) {
          debugPrint('[FaceId] VERIFIED → $bestId  sim=${bestSim.toStringAsFixed(3)}');
          return FaceMatchResult(
            outcome: FaceMatchOutcome.matched,
            faceId: bestId, similarity: bestSim, qualityScore: quality,
          );
        }
        debugPrint('[FaceId] NOT FOUND  bestSim=${bestSim.toStringAsFixed(3)}');
        return FaceMatchResult(
          outcome: FaceMatchOutcome.notFound,
          faceId: null, similarity: bestSim, qualityScore: quality,
        );

      // ── Registration only (duplicate prevention) ──────────────────────────
      case FaceIdMode.registrationOnly:
        if (bestId != null && bestSim >= registrationDuplicateThreshold) {
          debugPrint('[FaceId] DUPLICATE blocked → $bestId  '
              'sim=${bestSim.toStringAsFixed(3)} ≥ $registrationDuplicateThreshold');
          return FaceMatchResult(
            outcome: FaceMatchOutcome.alreadyExists,
            faceId: bestId, similarity: bestSim, qualityScore: quality,
          );
        }
        // New person — register
        final faceId = _newFaceId();
        _gallery[faceId] = [embedding];
        await _flushToPrefs();
        debugPrint('[FaceId] REGISTERED → $faceId  '
            'bestSim=${bestId != null ? bestSim.toStringAsFixed(3) : "n/a (first)"}  '
            'gallery=${_gallery.length}');
        return FaceMatchResult(
          outcome: FaceMatchOutcome.registered,
          faceId: faceId, similarity: bestSim, qualityScore: quality,
        );

      // ── Auto (match or register) ──────────────────────────────────────────
      case FaceIdMode.auto:
        if (bestId != null && bestSim >= similarityThreshold) {
          // Grow gallery with this session's embedding (rolling window)
          _gallery[bestId]!.add(embedding);
          if (_gallery[bestId]!.length > maxEmbeddingsPerFace) {
            _gallery[bestId]!.removeAt(0);
          }
          await _flushToPrefs();
          debugPrint('[FaceId] MATCHED → $bestId  sim=${bestSim.toStringAsFixed(3)}  '
              'gallery_count=${_gallery[bestId]!.length}');
          return FaceMatchResult(
            outcome: FaceMatchOutcome.matched,
            faceId: bestId, similarity: bestSim, qualityScore: quality,
          );
        }
        // Unknown face — register new ID
        final faceId = _newFaceId();
        _gallery[faceId] = [embedding];
        await _flushToPrefs();
        debugPrint('[FaceId] NEW → $faceId  '
            'bestSim=${bestId != null ? bestSim.toStringAsFixed(3) : "n/a (first)"}  '
            'gallery=${_gallery.length}');
        return FaceMatchResult(
          outcome: FaceMatchOutcome.registered,
          faceId: faceId, similarity: bestSim, qualityScore: quality,
        );
    }
  }

  // ── Embedding quality ─────────────────────────────────────────────────────

  /// Score 0.0–1.0 for a face embedding.
  ///
  /// A well-formed MobileFaceNet embedding is L2-normalised (norm ≈ 1.0) and
  /// has non-trivial variance across its 128 dimensions.
  /// Score < [minEmbeddingQuality] → embedding is discarded before averaging.
  static double embeddingQuality(List<double> embedding) {
    if (embedding.length < 32) return 0.0;

    // Check 1: L2 norm should be ≈ 1.0 (model normalises its output)
    double norm = 0.0;
    for (final v in embedding) { norm += v * v; }
    norm = math.sqrt(norm);
    if (norm < 0.80 || norm > 1.20) return 0.0;

    // Check 2: Variance should be non-trivial (not all-zero / all-one)
    final mean = embedding.reduce((a, b) => a + b) / embedding.length;
    double variance = 0.0;
    for (final v in embedding) { variance += (v - mean) * (v - mean); }
    variance /= embedding.length;
    if (variance < 1e-4) return 0.0;

    // Check 3: No degenerate constant vector
    final firstVal = embedding.first;
    if (embedding.every((v) => (v - firstVal).abs() < 1e-5)) return 0.0;

    // Quality score: penalise norm deviation from 1.0
    final normScore = 1.0 - (norm - 1.0).abs().clamp(0.0, 0.20) / 0.20;
    // Penalise extremely low variance
    final varScore = (variance.clamp(0.001, 0.05) / 0.05).clamp(0.0, 1.0);
    return (normScore * 0.60 + varScore * 0.40).clamp(0.0, 1.0);
  }

  // ── Cosine similarity ─────────────────────────────────────────────────────

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0, magA = 0.0, magB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot  += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final denom = math.sqrt(magA) * math.sqrt(magB);
    return denom < 1e-10 ? 0.0 : (dot / denom).clamp(-1.0, 1.0);
  }

  // ── Storage + encryption ──────────────────────────────────────────────────

  Future<void> _loadStoredFaces() async {
    try {
      await _ensureEncKey();
      final prefs = await SharedPreferences.getInstance();
      final json  = prefs.getString(_kPrefsKey);
      if (json == null) return;
      final Map<String, dynamic> decoded = jsonDecode(json);
      for (final e in decoded.entries) {
        final embList = (e.value as List)
            .map((enc) => _decryptEmbedding(enc as String))
            .toList();
        _gallery[e.key] = embList;
      }
      debugPrint('[FaceIdentityService] Loaded ${_gallery.length} face(s) '
          '($totalEmbeddingCount embeddings) from encrypted storage');
    } catch (e) {
      debugPrint('[FaceIdentityService] Load error — clearing: $e');
      _gallery.clear();
    }
  }

  Future<void> _flushToPrefs() async {
    try {
      await _ensureEncKey();
      final prefs = await SharedPreferences.getInstance();
      final data = {
        for (final e in _gallery.entries)
          e.key: e.value.map(_encryptEmbedding).toList(),
      };
      await prefs.setString(_kPrefsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[FaceIdentityService] Persist error: $e');
    }
  }

  // ── Encryption (XOR stream cipher with per-installation key) ─────────────
  //
  // The XOR key is 64 random bytes stored in SharedPreferences on first run.
  // Each Float32 embedding (128 values × 4 bytes = 512 bytes) is XOR-ed with
  // the repeating key then base64-encoded before being written to the gallery
  // JSON. This prevents embeddings from being trivially readable in plain text
  // from app storage without adding any external dependencies.

  Future<void> _ensureEncKey() async {
    if (_encKey != null) return;
    final prefs  = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kEncKeyPrefs);
    if (stored != null) {
      _encKey = base64Decode(stored);
    } else {
      final rand = math.Random.secure();
      _encKey = Uint8List.fromList(
        List.generate(64, (_) => rand.nextInt(256)),
      );
      await prefs.setString(_kEncKeyPrefs, base64Encode(_encKey!));
      debugPrint('[FaceIdentityService] Generated new encryption key');
    }
  }

  String _encryptEmbedding(List<double> embedding) {
    // Convert List<double> → Float32List bytes → XOR → base64
    final floatBytes =
        Float32List.fromList(embedding.map((v) => v.toDouble()).toList())
            .buffer
            .asUint8List();
    final key    = _encKey!;
    final result = Uint8List(floatBytes.length);
    for (int i = 0; i < floatBytes.length; i++) {
      result[i] = floatBytes[i] ^ key[i % key.length];
    }
    return base64Encode(result);
  }

  List<double> _decryptEmbedding(String encoded) {
    final bytes  = base64Decode(encoded);
    final key    = _encKey!;
    final result = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ key[i % key.length];
    }
    return Float32List.view(result.buffer)
        .map((v) => v.toDouble())
        .toList();
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static String _newFaceId() {
    final rand  = math.Random.secure();
    final bytes = List.generate(12, (_) => rand.nextInt(256));
    return 'FID-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
  }
}

// ── Isolate helper ────────────────────────────────────────────────────────────

class _PreprocessInput {
  const _PreprocessInput({
    required this.imageBytes, required this.imageWidth, required this.imageHeight,
    required this.bbox, required this.sensorOrientation,
    this.leftEyeX, this.leftEyeY, this.rightEyeX, this.rightEyeY,
  });
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final Rect bbox;
  final int sensorOrientation;
  final double? leftEyeX;
  final double? leftEyeY;
  final double? rightEyeX;
  final double? rightEyeY;
}

Float32List? _runPreprocess(_PreprocessInput inp) =>
    FacePreprocessor.prepare(
      imageBytes: inp.imageBytes, imageWidth: inp.imageWidth,
      imageHeight: inp.imageHeight, bbox: inp.bbox,
      sensorOrientation: inp.sensorOrientation,
      leftEyeX: inp.leftEyeX, leftEyeY: inp.leftEyeY,
      rightEyeX: inp.rightEyeX, rightEyeY: inp.rightEyeY,
    );
