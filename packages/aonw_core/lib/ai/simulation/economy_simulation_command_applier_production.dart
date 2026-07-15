part of 'economy_simulation.dart';

extension _EconomySimulationProductionCommandApplier
    on _EconomySimulationCommandApplier {
  _ApplyCommandResult _applyProductionCommand({
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required WorldMap worldMap,
    required GameRuleset ruleset,
  }) {
    return switch (command) {
      StartBuildingCommand() => _startBuilding(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        worldMap: worldMap,
        ruleset: ruleset,
      ),
      StartUnitProductionCommand() => _startUnit(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        worldMap: worldMap,
        ruleset: ruleset,
      ),
      StartCityProjectCommand() => _startProject(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        ruleset: ruleset,
      ),
      StartWonderCommand() => _startWonder(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        worldMap: worldMap,
        ruleset: ruleset,
      ),
      _ => throw ArgumentError.value(
        command,
        'command',
        'Expected a production command',
      ),
    };
  }

  _ApplyCommandResult _startBuilding({
    required PersistentGameState state,
    required StartBuildingCommand command,
    required String actorPlayerId,
    required WorldMap worldMap,
    required GameRuleset ruleset,
  }) {
    final result = const PersistentCityProductionResolver().startBuilding(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      worldMap: worldMap,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    return _ApplyCommandResult(accepted: result.accepted, state: result.state);
  }

  _ApplyCommandResult _startUnit({
    required PersistentGameState state,
    required StartUnitProductionCommand command,
    required String actorPlayerId,
    required WorldMap worldMap,
    required GameRuleset ruleset,
  }) {
    final result = const PersistentCityProductionResolver().startUnitProduction(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      worldMap: worldMap,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    return _ApplyCommandResult(accepted: result.accepted, state: result.state);
  }

  _ApplyCommandResult _startProject({
    required PersistentGameState state,
    required StartCityProjectCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    final result = const PersistentCityProductionResolver().startCityProject(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: ruleset.city,
      paceBalance: ruleset.paceBalance,
    );
    return _ApplyCommandResult(accepted: result.accepted, state: result.state);
  }

  _ApplyCommandResult _startWonder({
    required PersistentGameState state,
    required StartWonderCommand command,
    required String actorPlayerId,
    required WorldMap worldMap,
    required GameRuleset ruleset,
  }) {
    final result = const PersistentCityProductionResolver().startWonder(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      worldMap: worldMap,
      wonderRuleset: ruleset.wonders,
      paceBalance: ruleset.paceBalance,
    );
    return _ApplyCommandResult(
      accepted: result.accepted,
      state: result.state,
      reason: result.reason,
    );
  }
}
