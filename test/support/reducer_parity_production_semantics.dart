import 'package:aonw_core/domain.dart';

import 'reducer_parity_contract.dart';
import 'reducer_parity_rush_semantics.dart';

bool tryRequireProduction(
  String fixtureId,
  DomainCommand command,
  String actorPlayerId,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
  MapReadView mapView,
  PaceBalance paceBalance,
) {
  if (!reducerParityCommandMatchesFamily('city-production', command)) {
    return false;
  }
  switch (command) {
    case final RushProductionCommand command:
      requireAcceptedRushProduction(
        fixtureId: fixtureId,
        command: command,
        actorPlayerId: actorPlayerId,
        before: before,
        after: after,
        events: events,
        mapTiles: mapView,
        paceBalance: paceBalance,
      );
    case final StartBuildingCommand command:
      _requireAcceptedStartBuilding(
        fixtureId: fixtureId,
        command: command,
        actorPlayerId: actorPlayerId,
        before: before,
        after: after,
        events: events,
        mapTiles: mapView,
        paceBalance: paceBalance,
      );
    case final StartUnitProductionCommand command:
      _requireAcceptedStartUnitProduction(
        fixtureId: fixtureId,
        command: command,
        actorPlayerId: actorPlayerId,
        before: before,
        after: after,
        events: events,
        mapView: mapView,
        paceBalance: paceBalance,
      );
    case final StartCityProjectCommand command:
      _requireAcceptedCityProject(fixtureId, command, before, after, events);
    case final SetCitySpecializationCommand command:
      _requireAcceptedCitySpecialization(
        fixtureId,
        command,
        actorPlayerId,
        before,
        after,
        events,
      );
    case final StartWonderCommand command:
      _requireAcceptedStartWonder(
        fixtureId: fixtureId,
        command: command,
        actorPlayerId: actorPlayerId,
        before: before,
        after: after,
        events: events,
        mapTiles: mapView,
        paceBalance: paceBalance,
      );
    default:
      throw StateError('Expected a production command.');
  }
  return true;
}

void _requireAcceptedStartUnitProduction({
  required String fixtureId,
  required StartUnitProductionCommand command,
  required String actorPlayerId,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
  required MapReadView mapView,
  required PaceBalance paceBalance,
}) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 ||
      before.cities.length < 2 ||
      before.runtimeState.turnStartedAt == null ||
      events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel, '
      'preserve runtime state, and emit no events.',
    );
  }

  final beforeCity = before.cities[cityIndex];
  final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
    playerId: beforeCity.ownerPlayerId,
    unitType: command.unitType,
    research: before.research,
    ruleset: TechnologyRulesets.standard,
  );
  final resourcesAvailable = UnitProductionRequirementRules.meetsRequirements(
    playerId: beforeCity.ownerPlayerId,
    unitType: command.unitType,
    cities: before.cities,
    mapTiles: mapView.mapTiles,
    ruleset: CityRulesets.standard,
    research: before.research,
    resourceTradeAgreements: before.runtimeState.resourceTradeAgreements,
  );
  final coastAvailable = CityUnitProductionRules.canProduceInCity(
    city: beforeCity,
    unitType: command.unitType,
    mapTiles: mapView.mapTiles,
  );
  final supplyAvailable = CityUnitSupplyRules.canQueueUnit(
    playerId: beforeCity.ownerPlayerId,
    unitType: command.unitType,
    cities: before.cities,
    units: before.units,
    artifacts: before.artifacts,
    fieldImprovements: before.fieldImprovements,
    mapView: mapView,
    cityRuleset: CityRulesets.standard,
    research: before.research,
    technologyRuleset: TechnologyRulesets.standard,
    replacingCityId: beforeCity.id,
  );
  if (beforeCity.ownerPlayerId != actorPlayerId ||
      !CityProductionRules.canProduceUnit(
        command.unitType,
        ruleset: CityRulesets.standard,
        technologyUnlocked: technologyUnlocked,
      ) ||
      !resourcesAvailable ||
      !coastAvailable ||
      !supplyAvailable) {
    throw FormatException(
      '$fixtureId must characterize a controlled unit target that passes '
      'technology, resource, coast, and supply checks.',
    );
  }

  final activeInvestment = beforeCity.productionQueue?.investedProduction;
  final productionCost = CityProductionRules.unitProductionCost(
    command.unitType,
    ruleset: CityRulesets.standard,
    paceBalance: paceBalance,
  );
  final rolloverInvestment = activeInvestment == null
      ? _reviewedRolloverInvestment(
          storedOverflow: beforeCity.productionOverflow,
          productionCost: productionCost,
        )
      : 0;
  final expectedCity = beforeCity.copyWith(
    productionQueue: CityProductionQueue.unit(
      unitType: command.unitType,
      investedProduction: activeInvestment ?? rolloverInvestment,
    ),
    productionOverflow: activeInvestment == null
        ? 0
        : beforeCity.productionOverflow,
  );
  final expectedCities = [...before.cities]..[cityIndex] = expectedCity;
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city queue while preserving '
      'pace-scaled overflow, active investment, city order, runtime, sentinels, '
      'and every unrelated state slice.',
    );
  }
}

