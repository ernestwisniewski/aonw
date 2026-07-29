part of 'server_command_reducer.dart';

extension _ServerCommandReducerUnitAction on ServerCommandReducer {
  _CommandApplication _applyDomainCommandEngine(
    CanonicalGameSnapshot snapshot,
    DomainCommand command,
    String actorPlayerId,
    int commandTick,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final result = const GameEngine().apply(
      snapshot: snapshot,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: mapView,
        ruleset: ruleset,
        commandTick: commandTick,
      ),
    );
    return switch (result) {
      GameEngineAccepted() => _CommandApplication.accept(
        snapshot: result.snapshot,
        events: result.events,
        movementExecutions: result.movementDelta.executions,
      ),
      final GameEngineRejected rejected => _CommandApplication.reject(
        snapshot: snapshot,
        reason: rejected.reason,
      ),
    };
  }
}
