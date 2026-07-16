part of 'city_production_reducer.dart';

GameStateTransition _rushCityProduction(
  GameState state,
  RushProductionCommand command,
  MapTileLookup mapTiles, {
  required GameCommandContext context,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required StabilityRuleset stabilityRuleset,
  required WonderRuleset wonderRuleset,
}) {
  final target = CityProductionReducer._controlledCityTarget(
    state,
    command.cityId,
    context,
  );
  if (target == null) return GameStateTransition(state: state);
  final city = target.city;

  final queue = city.productionQueue;
  if (queue == null) return GameStateTransition(state: state);
  if (!CityProductionRules.canRush(queue.target)) {
    return GameStateTransition(state: state);
  }

  final productionPerTurn = _productionPerTurnForTarget(
    state: state,
    city: city,
    mapTiles: mapTiles,
    target: queue.target,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    stabilityRuleset: stabilityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: context.paceBalance,
  );

  final targetCost = CityProductionRules.targetCost(
    queue.target,
    ruleset: cityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: context.paceBalance,
  );
  final rushedProduction = CityProductionRules.rushProductionAmount(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: productionPerTurn,
  );
  final rushCost = CityProductionRules.rushGoldCost(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: productionPerTurn,
  );
  final currentGold = state.playerGold[city.ownerPlayerId] ?? 0;
  if (rushedProduction <= 0 || rushCost <= 0 || currentGold < rushCost) {
    return GameStateTransition(state: state);
  }

  final advanced = queue.advancedBy(rushedProduction);
  final updatedGold = {
    ...state.playerGold,
    city.ownerPlayerId: currentGold - rushCost,
  };
  final applied = _applyRushedProduction(
    city: city,
    units: state.units,
    advancedQueue: advanced,
    targetCost: targetCost,
    mapTiles: mapTiles,
    cityRuleset: cityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: context.paceBalance,
  );

  var updatedCities = CityProductionReducer._replaceCityAt(
    state.cities,
    index: target.index,
    city: applied.city,
  );
  var nextGold = updatedGold;
  var nextResearch = state.research;
  var nextWonderRegistry = state.wonderRegistry;
  var events = applied.events;
  if (advanced.isCompleteFor(
        cityRuleset,
        wonderRuleset: wonderRuleset,
        paceBalance: context.paceBalance,
      ) &&
      advanced.target is WonderProductionTarget) {
    final completion = WonderCompletionResolver.resolveCompletedForPlayer(
      playerId: city.ownerPlayerId,
      cities: updatedCities,
      registry: state.wonderRegistry,
      playerGold: updatedGold,
      research: state.research,
      ruleset: wonderRuleset,
      paceBalance: context.paceBalance,
    );
    updatedCities = completion.cities;
    nextGold = completion.playerGold;
    nextResearch = completion.research;
    nextWonderRegistry = completion.registry;
    events = [...events, ...completion.events];
  }
  final refreshedCity = updatedCities.firstWhere(
    (candidate) => candidate.id == command.cityId,
    orElse: () => applied.city,
  );
  var next = state.copyWith(
    cities: updatedCities,
    units: applied.units,
    playerGold: nextGold,
    research: nextResearch,
    wonderRegistry: nextWonderRegistry,
  );

  next = CityProductionReducer._refreshCitySelectionIfSelected(
    next,
    cityId: command.cityId,
    city: refreshedCity,
    mapTiles: mapTiles,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    stabilityRuleset: stabilityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: context.paceBalance,
  );

  return GameStateTransition(state: next, events: events);
}

int _productionPerTurnForTarget({
  required GameState state,
  required GameCity city,
  required MapTileLookup mapTiles,
  required CityProductionTarget target,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required StabilityRuleset stabilityRuleset,
  required WonderRuleset wonderRuleset,
  required PaceBalance paceBalance,
}) {
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: city.ownerPlayerId,
    research: state.research,
    ruleset: technologyRuleset,
  );
  final cityYield = CityYieldCalculator.totalFor(
    city,
    mapTiles,
    fieldImprovements: state.fieldImprovements,
    units: state.units,
    artifacts: state.artifacts,
    ruleset: cityRuleset,
  );
  final cityEconomy = CityEconomyBreakdown.from(
    city: city,
    tileYield: cityYield,
    mapTiles: mapTiles,
    ruleset: cityRuleset,
    paceBalance: paceBalance,
    technologyEffects: technologyEffects,
    cities: state.cities,
    wonderRegistry: state.wonderRegistry,
    wonderRuleset: wonderRuleset,
    stabilityModifier: StabilityPolicy.modifierForNet(
      state.playerStabilityNet[city.ownerPlayerId] ?? 0,
      ruleset: stabilityRuleset,
    ),
  );
  var productionPerTurn = CityProductionRules.productionPerTurn(
    cityEconomy.netYield.production,
  );
  if (target is UnitProductionTarget) {
    productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
      productionPerTurn,
      effects: technologyEffects,
    );
  }
  return CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: productionPerTurn,
    target: target,
    specialization: city.specialization,
  );
}

_RushProductionApplication _applyRushedProduction({
  required GameCity city,
  required List<GameUnit> units,
  required CityProductionQueue advancedQueue,
  required int targetCost,
  required MapTileLookup mapTiles,
  required CityRuleset cityRuleset,
  required WonderRuleset wonderRuleset,
  required PaceBalance paceBalance,
}) {
  var updatedCity = city.copyWith(productionQueue: advancedQueue);
  var updatedUnits = units;
  final events = <GameEvent>[];

  if (!advancedQueue.isCompleteFor(
    cityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
  )) {
    return (city: updatedCity, units: updatedUnits, events: events);
  }

  final productionOverflow = CityProductionRules.completionOverflow(
    productionCost: targetCost,
    investedProduction: advancedQueue.investedProduction,
  );
  switch (advancedQueue.target) {
    case BuildingProductionTarget(:final buildingType):
      updatedCity = updatedCity.copyWith(
        buildings: {...updatedCity.buildings, buildingType},
        productionQueue: null,
        productionOverflow: productionOverflow,
      );
      events.add(
        CityBuiltBuildingEvent(
          cityId: updatedCity.id,
          buildingType: buildingType,
        ),
      );
    case UnitProductionTarget(:final unitType):
      final producedUnit = CityUnitProductionRules.produce(
        city: updatedCity,
        unitType: unitType,
        units: updatedUnits,
        mapTiles: mapTiles,
      );
      if (producedUnit != null) {
        updatedUnits = [...updatedUnits, producedUnit];
        updatedCity = updatedCity.copyWith(
          productionQueue: null,
          productionOverflow: productionOverflow,
        );
        events.add(
          CityProducedUnitEvent(
            cityId: updatedCity.id,
            unitType: unitType,
            producedUnitId: producedUnit.id,
          ),
        );
      }
    case ProjectProductionTarget():
      break;
    case WonderProductionTarget():
      break;
  }

  return (city: updatedCity, units: updatedUnits, events: events);
}
