/// All possible states the liveness engine can be in.
enum DetectionStatus {
  initializing,
  noFace,
  multipleFaces,
  faceTooFar,
  faceTooClose,
  faceNotCentered,
  lowLight,
  overExposed,
  blurry,
  fakeDetected,
  ready,
  actionInProgress,
  completed,
  failed,
}

extension DetectionStatusX on DetectionStatus {
  String get message {
    switch (this) {
      case DetectionStatus.initializing:
        return 'Iniciando a câmera...';
      case DetectionStatus.noFace:
        return 'Posicione seu rosto dentro do contorno.';
      case DetectionStatus.multipleFaces:
        return 'Deixe apenas uma pessoa visível na câmera.';
      case DetectionStatus.faceTooFar:
        return 'Aproxime um pouco o rosto da câmera.';
      case DetectionStatus.faceTooClose:
        return 'Afaste um pouco o rosto da câmera.';
      case DetectionStatus.faceNotCentered:
        return 'Centralize seu rosto dentro do contorno.';
      case DetectionStatus.lowLight:
        return 'O ambiente está escuro. Procure um local bem iluminado.';
      case DetectionStatus.overExposed:
        return 'Há luz demais. Evite luz forte atrás de você.';
      case DetectionStatus.blurry:
        return 'A imagem está desfocada. Mantenha o celular firme.';
      case DetectionStatus.fakeDetected:
        return 'Use seu rosto ao vivo. Não utilize foto ou outra tela.';
      case DetectionStatus.ready:
        return 'Mantenha o rosto parado...';
      case DetectionStatus.actionInProgress:
        return '';
      case DetectionStatus.completed:
        return 'Prova de vida concluída!';
      case DetectionStatus.failed:
        return 'Não foi possível confirmar. Tente novamente.';
    }
  }

  bool get isError {
    switch (this) {
      case DetectionStatus.noFace:
      case DetectionStatus.multipleFaces:
      case DetectionStatus.faceTooFar:
      case DetectionStatus.faceTooClose:
      case DetectionStatus.faceNotCentered:
      case DetectionStatus.lowLight:
      case DetectionStatus.overExposed:
      case DetectionStatus.blurry:
      case DetectionStatus.fakeDetected:
      case DetectionStatus.failed:
        return true;
      default:
        return false;
    }
  }

  bool get isSuccess => this == DetectionStatus.completed;
  bool get isProcessing =>
      this == DetectionStatus.actionInProgress || this == DetectionStatus.ready;
  bool get isQualityIssue =>
      this == DetectionStatus.lowLight ||
      this == DetectionStatus.overExposed ||
      this == DetectionStatus.blurry;
}
