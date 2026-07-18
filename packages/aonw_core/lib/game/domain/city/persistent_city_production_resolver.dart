import 'package:aonw_core/game/domain/city/city_economy_breakdown.dart';
import 'package:aonw_core/game/domain/city/city_production_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/city_unit_production_rules.dart';
import 'package:aonw_core/game/domain/city/city_unit_supply_rules.dart';
import 'package:aonw_core/game/domain/city/city_yield_calculator.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_availability_policy.dart';
import 'package:aonw_core/game/domain/wonder/wonder_completion_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'persistent_city_production_supply.dart';
part 'persistent_city_production_rush.dart';

class PersistentCityProductionResult {
  const PersistentCityProductionResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

class PersistentCityProductionResolver {
  const PersistentCityProductionResolver();

  PersistentCityProductionResult startBuilding({
    required PersistentGameState state,
    required StartBuildingCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startBuilding(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return _fromCommandResult(state, result);
  }

  PersistentCityProductionResult startUnitProduction({
    required PersistentGameState state,
    required StartUnitProductionCommand command,
    required String actorPlayerId,
    required MapReadView mapView,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityLookup(state.cities, command.cityId);
    if (lookup == null) return _reject(state, 'city_not_found');
    final (:cityIndex, :city) = lookup;
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }

    final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      research: state.research,
      ruleset: technologyRuleset,
    );
    if (!CityProductionRules.canProduceUnit(
      command.unitType,
      ruleset: cityRuleset,
      technologyUnlocked: technologyUnlocked,
    )) {
      return _reject(state, 'unit_production_not_available');
    }
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      mapTiles: mapView.mapTiles,
      ruleset: cityRuleset,
      research: state.research,
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
    );
    if (!requirementsMet) {
      return _reject(state, 'unit_production_requires_resource');
    }
    if (!CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: command.unitType,
      mapTiles: mapView.mapTiles,
    )) {
      return _reject(state, 'unit_production_requires_coast');
    }
    final hasSupply = _canQueuePersistentCityUnit(
      state: state,
      city: city,
      unitType: command.unitType,
      mapView: mapView,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
    if (!hasSupply) {
      return _reject(state, 'unit_supply_limit_reached');
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCity(
          state.cities,
          cityIndex,
          _queueProduction(
            city,
            UnitProductionTarget(command.unitType),
            cityRuleset,
            paceBalance,
          ),
        ),
      ),
    );
  }

  PersistentCityProductionResult startCityProject({
    required PersistentGameState state,
    required StartCityProjectCommand command,
    required String actorPlayerId,
    CityRuleset cityRuleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startCityProject(
      cities: state.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
      paceBalance: paceBalance,
    );
    return _fromCommandResult(state, result);
  }

  PersistentCityProductionResult startWonder({
    required PersistentGameState state,
    required StartWonderCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityLookup(state.cities, command.cityId);
    if (lookup == null) return _reject(state, 'city_not_found');
    final (:cityIndex, :city) = lookup;
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }

    final availability = WonderAvailabilityPolicy.availabilityFor(
      city: city,
      cities: state.cities,
      mapTiles: mapTiles,
      research: state.research,
      registry: state.wonderRegistry,
      ruleset: wonderRuleset,
      wonderType: command.wonderType,
    );
    if (!availability.isAvailable) {
      return _reject(state, 'wonder_not_available');
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCity(
          state.cities,
          cityIndex,
          _queueProduction(
            city,
            WonderProductionTarget(command.wonderType),
            CityRulesets.standard,
            paceBalance,
            wonderRuleset: wonderRuleset,
          ),
        ),
      ),
    );
  }

