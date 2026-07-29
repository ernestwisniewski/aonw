part of 'server_command_reducer.dart';

extension _ServerCommandReducerUnitAction on ServerCommandReducer {
  _CommandApplication _applyUnitActionEngine(
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
      ),
      final GameEngineRejected rejected => _CommandApplication.reject(
        snapshot: snapshot,
        reason: rejected.reason,
      ),
    };
  }

  _CommandApplication _applyCancelUnitAction(
    CanonicalGameSnapshot snapshot,
    CancelUnitActionCommand command,
    String actorPlayerId,
  ) {
    return _applyUnitActionResult(
      snapshot,
      UnitActionCommandResolver.cancelUnitAction(
        units: snapshot.domain.units,
        artifacts: snapshot.domain.artifacts,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyUnitActionResult(
    CanonicalGameSnapshot snapshot,
    UnitActionCommandResult result,
  ) {
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }
    final domain = snapshot.domain;
    final unitsChanged = !identical(result.units, domain.units);
    final artifactsChanged = !identical(result.artifacts, domain.artifacts);
    final domainChanged = unitsChanged || artifactsChanged;
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: domainChanged
          ? domain.copyWith(
              units: unitsChanged ? result.units : null,
              artifacts: artifactsChanged ? result.artifacts : null,
            )
          : null,
      interaction: _interactionReplacement(
        snapshot.interaction,
        result.interaction,
      ),
    );
  }
}
