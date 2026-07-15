part of 'server_command_reducer.dart';

extension _ServerProductionCommandReducer on ServerCommandReducer {
  _CommandApplication _applyProductionCommand({
    required GameSave save,
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final result = switch (command) {
      StartBuildingCommand() =>
        const PersistentCityProductionResolver().startBuilding(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: mapView,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: ruleset.paceBalance,
        ),
      StartUnitProductionCommand() =>
        const PersistentCityProductionResolver().startUnitProduction(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: mapView,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: ruleset.paceBalance,
        ),
      StartCityProjectCommand() =>
        const PersistentCityProductionResolver().startCityProject(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          cityRuleset: ruleset.city,
          paceBalance: ruleset.paceBalance,
        ),
      StartWonderCommand() =>
        const PersistentCityProductionResolver().startWonder(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: mapView,
          wonderRuleset: ruleset.wonders,
          paceBalance: ruleset.paceBalance,
        ),
      _ => throw ArgumentError.value(
        command,
        'command',
        'Expected a production command',
      ),
    };
    return _fromPersistentResult(save, result);
  }
}