  PersistentCityProductionResult setCitySpecialization({
    required PersistentGameState state,
    required SetCitySpecializationCommand command,
    required String actorPlayerId,
  }) {
    final result = CityProductionCommandResolver.setCitySpecialization(
      cities: state.cities,
      research: state.research,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _fromCommandResult(state, result);
  }

  PersistentCityProductionResult rushProduction({
    required PersistentGameState state,
    required RushProductionCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityLookup(state.cities, command.cityId);
    if (lookup == null) return _reject(state, 'city_not_found');
    final (:cityIndex, :city) = lookup;
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }
    final queue = city.productionQueue;
    if (queue == null) return _reject(state, 'production_queue_empty');
    if (!CityProductionRules.canRush(queue.target)) {
      return _reject(state, 'project_cannot_be_rushed');
    }

    final productionPerTurn = _rushProductionPerTurn(
      state: state,
      city: city,
      target: queue.target,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    );

    final targetCost = CityProductionRules.targetCost(
      queue.target,
      ruleset: cityRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
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
      return _reject(state, 'rush_production_unavailable');
    }

    final advanced = queue.advancedBy(rushedProduction);
    var updatedGold = {
      ...state.playerGold,
      city.ownerPlayerId: currentGold - rushCost,
    };
    final events = <GameEvent>[];
    var updatedCity = city.copyWith(productionQueue: advanced);
    var updatedCities = state.cities;
    var updatedResearch = state.research;
    var updatedWonderRegistry = state.wonderRegistry;
    var updatedUnits = state.units;
    var resolvedWonderCompletion = false;

    if (advanced.isCompleteFor(
      cityRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    )) {
      final productionOverflow = CityProductionRules.completionOverflow(
        productionCost: targetCost,
        investedProduction: advanced.investedProduction,
      );
      switch (advanced.target) {
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
          final completion = WonderCompletionResolver.resolveCompletedForPlayer(
            playerId: actorPlayerId,
            cities: _replaceCity(state.cities, cityIndex, updatedCity),
            registry: updatedWonderRegistry,
            playerGold: updatedGold,
            research: updatedResearch,
            ruleset: wonderRuleset,
            paceBalance: paceBalance,
          );
          updatedCities = completion.cities;
          updatedGold = completion.playerGold;
          updatedResearch = completion.research;
          updatedWonderRegistry = completion.registry;
          events.addAll(completion.events);
          resolvedWonderCompletion = true;
      }
    }
    if (!resolvedWonderCompletion) {
      updatedCities = _replaceCity(state.cities, cityIndex, updatedCity);
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: updatedCities,
        units: updatedUnits,
        playerGold: updatedGold,
        research: updatedResearch,
        wonderRegistry: updatedWonderRegistry,
      ),
      events: events,
    );
  }

  PersistentCityProductionResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentCityProductionResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  PersistentCityProductionResult _fromCommandResult(
    PersistentGameState state,
    CityProductionCommandResult result,
  ) {
    if (!result.accepted) return _reject(state, result.reason!);
    return PersistentCityProductionResult(
      accepted: true,
      state: identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
    );
  }

  static GameCity _queueProduction(
    GameCity city,
    CityProductionTarget target,
    CityRuleset cityRuleset,
    PaceBalance paceBalance, {
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: CityProductionRules.targetCost(
              target,
              ruleset: cityRuleset,
              wonderRuleset: wonderRuleset,
              paceBalance: paceBalance,
            ),
          )
        : 0;
    return city.copyWith(
      productionQueue: CityProductionQueue.target(
        target: target,
        investedProduction: activeInvestment ?? rolloverInvestment,
      ),
      productionOverflow: activeInvestment == null
          ? 0
          : city.productionOverflow,
    );
  }

  static ({int cityIndex, GameCity city})? _cityLookup(
    List<GameCity> cities,
    String cityId,
  ) {
    for (var i = 0; i < cities.length; i++) {
      final city = cities[i];
      if (city.id == cityId) return (cityIndex: i, city: city);
    }
    return null;
  }

  static List<GameCity> _replaceCity(
    List<GameCity> cities,
    int index,
    GameCity updated,
  ) {
    return [
      for (var i = 0; i < cities.length; i++)
        if (i == index) updated else cities[i],
    ];
  }
}
