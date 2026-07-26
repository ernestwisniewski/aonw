part of 'server_command_reducer.dart';

extension _ServerProductionCommandReducer on ServerCommandReducer {
  _CommandApplication _applyProductionCommand({
    required CanonicalGameSnapshot snapshot,
    required GameCommand command,
    required String actorPlayerId,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    if (command is StartCityProjectCommand) {
      return _applyStartCityProject(snapshot, command, actorPlayerId, ruleset);
    }
    if (command is SetCitySpecializationCommand) {
      return _applySetCitySpecialization(snapshot, command, actorPlayerId);
    }
    if (command is RushProductionCommand) {
      return _applyRushProduction(
        snapshot,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    return _applyStartProductionCommand(
      snapshot: snapshot,
      command: command,
      actorPlayerId: actorPlayerId,
      mapView: mapView,
      ruleset: ruleset,
    );
  }

  _CommandApplication _applyStartProductionCommand({
    required CanonicalGameSnapshot snapshot,
    required GameCommand command,
    required String actorPlayerId,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    if (command is StartBuildingCommand) {
      return _applyStartBuilding(
        snapshot,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    if (command is StartWonderCommand) {
      return _applyStartWonder(
        snapshot,
        command,
        actorPlayerId,
        mapView,
        ruleset,
      );
    }
    if (command is StartUnitProductionCommand) {
      return _applyStartUnitProduction(
        snapshot,
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
    CanonicalGameSnapshot snapshot,
    StartCityProjectCommand command,
    String actorPlayerId,
    GameRuleset ruleset,
  ) {
    final domain = snapshot.domain;
    final result = CityProductionCommandResolver.startCityProject(
      cities: domain.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: ruleset.city,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: !result.accepted || identical(result.cities, domain.cities)
          ? null
          : domain.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applySetCitySpecialization(
    CanonicalGameSnapshot snapshot,
    SetCitySpecializationCommand command,
    String actorPlayerId,
  ) {
    final domain = snapshot.domain;
    final result = CityProductionCommandResolver.setCitySpecialization(
      cities: domain.cities,
      research: domain.research,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: !result.accepted || identical(result.cities, domain.cities)
          ? null
          : domain.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyStartBuilding(
    CanonicalGameSnapshot snapshot,
    StartBuildingCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final domain = snapshot.domain;
    final result = CityProductionCommandResolver.startBuilding(
      cities: domain.cities,
      research: domain.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapView,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: !result.accepted || identical(result.cities, domain.cities)
          ? null
          : domain.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyStartWonder(
    CanonicalGameSnapshot snapshot,
    StartWonderCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final domain = snapshot.domain;
    final result = CityProductionCommandResolver.startWonder(
      cities: domain.cities,
      research: domain.research,
      wonderRegistry: domain.wonderRegistry,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapView,
      wonderRuleset: ruleset.wonders,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: !result.accepted || identical(result.cities, domain.cities)
          ? null
          : domain.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyStartUnitProduction(
    CanonicalGameSnapshot snapshot,
    StartUnitProductionCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final domain = snapshot.domain;
    final result = CityProductionCommandResolver.startUnitProduction(
      cities: domain.cities,
      units: domain.units,
      artifacts: domain.artifacts,
      fieldImprovements: domain.fieldImprovements,
      research: domain.research,
      resourceTradeAgreements: domain.resourceTradeAgreements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapView: mapView,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: !result.accepted || identical(result.cities, domain.cities)
          ? null
          : domain.copyWith(cities: result.cities),
      reason: result.reason,
    );
  }

  _CommandApplication _applyRushProduction(
    CanonicalGameSnapshot snapshot,
    RushProductionCommand command,
    String actorPlayerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    final domain = snapshot.domain;
    final result = RushProductionCommandResolver.resolve(
      cities: domain.cities,
      units: domain.units,
      artifacts: domain.artifacts,
      fieldImprovements: domain.fieldImprovements,
      playerGold: domain.playerGold,
      playerStabilityNet: domain.playerStabilityNet,
      research: domain.research,
      wonderRegistry: domain.wonderRegistry,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapView,
      cityRuleset: ruleset.city,
      technologyRuleset: ruleset.technology,
      stabilityRuleset: ruleset.stability,
      wonderRuleset: ruleset.wonders,
      paceBalance: ruleset.paceBalance,
    );
    final nextDomain = result.accepted ? _rushDomain(domain, result) : domain;
    return _applicationFrom(
      snapshot: snapshot,
      accepted: result.accepted,
      domain: identical(nextDomain, domain) ? null : nextDomain,
      events: result.events,
      reason: result.reason,
    );
  }

  DomainState _rushDomain(
    DomainState domain,
    RushProductionCommandResult result,
  ) {
    final cities = _productionChange(result.cities, domain.cities);
    final units = _productionChange(result.units, domain.units);
    final playerGold = _productionChange(result.playerGold, domain.playerGold);
    final research = _productionChange(result.research, domain.research);
    final wonderRegistry = _productionChange(
      result.wonderRegistry,
      domain.wonderRegistry,
    );
    if ([
      cities,
      units,
      playerGold,
      research,
      wonderRegistry,
    ].every((replacement) => replacement == null)) {
      return domain;
    }
    return domain.copyWith(
      cities: cities,
      units: units,
      playerGold: playerGold,
      research: research,
      wonderRegistry: wonderRegistry,
    );
  }
}

T? _productionChange<T extends Object>(T next, T current) =>
    identical(next, current) ? null : next;
