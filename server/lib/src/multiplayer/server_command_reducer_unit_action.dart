part of 'server_command_reducer.dart';

extension _ServerCommandReducerUnitAction on ServerCommandReducer {
  _CommandApplication _applyDomainCommandEngine(
    CanonicalGameSnapshot snapshot,
    DomainCommand command,
    String actorPlayerId,
    int commandTick,
    MapReadView mapView,
    GameRuleset ruleset, {
    List<String> turnPlayerIds = const [],
    List<String> requiredTurnSubmissionPlayerIds = const [],
    DateTime? savedAt,
    bool preserveNonParticipantTurnStates = false,
    bool trackTimeoutStreaks = false,
  }) {
    final result = const GameEngine().apply(
      snapshot: snapshot,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: mapView,
        ruleset: ruleset,
        commandTick: commandTick,
        turnPlayerIds: turnPlayerIds,
        requiredTurnSubmissionPlayerIds: requiredTurnSubmissionPlayerIds,
        savedAt: savedAt,
        preserveNonParticipantTurnStates: preserveNonParticipantTurnStates,
        trackTimeoutStreaks: trackTimeoutStreaks,
      ),
    );
    return _commandApplicationFromEngine(snapshot, result);
  }
}
