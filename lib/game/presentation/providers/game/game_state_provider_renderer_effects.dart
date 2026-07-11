part of 'game_state_provider.dart';

extension GameStateNotifierRendererEffects on GameStateNotifier {
  Future<void> _presentExternalSnapshot({
    required GameState? previousState,
    required GameState nextState,
    required List<GameEvent> events,
    required bool inferDirectMoves,
    required String? viewerPlayerId,
    required int turn,
    required RendererViewModel? renderer,
    required GameAudioController audioController,
    required GameEventNotificationsNotifier notifications,
    required bool Function() isMounted,
  }) async {
    if (previousState == null) return;
    final transitionEffects = _rendererEffectsForExternalSnapshot(
      previousState: previousState,
      nextState: nextState,
      events: events,
      inferDirectMoves: inferDirectMoves,
      viewerPlayerId: viewerPlayerId,
      turn: _eventTurnFor(events, fallbackTurn: turn),
    );
    final cues = [
      ...GameSoundCueMapper.forRendererEffects(
        effects: transitionEffects,
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
      await renderer.applyTransition(
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

  List<RendererEffect> _rendererEffectsForExternalSnapshot({
    required GameState previousState,
    required GameState nextState,
    required Iterable<GameEvent> events,
    bool inferDirectMoves = false,
    String? viewerPlayerId,
    int? turn,
  }) {
    final combatRetreatUnitIds = {
      for (final event in events.whereType<CombatResolvedEvent>())
        if (event.outcome.defenderRetreated) event.defenderUnitId,
    };
    final movementEffects =
        QueuedMovementEffectBuilder.fromUnitDelta(
              beforeUnits: previousState.units,
              afterUnits: nextState.units,
              inferDirectMoves: inferDirectMoves,
            )
            .where((effect) => !combatRetreatUnitIds.contains(effect.unitId))
            .toList(growable: false);
    final animatedUnitIds = {
      for (final effect in movementEffects) effect.unitId,
    };
    return [
      ...movementEffects,
      ...GameEventRendererEffectMapper.effectsFor(
        events: events,
        state: nextState,
        previousState: previousState,
        skipUnitMoveIds: animatedUnitIds,
        viewerPlayerId: viewerPlayerId,
        turn: turn,
      ),
    ];
  }

  int? _eventTurnFor(Iterable<GameEvent> events, {required int fallbackTurn}) {
    for (final event in events) {
      final completedTurn = GameEventDescriptor.forEvent(event).completedTurn;
      if (completedTurn != null) return completedTurn;
    }
    return fallbackTurn;
  }
}
