part of 'game_state_provider.dart';

extension GameStateNotifierRendererEffects on GameStateNotifier {
  List<RendererEffect> _rendererEffectsForExternalSnapshot({
    required GameState previousState,
    required GameState nextState,
    required Iterable<GameEvent> events,
    String? viewerPlayerId,
    int? turn,
  }) {
    final movementEffects = QueuedMovementEffectBuilder.fromUnitDelta(
      beforeUnits: previousState.units,
      afterUnits: nextState.units,
    );
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
      if (event is AllPlayersSubmittedEvent) return event.turn;
    }
    return fallbackTurn;
  }
}
