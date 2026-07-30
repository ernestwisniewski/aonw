part of 'game_renderer.dart';

final Expando<ProjectedGameEffectCursor> _gameRendererProjectionCursors =
    Expando();

extension GameRendererProjectedEffects on GameRenderer {
  ProjectedGameEffectCursor get _projectedEffectCursor {
    return _gameRendererProjectionCursors[this] ??= ProjectedGameEffectCursor();
  }

  Future<void> applyProjectedTransition(
    GameState state,
    ProjectedGameEffectBatch batch, {
    int? currentTurn,
  }) {
    final projectedEffects = _projectedEffectCursor.consume(
      batch.projectedEffects,
    );
    return applyTransition(state, projectedEffects, currentTurn: currentTurn);
  }

  void resetProjectedEffectCursorForReplaySeek() {
    _projectedEffectCursor.resetForReplaySeek();
  }

  void activateProjectedEffectSource(String sourceId) {
    _projectedEffectCursor.activateSource(sourceId);
  }
}