void _requireAcceptedStartBuilding({
  required String fixtureId,
  required StartBuildingCommand command,
  required String actorPlayerId,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
  required MapTileLookup mapTiles,
  required PaceBalance paceBalance,
}) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 ||
      before.cities.length < 2 ||
      before.runtimeState.turnStartedAt == null ||
      events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel, '
      'preserve runtime state, and emit no events.',
    );
  }
  final beforeCity = before.cities[cityIndex];
  final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
    playerId: beforeCity.ownerPlayerId,
    buildingType: command.buildingType,
    research: before.research,
    ruleset: TechnologyRulesets.standard,
  );
  final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
    city: beforeCity,
    buildingType: command.buildingType,
    mapTiles: mapTiles,
    ruleset: CityRulesets.standard,
    research: before.research,
  );
  if (beforeCity.ownerPlayerId != actorPlayerId ||
      !technologyUnlocked ||
      !requirementsMet ||
      beforeCity.buildings.contains(command.buildingType)) {
    throw FormatException(
      '$fixtureId must characterize a controlled and available building that '
      'has not already been built.',
    );
  }

  final activeInvestment = beforeCity.productionQueue?.investedProduction;
  final baseCost = CityRulesets.standard
      .buildingDefinitionFor(command.buildingType)
      .productionCost;
  final productionCost = paceBalance.buildingProductionCost(baseCost);
  final rolloverInvestment = activeInvestment == null
      ? _reviewedRolloverInvestment(
          storedOverflow: beforeCity.productionOverflow,
          productionCost: productionCost,
        )
      : 0;
  final expectedCity = beforeCity.copyWith(
    productionQueue: CityProductionQueue.building(
      buildingType: command.buildingType,
      investedProduction: activeInvestment ?? rolloverInvestment,
    ),
    productionOverflow: activeInvestment == null
        ? 0
        : beforeCity.productionOverflow,
  );
  final expectedCities = [...before.cities]..[cityIndex] = expectedCity;
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city queue while preserving '
      'pace-scaled overflow, active investment, city order, sentinels, and '
      'all unrelated state.',
    );
  }
}

int _reviewedRolloverInvestment({
  required int storedOverflow,
  required int productionCost,
}) {
  if (storedOverflow <= 0 || productionCost <= 1) return 0;
  final cap = productionCost ~/ 2;
  return storedOverflow < cap ? storedOverflow : cap;
}

void _requireAcceptedCitySpecialization(
  String fixtureId,
  SetCitySpecializationCommand command,
  String actorPlayerId,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 ||
      before.cities.length < 2 ||
      before.runtimeState.turnStartedAt == null ||
      events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel, '
      'preserve runtime state, and emit no events.',
    );
  }

  final beforeCity = before.cities[cityIndex];
  final specializationUnlocked = before.research
      .forPlayer(beforeCity.ownerPlayerId)
      .hasUnlocked(TechnologyId.specialization);
  if (beforeCity.ownerPlayerId != actorPlayerId ||
      !specializationUnlocked ||
      beforeCity.specialization == command.specialization ||
      !CitySpecializationRules.hasRequiredBuilding(
        beforeCity.buildings,
        command.specialization,
      )) {
    throw FormatException(
      '$fixtureId must characterize a controlled, unlocked, changed '
      'specialization with its required building.',
    );
  }

  final expectedCities = [...before.cities]
    ..[cityIndex] = beforeCity.copyWith(specialization: command.specialization);
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city specialization while '
      'preserving city order, sentinels, production, and unrelated state.',
    );
  }
}

