part of 'game_renderer.dart';

final Expando<ProjectedGameEffectCursor> _gameRendererProjectionCursors =
    Expando();
final Expando<ProjectedGameTransitionQueue<GameClientState>>
_gameRendererTransitionQueues = Expando();
final Expando<AuthoritativePresentationScheduler>
_gameRendererPresentationSchedulers = Expando();

extension GameRendererProjectedEffects on GameRenderer {
  ProjectedGameEffectCursor get _projectedEffectCursor =>
      _gameRendererProjectionCursors[this] ??= ProjectedGameEffectCursor();

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
    PresentationStartCallback? onPresentationStart,
  }) async {
    final ready = _projectedTransitionQueue.enqueue(
      ProjectedGameTransition(
        state: state,
        batch: batch,
        currentTurn: currentTurn,
        onPresentationStart: onPresentationStart,
      ),
    );
    for (final transition in ready) {
      final projectedEffects = _projectedEffectCursor.consumeBatch(
        transition.batch,
      );
      await ProjectedTransitionPresenter.present(
        transitionHandler: _transitionHandler,
        transition: transition,
        effects: projectedEffects,
        presentationReady: _lifecycleHandler.initialPresentationReady,
        ensureActive: _ensureRendererActive,
        scheduler: _authoritativeScheduler,
      );
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
