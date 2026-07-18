part of 'rush_production_command_resolver.dart';

final class _RushProductionCompletion {
  const _RushProductionCompletion({
    required this.input,
    required this.target,
    required this.quote,
  });

  final _RushProductionInput input;
  final _RushTarget target;
  final _RushQuote quote;

  RushProductionCommandResult resolve() {
    final advancedQueue = target.queue.advancedBy(quote.rushedProduction);
    final spentGold = Map<String, int>.unmodifiable({
      ...input.playerGold,
      target.city.ownerPlayerId: quote.currentGold - quote.rushCost,
    });
    final advancedCity = target.city.copyWith(productionQueue: advancedQueue);
    if (!advancedQueue.isCompleteFor(
      input.cityRuleset,
      wonderRuleset: input.wonderRuleset,
      paceBalance: input.paceBalance,
    )) {
      return _acceptCity(advancedCity, spentGold);
    }

    final overflow = CityProductionRules.completionOverflow(
      productionCost: quote.targetCost,
      investedProduction: advancedQueue.investedProduction,
    );
    return switch (advancedQueue.target) {
      BuildingProductionTarget(:final buildingType) => _completeBuilding(
        advancedCity,
        buildingType,
        overflow,
        spentGold,
      ),
      UnitProductionTarget(:final unitType) => _completeUnit(
        advancedCity,
        unitType,
        overflow,
        spentGold,
      ),
      WonderProductionTarget() => _completeWonder(advancedCity, spentGold),
      ProjectProductionTarget() => throw StateError(
        'A continuous city project cannot be rushed.',
      ),
    };
  }

  RushProductionCommandResult _completeBuilding(
    GameCity advancedCity,
    CityBuildingType buildingType,
    int overflow,
    Map<String, int> spentGold,
  ) {
    final completedCity = advancedCity.copyWith(
      buildings: {...advancedCity.buildings, buildingType},
      productionQueue: null,
      productionOverflow: overflow,
    );
    return _acceptCity(
      completedCity,
      spentGold,
      events: List<GameEvent>.unmodifiable([
        CityBuiltBuildingEvent(
          cityId: completedCity.id,
          buildingType: buildingType,
        ),
      ]),
    );
  }

  RushProductionCommandResult _completeUnit(
    GameCity advancedCity,
    GameUnitType unitType,
    int overflow,
    Map<String, int> spentGold,
  ) {
    final producedUnit = CityUnitProductionRules.produce(
      city: advancedCity,
      unitType: unitType,
      units: input.units,
      mapTiles: input.mapTiles,
    );
    if (producedUnit == null) {
      return _acceptCity(advancedCity, spentGold);
    }
    final completedCity = advancedCity.copyWith(
      productionQueue: null,
      productionOverflow: overflow,
    );
    return RushProductionCommandResult._accepted(
      cities: _replaceCity(completedCity),
      units: List<GameUnit>.unmodifiable([...input.units, producedUnit]),
      playerGold: spentGold,
      research: input.research,
      wonderRegistry: input.wonderRegistry,
      events: List<GameEvent>.unmodifiable([
        CityProducedUnitEvent(
          cityId: completedCity.id,
          unitType: unitType,
          producedUnitId: producedUnit.id,
        ),
      ]),
    );
  }

  RushProductionCommandResult _completeWonder(
    GameCity advancedCity,
    Map<String, int> spentGold,
  ) {
    final completion = WonderCompletionResolver.resolveCompletedForPlayer(
      playerId: target.city.ownerPlayerId,
      cities: _replaceCity(advancedCity),
      registry: input.wonderRegistry,
      playerGold: spentGold,
      research: input.research,
      ruleset: input.wonderRuleset,
      paceBalance: input.paceBalance,
    );
    return RushProductionCommandResult._accepted(
      cities: completion.cities,
      units: input.units,
      playerGold: completion.playerGold,
      research: completion.research,
      wonderRegistry: completion.registry,
      events: completion.events,
    );
  }

  RushProductionCommandResult _acceptCity(
    GameCity city,
    Map<String, int> spentGold, {
    List<GameEvent> events = const [],
  }) {
    return RushProductionCommandResult._accepted(
      cities: _replaceCity(city),
      units: input.units,
      playerGold: spentGold,
      research: input.research,
      wonderRegistry: input.wonderRegistry,
      events: events,
    );
  }

  List<GameCity> _replaceCity(GameCity city) {
    return List<GameCity>.unmodifiable([
      for (var index = 0; index < input.cities.length; index++)
        if (index == target.cityIndex) city else input.cities[index],
    ]);
  }
}
