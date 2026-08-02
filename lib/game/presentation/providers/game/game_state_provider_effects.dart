part of 'game_state_provider.dart';

void _warnGameState(
  Ref ref,
  String message,
  Object? error,
  StackTrace? stackTrace,
) {
  ref
      .read(gameLoggerProvider)
      .warn('GameStateNotifier', message, error, stackTrace);
}

extension GameStateNotifierEffects on GameStateNotifier {
  Future<void> _presentExternalSnapshot({
    required GameClientState? previousState,
    required GameClientState nextState,
    required List<GameEvent> events,
    required List<MovementCommandExecution> movementExecutions,
    required PresentationBatchIdentity identity,
    required String? viewerPlayerId,
    required int turn,
    required RendererViewModel? renderer,
    required GameAudioController audioController,
    required GameEventNotificationsNotifier notifications,
    required bool Function() isMounted,
  }) async {
    if (previousState == null) return;
    final transitionEffects =
        DomainEventPresentationProjector.projectObservedBatch(
          identity: identity,
          interactionEffects: const [],
          previousState: previousState,
          state: nextState,
          events: events,
          visibleMovementExecutions: movementExecutions,
          viewerPlayerId: viewerPlayerId,
          turn: _eventTurnFor(events, fallbackTurn: turn),
        );
    final cues = [
      ...GameSoundCueMapper.forRendererEffects(
        effects: transitionEffects.effects,
        state: nextState,
        previousState: previousState,
      ),
      ...GameSoundCueMapper.forEvents(
        events: events,
        state: nextState,
        previousState: previousState,
      ),
    ];
    if (cues.isNotEmpty) {
      audioController.playAll(cues);
    }
    if (renderer != null) {
      await renderer.applyProjectedTransition(
        nextState,
        transitionEffects,
        currentTurn: turn,
      );
    }
    if (!isMounted()) return;
    notifications.addAll(
      events,
      nextState,
      previousState: previousState,
      turn: turn,
    );
  }

  int? _eventTurnFor(Iterable<GameEvent> events, {required int fallbackTurn}) {
    for (final event in events) {
      final completedTurn = GameEventDescriptor.forEvent(event).completedTurn;
      if (completedTurn != null) return completedTurn;
    }
    return fallbackTurn;
  }

  void _warn(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isMounted) return;
    _warnGameState(_providerRef, message, error, stackTrace);
  }
}

PresentationBatchIdentity _liveBatchIdentity(String sourceId, int eventOffset) {
  return PresentationBatchIdentity(
    sourceId: sourceId,
    eventOffset: eventOffset,
  );
}

List<GameEvent> _presentedLiveEvents(
  LiveSnapshotPresentationDecision presentation,
  LiveServerEvent? liveEvent,
) {
  final event = presentation.canPresentLiveTransition ? liveEvent : null;
  return event?.events ?? const [];
}
