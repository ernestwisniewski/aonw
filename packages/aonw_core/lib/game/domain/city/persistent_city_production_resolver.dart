import 'package:aonw_core/game/domain/city/city_building_requirement_rules.dart';
import 'package:aonw_core/game/domain/city/city_economy_breakdown.dart';
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
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_availability_policy.dart';
import 'package:aonw_core/game/domain/wonder/wonder_completion_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'persistent_city_production_supply.dart';

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
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityLookup(state.cities, command.cityId);
    if (lookup == null) return _reject(state, 'city_not_found');
    final (:cityIndex, :city) = lookup;
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }

    final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: city.ownerPlayerId,
      buildingType: command.buildingType,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: command.buildingType,
      mapTiles: mapTiles,
      ruleset: cityRuleset,
      research: state.research,
    );
    if (!CityProductionRules.canBuild(
      city.buildings,
      command.buildingType,
      ruleset: cityRuleset,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return _reject(state, 'building_not_available');
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCity(
          state.cities,
          cityIndex,
          _queueProduction(
            city,
            BuildingProductionTarget(command.buildingType),
            cityRuleset,
            paceBalance,
          ),
        ),
      ),
    );
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
    final lookup = _cityLookup(state.cities, command.cityId);
    if (lookup == null) return _reject(state, 'city_not_found');
    final (:cityIndex, :city) = lookup;
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCity(
          state.cities,
          cityIndex,
          _queueProduction(
            city,
            ProjectProductionTarget(command.projectType),
            cityRuleset,
            paceBalance,
          ),
        ),
      ),
    );
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
    final lookup = _cityLookup(state.cities, command.cityId);
    if (lookup == null) return _reject(state, 'city_not_found');
    final (:cityIndex, :city) = lookup;
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }
    if (!state.research
        .forPlayer(city.ownerPlayerId)
        .hasUnlocked(TechnologyId.specialization)) {
      return _reject(state, 'city_specialization_locked');
    }
    if (city.specialization == command.specialization) {
      return _reject(state, 'city_specialization_unchanged');
    }
    if (!CitySpecializationRules.hasRequiredBuilding(
      city.buildings,
      command.specialization,
    )) {
      return _reject(state, 'city_specialization_missing_building');
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCity(
          state.cities,
          cityIndex,
          city.copyWith(specialization: command.specialization),
        ),
      ),
    );
  }

  PersistentCityProductionResult rushProduction({
    required PersistentGameState state,
    required RushProductionCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
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
      technologyEffects: technologyEffects,
      paceBalance: paceBalance,
      cities: state.cities,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: wonderRuleset,
    );
    var productionPerTurn = CityProductionRules.productionPerTurn(
      cityEconomy.netYield.production,
    );
    if (queue.target is UnitProductionTarget) {
      productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
        productionPerTurn,
        effects: technologyEffects,
      );
    }
    productionPerTurn = CitySpecializationRules.productionPerTurnForTarget(
      productionPerTurn: productionPerTurn,
      target: queue.target,
      specialization: city.specialization,
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
