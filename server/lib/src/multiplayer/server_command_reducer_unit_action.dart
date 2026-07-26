part of 'server_command_reducer.dart';

extension _ServerCommandReducerUnitAction on ServerCommandReducer {
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

  _CommandApplication _applySkipUnitTurn(
    CanonicalGameSnapshot snapshot,
    SkipUnitTurnCommand command,
    String actorPlayerId,
  ) {
    return _applyUnitActionResult(
      snapshot,
      UnitActionCommandResolver.skipUnitTurn(
        units: snapshot.domain.units,
        artifacts: snapshot.domain.artifacts,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyFortifyUnit(
    CanonicalGameSnapshot snapshot,
    FortifyUnitCommand command,
    String actorPlayerId,
  ) {
    return _applyUnitActionResult(
      snapshot,
      UnitActionCommandResolver.fortifyUnit(
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