void _requireAcceptedCityProject(
  String fixtureId,
  StartCityProjectCommand command,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 || before.cities.length < 2 || events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel '
      'without emitting events.',
    );
  }

  final beforeCity = before.cities[cityIndex];
  final activeInvestment = beforeCity.productionQueue?.investedProduction;
  final expectedCity = beforeCity.copyWith(
    productionQueue: CityProductionQueue.target(
      target: ProjectProductionTarget(command.projectType),
      investedProduction: activeInvestment ?? 0,
    ),
    productionOverflow: activeInvestment == null
        ? 0
        : beforeCity.productionOverflow,
  );
  final expectedCities = [...before.cities]..[cityIndex] = expectedCity;
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city queue while preserving '
      'investment, overflow, city order, sentinels, and unrelated state.',
    );
  }
}

void _requireAcceptedStartWonder({
  required String fixtureId,
  required StartWonderCommand command,
  required String actorPlayerId,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
  required MapTileLookup mapTiles,
  required PaceBalance paceBalance,
}) {
  final cityIndex = before.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (cityIndex < 0 ||
      before.cities.length < 2 ||
      before.runtimeState.turnStartedAt == null ||
      events.isNotEmpty) {
    throw FormatException(
      '$fixtureId must target an existing city beside an unrelated sentinel, '
      'preserve runtime state, and emit no events.',
    );
  }

  final beforeCity = before.cities[cityIndex];
  final definition = WonderRuleset.standard.definitionFor(command.wonderType);
  final technologyUnlocked = before.research
      .forPlayer(beforeCity.ownerPlayerId)
      .hasUnlocked(definition.unlockTech);
  final requirementsMissing = WonderRequirementRules.missingRequirements(
    city: beforeCity,
    wonderType: command.wonderType,
    mapTiles: mapTiles,
    ruleset: WonderRuleset.standard,
    research: before.research,
  );
  final targetCityAlreadyBuilding =
      beforeCity.productionQueue?.target is WonderProductionTarget;
  final playerAlreadyBuilding = before.cities.any(
    (city) =>
        city.id != beforeCity.id &&
        city.ownerPlayerId == beforeCity.ownerPlayerId &&
        city.productionQueue?.target is WonderProductionTarget,
  );
  if (beforeCity.ownerPlayerId != actorPlayerId ||
      before.wonderRegistry.ownerOf(command.wonderType) != null ||
      !technologyUnlocked ||
      requirementsMissing.isNotEmpty ||
      targetCityAlreadyBuilding ||
      playerAlreadyBuilding) {
    throw FormatException(
      '$fixtureId must characterize a controlled and independently available '
      'wonder target.',
    );
  }

  final activeInvestment = beforeCity.productionQueue?.investedProduction;
  final productionCost = paceBalance.buildingProductionCost(
    definition.productionCost,
  );
  final rolloverInvestment = activeInvestment == null
      ? _reviewedRolloverInvestment(
          storedOverflow: beforeCity.productionOverflow,
          productionCost: productionCost,
        )
      : 0;
  final expectedCity = beforeCity.copyWith(
    productionQueue: CityProductionQueue.wonder(
      wonderType: command.wonderType,
      investedProduction: activeInvestment ?? rolloverInvestment,
    ),
    productionOverflow: activeInvestment == null
        ? 0
        : beforeCity.productionOverflow,
  );
  final expectedCities = [...before.cities]..[cityIndex] = expectedCity;
  final expectedState = before.copyWith(cities: expectedCities);
  if (after != expectedState) {
    throw FormatException(
      '$fixtureId must only replace the target city queue while preserving '
      'pace-scaled overflow, active investment, city order, registry, runtime, '
      'sentinels, and every unrelated state slice.',
    );
  }
}
