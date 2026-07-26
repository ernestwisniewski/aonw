part of 'server_command_reducer.dart';

extension _ServerCommandReducerWorker on ServerCommandReducer {
  _CommandApplication _applySelectWorkerImprovement(
    CanonicalGameSnapshot snapshot,
    SelectWorkerImprovementCommand command,
    String actorPlayerId,
    MapTileLookup mapTiles,
    GameRuleset ruleset,
  ) {
    return _applyWorkerResult(
      snapshot,
      WorkerCommandResolver.selectWorkerImprovement(
        units: snapshot.domain.units,
        cities: snapshot.domain.cities,
        fieldImprovements: snapshot.domain.fieldImprovements,
        research: snapshot.domain.research,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: ruleset.paceBalance,
      ),
    );
  }

  _CommandApplication _applyConfirmWorkerImprovement(
    CanonicalGameSnapshot snapshot,
    ConfirmWorkerImprovementCommand command,
    String actorPlayerId,
    MapTileLookup mapTiles,
    GameRuleset ruleset,
  ) {
    return _applyWorkerResult(
      snapshot,
      WorkerCommandResolver.confirmWorkerImprovement(
        units: snapshot.domain.units,
        cities: snapshot.domain.cities,
        fieldImprovements: snapshot.domain.fieldImprovements,
        research: snapshot.domain.research,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: ruleset.paceBalance,
      ),
    );
  }

  _CommandApplication _applyCancelWorkerJob(
    CanonicalGameSnapshot snapshot,
    CancelWorkerJobCommand command,
    String actorPlayerId,
  ) {
    return _applyWorkerResult(
      snapshot,
      WorkerCommandResolver.cancelWorkerJob(
        units: snapshot.domain.units,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyAssignWorkerToHex(
    CanonicalGameSnapshot snapshot,
    AssignWorkerToHexCommand command,
    String actorPlayerId,
    MapTileLookup mapTiles,
  ) {
    return _applyWorkerResult(
      snapshot,
      WorkerCommandResolver.assignWorkerToHex(
        units: snapshot.domain.units,
        cities: snapshot.domain.cities,
        fieldImprovements: snapshot.domain.fieldImprovements,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
      ),
    );
  }

  _CommandApplication _applyCancelWorkerAssignment(
    CanonicalGameSnapshot snapshot,
    CancelWorkerAssignmentCommand command,
    String actorPlayerId,
  ) {
    return _applyWorkerResult(
      snapshot,
      WorkerCommandResolver.cancelWorkerAssignment(
        units: snapshot.domain.units,
        interaction: snapshot.interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  _CommandApplication _applyWorkerResult(
    CanonicalGameSnapshot snapshot,
    WorkerCommandResult result,
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
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: unitsChanged ? domain.copyWith(units: result.units) : null,
      interaction: _interactionReplacement(
        snapshot.interaction,
        result.interaction,
      ),
    );
  }
}
