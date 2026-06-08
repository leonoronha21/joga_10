import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

/// Processed data derived from the 468-landmark MediaPipe Face Mesh model.
///
/// Provides three signals for liveness detection:
///
///  1. **3-D depth** — Z-range of nose tip vs outer cheeks / face width.
///     Real face ≈ 0.15–0.30; flat surface (photo / screen) ≈ 0.0–0.04.
///
///  2. **Eye openness** — Geometric eyelid gap from upper/lower lid landmarks.
///     Supplements ML Kit IR probability for blink detection.
///
///  3. **Head pose** — Yaw and pitch derived from 3-D landmark geometry.
///     More consistent across devices than ML Kit Euler angles.
@immutable
class FaceMeshData {
  const FaceMeshData({
    required this.depthSpread,
    required this.leftEyeOpenness,
    required this.rightEyeOpenness,
    required this.mouthOpenRatio,
    required this.smileRatio,
    required this.headYawDeg,
    required this.headPitchDeg,
  });

  /// Build from a [FaceMesh] result.
  ///
  /// Returns null when fewer than 3 key depth landmarks are present (can
  /// happen on extreme face angles or heavy partial occlusion).
  static FaceMeshData? tryFromMesh(FaceMesh mesh) {
    // Build index → point lookup in one pass
    final pts = <int, FaceMeshPoint>{};
    for (final p in mesh.points) {
      pts[p.index] = p;
    }

    final bbox  = mesh.boundingBox;
    final faceW = bbox.width.clamp(1.0, double.infinity);
    final faceH = bbox.height.clamp(1.0, double.infinity);

    // ── 3-D depth spread ────────────────────────────────────────────────────
    // Key anchors with maximum expected Z separation:
    //   1   = nose tip        (closest to camera — protrudes most)
    //   234 = left outer face (ear / temple region, furthest back)
    //   454 = right outer face
    //   10  = forehead midline
    //   152 = chin bottom
    // Z-range / face_width is scale-invariant and large for a real 3-D face.
    const depthIdxs = [1, 234, 454, 10, 152];
    final depthPts  = depthIdxs
        .map((i) => pts[i])
        .whereType<FaceMeshPoint>()
        .toList();

    if (depthPts.length < 3) return null; // insufficient anchors

    final zVals      = depthPts.map((p) => p.z).toList();
    final zMin       = zVals.reduce((a, b) => a < b ? a : b);
    final zMax       = zVals.reduce((a, b) => a > b ? a : b);
    final depthSpread = ((zMax - zMin) / faceW).clamp(0.0, 2.0);

    // ── Geometric eye openness (eyelid gap / face height) ──────────────────
    // Upper lids: 159 (left), 386 (right)
    // Lower lids: 145 (left), 374 (right)
    // Y increases downward in image space: lower lid Y > upper lid Y.
    double leftEyeOpenness  = 0.0;
    double rightEyeOpenness = 0.0;

    final lUpper = pts[159];
    final lLower = pts[145];
    if (lUpper != null && lLower != null) {
      leftEyeOpenness = ((lLower.y - lUpper.y).abs() / faceH).clamp(0.0, 1.0);
    }

    final rUpper = pts[386];
    final rLower = pts[374];
    if (rUpper != null && rLower != null) {
      rightEyeOpenness = ((rLower.y - rUpper.y).abs() / faceH).clamp(0.0, 1.0);
    }

    // ── Mouth open ratio (inner lip gap / face height) ─────────────────────
    // Landmark 13 = upper inner lip, 14 = lower inner lip.
    // Closed mouth: gap ≈ 0.00–0.02.  Wide open: ≈ 0.05–0.15.
    // A hand placed over the mouth does NOT move these face-geometry landmarks,
    // making this far more reliable than bounding-box height growth.
    double mouthOpenRatio = 0.0;
    final mUpper = pts[13];
    final mLower = pts[14];
    if (mUpper != null && mLower != null) {
      mouthOpenRatio = ((mLower.y - mUpper.y).abs() / faceH).clamp(0.0, 1.0);
    }

    // ── Smile ratio (lip corner lift / face height) ────────────────────────
    // Lip corners: 61 (left), 291 (right).
    // Positive when corners sit above the inner-lip midline → genuine smile.
    // Neutral ≈ 0.0; smiling ≈ 0.015–0.04+.
    double smileRatio = 0.0;
    final lCorner = pts[61];
    final rCorner = pts[291];
    if (mUpper != null && mLower != null && lCorner != null && rCorner != null) {
      final mouthCenterY  = (mUpper.y + mLower.y) / 2.0;
      final cornerMidY    = (lCorner.y + rCorner.y) / 2.0;
      smileRatio = ((mouthCenterY - cornerMidY) / faceH).clamp(-0.5, 0.5);
    }

    // ── Head pose (approximate degrees) ───────────────────────────────────
    // Yaw  — nose X offset from temple midpoint; atan2 gives a degree estimate.
    //   +ve = user turned LEFT (front camera), −ve = turned RIGHT.
    //   Same sign convention as ML Kit headEulerAngleY (iOS-corrected).
    // Pitch — nose Y position in the eye→chin segment vs. neutral ratio 0.45.
    //   +ve = looking UP, −ve = looking DOWN (matches ML Kit headEulerAngleX).
    double headYawDeg   = 0.0;
    double headPitchDeg = 0.0;

    final noseTip     = pts[1];
    final leftTemple  = pts[234];
    final rightTemple = pts[454];
    final chinPt      = pts[152];
    final leftEyeOuter  = pts[33];
    final rightEyeOuter = pts[263];

    if (noseTip != null && leftTemple != null && rightTemple != null) {
      final centerX   = (leftTemple.x + rightTemple.x) / 2.0;
      final halfWidth = (rightTemple.x - leftTemple.x).abs() / 2.0;
      if (halfWidth > 0) {
        headYawDeg = math.atan2(noseTip.x - centerX, halfWidth) *
            (180.0 / math.pi);
      }
    }

    if (noseTip != null && leftEyeOuter != null && rightEyeOuter != null && chinPt != null) {
      final eyeCenterY = (leftEyeOuter.y + rightEyeOuter.y) / 2.0;
      final segH       = chinPt.y - eyeCenterY;
      // Guard: chin must be below eye level and segment large enough to be valid.
      if (segH > faceH * 0.2) {
        // Nose at 45% from eye centre to chin is the neutral front-facing position.
        // Deviation: negative → looking UP (nose rises), positive → looking DOWN.
        // Negate so the sign matches ML Kit convention (+ve = looking UP).
        final nosePosRatio = (noseTip.y - eyeCenterY) / segH;
        headPitchDeg = -(nosePosRatio - 0.45) * 100.0;
      }
    }

    return FaceMeshData(
      depthSpread:      depthSpread,
      leftEyeOpenness:  leftEyeOpenness,
      rightEyeOpenness: rightEyeOpenness,
      mouthOpenRatio:   mouthOpenRatio,
      smileRatio:       smileRatio,
      headYawDeg:       headYawDeg,
      headPitchDeg:     headPitchDeg,
    );
  }

