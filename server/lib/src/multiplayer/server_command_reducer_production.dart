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
    if (command is StartCityProjectCommand) {
      return _applyStartCityProject(
        save,
        state,
        command,
        actorPlayerId,
        ruleset,
      );
    }
    if (command is SetCitySpecializationCommand) {
      return _applySetCitySpecialization(save, state, command, actorPlayerId);
    }
    if (command is RushProductionCommand) {
      return _applyRushProduction(
        save,
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    return _applyStartProductionCommand(
      save: save,
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapView: mapView,
      ruleset: ruleset,
    );
  }

  _CommandApplication _applyStartProductionCommand({
    required GameSave save,
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    if (command is StartBuildingCommand) {
      return _applyStartBuilding(
        save,
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    if (command is StartWonderCommand) {
      return _applyStartWonder(
        save,
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    if (command is StartUnitProductionCommand) {
      return _applyStartUnitProduction(
        save,
        state,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    throw ArgumentError.value(
      command,
      'command',
      'Expected a production command',
    );
  }

  _CommandApplication _applyStartCityProject(
    GameSave save,
    PersistentGameState state,
    StartCityProjectCommand command,
    String actorPlayerId,
    GameRuleset ruleset,
  ) {
    final result = CityProductionCommandResolver.startCityProject(
      cities: state.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: ruleset.city,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: !result.accepted || identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applySetCitySpecialization(
    GameSave save,
    PersistentGameState state,
    SetCitySpecializationCommand command,
    String actorPlayerId,
  ) {
    final result = CityProductionCommandResolver.setCitySpecialization(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: !result.accepted || identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyStartBuilding(
    GameSave save,
    PersistentGameState state,
    StartBuildingCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final result = CityProductionCommandResolver.startBuilding(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapView,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: !result.accepted ? state : state.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyStartWonder(
    GameSave save,
    PersistentGameState state,
    StartWonderCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final result = CityProductionCommandResolver.startWonder(
      cities: state.cities,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapView,
      wonderRuleset: ruleset.wonders,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: !result.accepted ? state : state.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyStartUnitProduction(
    GameSave save,
    PersistentGameState state,
    StartUnitProductionCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final result = CityProductionCommandResolver.startUnitProduction(
      cities: state.cities,
      units: state.units,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapView: mapView,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: !result.accepted ? state : state.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyRushProduction(
    GameSave save,
    PersistentGameState state,
    RushProductionCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final result = RushProductionCommandResolver.resolve(
      cities: state.cities,
      units: state.units,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      playerGold: state.playerGold,
      playerStabilityNet: state.playerStabilityNet,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapView,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      stabilityRuleset: ruleset.stability,
      wonderRuleset: ruleset.wonders,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: result.accepted ? _rushState(state, result) : state,
      events: result.events,
      reason: result.reason,
    );
  }

  PersistentGameState _rushState(
    PersistentGameState state,
    RushProductionCommandResult result,
  ) {
    return state.copyWith(
      cities: identical(result.cities, state.cities) ? null : result.cities,
      units: identical(result.units, state.units) ? null : result.units,
      playerGold: identical(result.playerGold, state.playerGold)
          ? null
          : result.playerGold,
      research: identical(result.research, state.research)
          ? null
          : result.research,
      wonderRegistry: identical(result.wonderRegistry, state.wonderRegistry)
          ? null
          : result.wonderRegistry,
    );
  }
}
