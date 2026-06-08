/// Flutter Face Liveness — AI-powered face detection, liveness verification,
/// and anti-spoof protection using Google ML Kit + optional TFLite.
///
/// ## Quick start
/// ```dart
/// import 'package:flutter_face_liveness/flutter_face_liveness.dart';
///
/// FlutterFaceLiveness(
///   actions: [LivenessAction.blink, LivenessAction.turnLeft, LivenessAction.smile],
///   config: LivenessConfig(
///     randomizeActions: true,
///     enableAntiSpoof: true,
///   ),
///   onSuccess: (result) {
///     print('Verified — session: ${result.sessionId}');
///     print('Confidence: ${result.confidenceScore}');
///   },
///   onFailed: (reason) => print('Failed: $reason'),
/// )
/// ```
library;


// Widget + controller
export 'src/flutter_face_liveness_widget.dart';
export 'src/liveness_controller.dart';

// Models
export 'src/models/liveness_action.dart';
export 'src/models/liveness_config.dart';
export 'src/models/liveness_result.dart';
export 'src/models/face_data.dart';
export 'src/models/face_mesh_data.dart';
export 'src/models/detection_status.dart';
export 'src/models/frame_quality.dart';

// ML / security (useful for advanced integrations)
export 'src/ml/anti_spoof_engine.dart' show AntiSpoofEngine, AntiSpoofResult;
export 'src/ml/tflite_service.dart'          show TFLiteService;
export 'src/ml/tflite_model_downloader.dart' show TFLiteModelDownloader, TFLiteModelDownloadException;
export 'src/security/session_manager.dart' show SessionManager;

// Face identity
export 'src/identity/face_identity_service.dart'
    show FaceIdentityService, FaceIdMode, FaceMatchOutcome, FaceMatchResult;
export 'src/identity/face_model_downloader.dart'
    show FaceModelDownloader, FaceModelDownloadException;
export 'src/ml/face_detector_service.dart' show RawFrameData;
