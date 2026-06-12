import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_face_liveness/flutter_face_liveness.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Resultado de uma comparação biométrica 1:1 (documento × selfie).
class ResultadoBiometria {
  final bool combina;
  final double similaridade; // 0.0 – 1.0
  final String? erro;
  const ResultadoBiometria({
    required this.combina,
    required this.similaridade,
    this.erro,
  });
}

/// Comparação facial 1:1 entre o rosto do documento (CNH/RG) e a selfie ao vivo.
///
/// Usa o ML Kit para localizar o rosto (bounding box + olhos) e o
/// [FaceIdentityService] (MobileFaceNet, modelo baixado em runtime) para gerar
/// os embeddings, comparados por similaridade de cosseno. O pré-processador do
/// pacote espera bytes NV21, então cada JPEG é decodificado para RGBA e
/// convertido para NV21.
class BiometriaFacial {
  BiometriaFacial({this.limiar = 0.45});

  /// Similaridade mínima para considerar "mesma pessoa". Documento × selfie
  /// gera similaridade menor que selfie × selfie, por isso o limiar é mais
  /// baixo que o padrão do pacote (0.82). Ajustável após testes em campo.
  final double limiar;

  final FaceIdentityService _identidade = FaceIdentityService();
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  bool _pronto = false;

  Future<void> inicializar({void Function(double progresso)? onProgresso}) async {
    if (_pronto) return;
    await _identidade.initialize(onModelDownloadProgress: onProgresso);
    _pronto = _identidade.isReady;
  }

  /// Há ao menos um rosto detectável na imagem?
  Future<bool> temRosto(String caminho) async {
    try {
      final faces =
          await _detector.processImage(InputImage.fromFilePath(caminho));
      return faces.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Compara o rosto do documento com o da selfie. Roda 100% no dispositivo.
  Future<ResultadoBiometria> comparar({
    required String caminhoDocumento,
    required String caminhoSelfie,
  }) async {
    await inicializar();
    if (!_pronto) {
      return const ResultadoBiometria(
        combina: false,
        similaridade: 0,
        erro: 'Modelo de biometria indisponível (verifique a internet).',
      );
    }
    final docEmb = await _embeddingDoArquivo(caminhoDocumento);
    if (docEmb == null) {
      return const ResultadoBiometria(
        combina: false,
        similaridade: 0,
        erro: 'Não foi possível detectar o rosto no documento.',
      );
    }
    final selfieEmb = await _embeddingDoArquivo(caminhoSelfie);
    if (selfieEmb == null) {
      return const ResultadoBiometria(
        combina: false,
        similaridade: 0,
        erro: 'Não foi possível detectar o rosto na selfie.',
      );
    }
    final sim = FaceIdentityService.cosineSimilarity(docEmb, selfieEmb);
    final normalizada = ((sim + 1) / 2).clamp(0.0, 1.0); // -1..1 → 0..1
    return ResultadoBiometria(combina: sim >= limiar, similaridade: normalizada);
  }

  Future<List<double>?> _embeddingDoArquivo(String caminho) async {
    final faces =
        await _detector.processImage(InputImage.fromFilePath(caminho));
    if (faces.isEmpty) return null;
    faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
        .compareTo(a.boundingBox.width * a.boundingBox.height));
    final face = faces.first;

    final rgba = await _decodeRgba(await File(caminho).readAsBytes());
    if (rgba == null) return null;

    final nv21 = _rgbaParaNv21(rgba.bytes, rgba.width, rgba.height);
    final olhoEsq = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final olhoDir = face.landmarks[FaceLandmarkType.rightEye]?.position;

    return _identidade.computeEmbedding(
      imageBytes: nv21,
      imageWidth: rgba.width,
      imageHeight: rgba.height,
      faceBoundingBox: face.boundingBox,
      sensorOrientation: 0,
      leftEyeX: olhoEsq?.x.toDouble(),
      leftEyeY: olhoEsq?.y.toDouble(),
      rightEyeX: olhoDir?.x.toDouble(),
      rightEyeY: olhoDir?.y.toDouble(),
    );
  }

  Future<({Uint8List bytes, int width, int height})?> _decodeRgba(
      Uint8List jpg) async {
    final codec = await ui.instantiateImageCodec(jpg);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return null;
    return (bytes: data.buffer.asUint8List(), width: w, height: h);
  }

  /// Converte RGBA (4 bytes/pixel) para NV21 (plano Y + plano VU 4:2:0),
  /// formato consumido pelo pré-processador do flutter_face_liveness no Android.
  Uint8List _rgbaParaNv21(Uint8List rgba, int w, int h) {
    final ySize = w * h;
    final out = Uint8List(ySize + ySize ~/ 2);
    var yi = 0;
    var uvi = ySize;
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        final p = (j * w + i) * 4;
        final r = rgba[p];
        final g = rgba[p + 1];
        final b = rgba[p + 2];
        out[yi++] = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
        if ((j & 1) == 0 && (i & 1) == 0) {
          final v = (0.5 * r - 0.419 * g - 0.081 * b + 128).round().clamp(0, 255);
          final u =
              (-0.169 * r - 0.331 * g + 0.5 * b + 128).round().clamp(0, 255);
          out[uvi++] = v; // NV21: V antes de U
          out[uvi++] = u;
        }
      }
    }
    return out;
  }

  void dispose() {
    _detector.close();
    _identidade.dispose();
  }
}
