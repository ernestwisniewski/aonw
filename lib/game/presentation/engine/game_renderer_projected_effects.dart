part of 'game_renderer.dart';

final Expando<ProjectedGameEffectCursor> _gameRendererProjectionCursors =
    Expando();
final Expando<ProjectedGameTransitionQueue<GameClientState>>
_gameRendererTransitionQueues = Expando();
final Expando<AuthoritativePresentationScheduler>
_gameRendererPresentationSchedulers = Expando();

extension GameRendererProjectedEffects on GameRenderer {
  ProjectedGameEffectCursor get _projectedEffectCursor {
    return _gameRendererProjectionCursors[this] ??= ProjectedGameEffectCursor();
  }

  ProjectedGameTransitionQueue<GameClientState> get _projectedTransitionQueue {
    return _gameRendererTransitionQueues[this] ??=
        ProjectedGameTransitionQueue<GameClientState>();
  }

  AuthoritativePresentationScheduler? get _authoritativeScheduler {
    final clock = presentationClock;
    if (clock == null) return null;
    return _gameRendererPresentationSchedulers[this] ??=
        AuthoritativePresentationScheduler(clock: clock);
  }

  Future<void> applyProjectedTransition(
    GameClientState state,
    ProjectedGameEffectBatch batch, {
    int? currentTurn,
  }) async {
    final ready = _projectedTransitionQueue.enqueue(
      ProjectedGameTransition(
        state: state,
        batch: batch,
        currentTurn: currentTurn,
      ),
    );
    for (final transition in ready) {
      final projectedEffects = _projectedEffectCursor.consumeBatch(
        transition.batch,
      );
      final scheduler = _authoritativeScheduler;
      if (scheduler == null) {
        await applyTransition(
          transition.state,
          projectedEffects,
          currentTurn: transition.currentTurn,
        );
        continue;
      }
      await _transitionHandler.enqueue(() async {
        await scheduler.waitForOrStartLate(transition.batch);
        await _transitionHandler.applyNow(
          transition.state,
          projectedEffects,
          currentTurn: transition.currentTurn,
        );
      });
    }
  }

  void resetProjectedEffectCursorForReplaySeek() {
    _projectedEffectCursor.resetForReplaySeek();
    _projectedTransitionQueue.resetForReplaySeek();
  }

  void activateProjectedEffectSource(String sourceId, {int? nextEventOffset}) {
    _projectedEffectCursor.activateSource(
      sourceId,
      nextEventOffset: nextEventOffset,
    );
    _projectedTransitionQueue.activateSource(
      sourceId,
      nextEventOffset: nextEventOffset,
    );
  }
}