  // ── Core measurements ─────────────────────────────────────────────────────

  /// Normalised Z-range across key depth anchors / face width.
  /// Real 3-D face ≈ 0.15–0.30; flat surface ≈ 0.00–0.04.
  final double depthSpread;

  /// Geometric eyelid gap / face height for the left eye.
  /// Open eye ≈ 0.03–0.06; fully closed or occluded ≈ 0.00–0.015.
  final double leftEyeOpenness;

  /// Geometric eyelid gap / face height for the right eye.
  final double rightEyeOpenness;

  /// Inner lip gap (landmark 13 to 14) / face height.
  /// Closed mouth ≈ 0.00–0.02; wide open ≈ 0.05–0.15.
  final double mouthOpenRatio;

  /// Lip corner lift above inner-lip midline / face height.
  /// Neutral ≈ 0.0; genuine smile ≈ 0.015–0.04+.
  final double smileRatio;

  /// Approximate head yaw in degrees (same sign as ML Kit headEulerAngleY).
  /// +ve = user turned LEFT (front camera); −ve = turned RIGHT.
  final double headYawDeg;

  /// Approximate head pitch in degrees (same sign as ML Kit headEulerAngleX).
  /// +ve = looking UP; −ve = looking DOWN.
  final double headPitchDeg;

  // ── 3-D depth score ───────────────────────────────────────────────────────

  /// Plausibility score for a real 3-D face structure (0.0 = flat, 1.0 = real).
  ///
  /// Maps [depthSpread] onto [0, 1]; saturates at depthSpread ≥ 0.20
  /// (typical real-face value).  Use as an additional anti-spoof signal.
  double get depth3DScore => (depthSpread / 0.20).clamp(0.0, 1.0);

  @override
  String toString() =>
      'FaceMeshData(depth=${depthSpread.toStringAsFixed(3)}, '
      'lEye=${leftEyeOpenness.toStringAsFixed(3)}, '
      'rEye=${rightEyeOpenness.toStringAsFixed(3)}, '
      'mouth=${mouthOpenRatio.toStringAsFixed(3)}, '
      'smile=${smileRatio.toStringAsFixed(3)}, '
      'yaw=${headYawDeg.toStringAsFixed(1)}°, '
      'pitch=${headPitchDeg.toStringAsFixed(1)}°)';
}
