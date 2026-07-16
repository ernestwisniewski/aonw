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
      StartBuildingCommand() => _startBuildingProduction(
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      ),
      StartUnitProductionCommand() => _startUnitProduction(
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      ),
      StartCityProjectCommand() => _startCityProject(
        state,
        command,
        actorPlayerId,
        ruleset,
      ),
      StartWonderCommand() => _startWonderProduction(
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      ),
      RushProductionCommand() => _rushProduction(
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
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

PersistentCityProductionResult _startBuildingProduction(
  PersistentGameState state,
  StartBuildingCommand command,
  String actorPlayerId,
  MapReadView mapView,
  GameRuleset ruleset,
) => const PersistentCityProductionResolver().startBuilding(
  state: state,
  command: command,
  actorPlayerId: actorPlayerId,
  mapTiles: mapView,
  cityRuleset: ruleset.city,
  technologyRuleset: ruleset.technology,
  paceBalance: ruleset.paceBalance,
);

PersistentCityProductionResult _startUnitProduction(
  PersistentGameState state,
  StartUnitProductionCommand command,
  String actorPlayerId,
  MapReadView mapView,
  GameRuleset ruleset,
) => const PersistentCityProductionResolver().startUnitProduction(
  state: state,
  command: command,
  actorPlayerId: actorPlayerId,
  mapView: mapView,
  cityRuleset: ruleset.city,
  technologyRuleset: ruleset.technology,
  paceBalance: ruleset.paceBalance,
);

PersistentCityProductionResult _startCityProject(
  PersistentGameState state,
  StartCityProjectCommand command,
  String actorPlayerId,
  GameRuleset ruleset,
) => const PersistentCityProductionResolver().startCityProject(
  state: state,
  command: command,
  actorPlayerId: actorPlayerId,
  cityRuleset: ruleset.city,
  paceBalance: ruleset.paceBalance,
);

PersistentCityProductionResult _startWonderProduction(
  PersistentGameState state,
  StartWonderCommand command,
  String actorPlayerId,
  MapReadView mapView,
  GameRuleset ruleset,
) => const PersistentCityProductionResolver().startWonder(
  state: state,
  command: command,
  actorPlayerId: actorPlayerId,
  mapTiles: mapView,
  wonderRuleset: ruleset.wonders,
  paceBalance: ruleset.paceBalance,
);

PersistentCityProductionResult _rushProduction(
  PersistentGameState state,
  RushProductionCommand command,
  String actorPlayerId,
  MapReadView mapView,
  GameRuleset ruleset,
) => const PersistentCityProductionResolver().rushProduction(
  state: state,
  command: command,
  actorPlayerId: actorPlayerId,
  mapTiles: mapView,
  cityRuleset: ruleset.city,
  technologyRuleset: ruleset.technology,
  stabilityRuleset: ruleset.stability,
  wonderRuleset: ruleset.wonders,
  paceBalance: ruleset.paceBalance,
);
