/// All supported liveness challenge actions.
enum LivenessAction {
  blink,
  turnLeft,
  turnRight,
  lookUp,
  lookDown,
  smile,
  openMouth,
}

extension LivenessActionX on LivenessAction {
  String get instruction {
    switch (this) {
      case LivenessAction.blink:
        return 'Pisque os olhos';
      case LivenessAction.turnLeft:
        return 'Vire o rosto devagar para a esquerda';
      case LivenessAction.turnRight:
        return 'Vire o rosto devagar para a direita';
      case LivenessAction.lookUp:
        return 'Olhe para cima';
      case LivenessAction.lookDown:
        return 'Olhe para baixo';
      case LivenessAction.smile:
        return 'Sorria naturalmente';
      case LivenessAction.openMouth:
        return 'Abra a boca';
    }
  }

  String get shortLabel {
    switch (this) {
      case LivenessAction.blink:
        return 'Piscar';
      case LivenessAction.turnLeft:
        return 'Virar à esquerda';
      case LivenessAction.turnRight:
        return 'Virar à direita';
      case LivenessAction.lookUp:
        return 'Olhar para cima';
      case LivenessAction.lookDown:
        return 'Olhar para baixo';
      case LivenessAction.smile:
        return 'Sorrir';
      case LivenessAction.openMouth:
        return 'Abrir a boca';
    }
  }

  String get iconEmoji {
    switch (this) {
      case LivenessAction.blink:
        return '👁️';
      case LivenessAction.turnLeft:
        return '⬅️';
      case LivenessAction.turnRight:
        return '➡️';
      case LivenessAction.lookUp:
        return '⬆️';
      case LivenessAction.lookDown:
        return '⬇️';
      case LivenessAction.smile:
        return '😊';
      case LivenessAction.openMouth:
        return '😮';
    }
  }

  /// Icon for use in non-emoji UI contexts.
  String get iconCode {
    switch (this) {
      case LivenessAction.blink:
        return 'eye';
      case LivenessAction.turnLeft:
        return 'arrow_left';
      case LivenessAction.turnRight:
        return 'arrow_right';
      case LivenessAction.lookUp:
        return 'arrow_up';
      case LivenessAction.lookDown:
        return 'arrow_down';
      case LivenessAction.smile:
        return 'smile';
      case LivenessAction.openMouth:
        return 'mouth';
    }
  }
}
