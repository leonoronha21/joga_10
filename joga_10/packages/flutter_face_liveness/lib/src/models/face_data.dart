import 'dart:io' show Platform;
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// 2-D point for face landmark positions, expressed in image-pixel coordinates.
typedef LandmarkPoint = ({double x, double y});

/// Processed face data extracted from ML Kit detection result.
@immutable
class FaceData {
  const FaceData({
    required this.boundingBox,
    required this.headEulerAngleX,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.smilingProbability,
    required this.trackingId,
    required this.imageSize,
    this.leftEyePosition,
    this.rightEyePosition,
    this.noseBasePosition,
    this.leftCheekPosition,
    this.rightCheekPosition,
    this.leftMouthPosition,
    this.rightMouthPosition,
    this.bottomMouthPosition,
    this.leftEarPosition,
    this.rightEarPosition,
  });

  factory FaceData.fromFace(Face face, Size imageSize) {
    // iOS front-camera delivers horizontally-mirrored BGRA8888 frames and we
    // pass them to ML Kit with rotation0deg (no correction). The mirroring
    // flips the sign of headEulerAngleY: physical RIGHT gives positive yaw,
    // physical LEFT gives negative — opposite of Android. Negate on iOS so
    // both platforms share the same convention:
    //   positive yaw = user physically turned LEFT (front-camera convention).
    final rawYaw = face.headEulerAngleY ?? 0.0;
    final correctedYaw = Platform.isIOS ? -rawYaw : rawYaw;

    LandmarkPoint? lm(FaceLandmarkType type) {
      final pt = face.landmarks[type]?.position;
      if (pt == null) return null;
      return (x: pt.x.toDouble(), y: pt.y.toDouble());
    }

    return FaceData(
      boundingBox: face.boundingBox,
      headEulerAngleX: face.headEulerAngleX ?? 0.0,
      headEulerAngleY: correctedYaw,
      headEulerAngleZ: face.headEulerAngleZ ?? 0.0,
      leftEyeOpenProbability: face.leftEyeOpenProbability ?? 1.0,
      rightEyeOpenProbability: face.rightEyeOpenProbability ?? 1.0,
      smilingProbability: face.smilingProbability ?? 0.0,
      trackingId: face.trackingId,
      imageSize: imageSize,
      leftEyePosition:     lm(FaceLandmarkType.leftEye),
      rightEyePosition:    lm(FaceLandmarkType.rightEye),
      noseBasePosition:    lm(FaceLandmarkType.noseBase),
      leftCheekPosition:   lm(FaceLandmarkType.leftCheek),
      rightCheekPosition:  lm(FaceLandmarkType.rightCheek),
      leftMouthPosition:   lm(FaceLandmarkType.leftMouth),
      rightMouthPosition:  lm(FaceLandmarkType.rightMouth),
      bottomMouthPosition: lm(FaceLandmarkType.bottomMouth),
      leftEarPosition:     lm(FaceLandmarkType.leftEar),
      rightEarPosition:    lm(FaceLandmarkType.rightEar),
    );
  }

  final Rect boundingBox;

  /// Pitch: positive = looking up, negative = looking down
  final double headEulerAngleX;

  /// Yaw (iOS-corrected): positive = user turned LEFT, negative = user turned RIGHT.
  /// Convention is consistent across Android and iOS after the iOS negation in fromFace().
  final double headEulerAngleY;

  /// Roll: head tilt
  final double headEulerAngleZ;

  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final double smilingProbability;
  final int? trackingId;
  final Size imageSize;

  // ── Landmark positions (null when enableLandmarks = false or not detected) ──

  /// Centre of left eye in image-pixel coordinates.
  final LandmarkPoint? leftEyePosition;

  /// Centre of right eye in image-pixel coordinates.
  final LandmarkPoint? rightEyePosition;

  /// Base of nose in image-pixel coordinates.
  final LandmarkPoint? noseBasePosition;

  final LandmarkPoint? leftCheekPosition;
  final LandmarkPoint? rightCheekPosition;
  final LandmarkPoint? leftMouthPosition;
  final LandmarkPoint? rightMouthPosition;
  final LandmarkPoint? bottomMouthPosition;
  final LandmarkPoint? leftEarPosition;
  final LandmarkPoint? rightEarPosition;

  /// Normalized bounding box relative to image dimensions (0.0 to 1.0)
  Rect get normalizedBoundingBox => Rect.fromLTRB(
        boundingBox.left / imageSize.width,
        boundingBox.top / imageSize.height,
        boundingBox.right / imageSize.width,
        boundingBox.bottom / imageSize.height,
      );

  double get faceAreaRatio {
    final faceArea = boundingBox.width * boundingBox.height;
    final imageArea = imageSize.width * imageSize.height;
    return faceArea / imageArea;
  }

  bool get isFaceTooFar => faceAreaRatio < 0.015;
  bool get isFaceTooClose => faceAreaRatio > 0.70;

  @override
  String toString() => 'FaceData(yaw: ${headEulerAngleY.toStringAsFixed(1)}, '
      'pitch: ${headEulerAngleX.toStringAsFixed(1)}, '
      'leftEye: ${leftEyeOpenProbability.toStringAsFixed(2)}, '
      'rightEye: ${rightEyeOpenProbability.toStringAsFixed(2)})';
}
