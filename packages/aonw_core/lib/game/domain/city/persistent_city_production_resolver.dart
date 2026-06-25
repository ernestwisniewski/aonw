import 'package:aonw_core/domain/map_definition.dart';
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
import 'package:aonw_core/map/domain/map_data.dart';

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
    required MapDefinition mapDefinition,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityById(state.cities, command.cityId);
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
      mapData: _mapDataFromDefinition(mapDefinition),
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
    required MapDefinition mapDefinition,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityById(state.cities, command.cityId);
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
    final mapData = _mapDataFromDefinition(mapDefinition);
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      mapData: mapData,
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
      mapData: mapData,
    )) {
      return _reject(state, 'unit_production_requires_coast');
    }
    final hasSupply = CityUnitSupplyRules.canQueueUnit(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      units: state.units,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
      cityRuleset: cityRuleset,
      research: state.research,
      technologyRuleset: technologyRuleset,
      replacingCityId: city.id,
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
    final lookup = _cityById(state.cities, command.cityId);
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

  PersistentCityProductionResult setCitySpecialization({
    required PersistentGameState state,
    required SetCitySpecializationCommand command,
    required String actorPlayerId,
  }) {
    final lookup = _cityById(state.cities, command.cityId);
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
    required MapDefinition mapDefinition,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final lookup = _cityById(state.cities, command.cityId);
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

    final mapData = _mapDataFromDefinition(mapDefinition);
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      ruleset: cityRuleset,
    );
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
      paceBalance: paceBalance,
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
    final updatedGold = {
      ...state.playerGold,
      city.ownerPlayerId: currentGold - rushCost,
    };
    final events = <GameEvent>[];
    var updatedCity = city.copyWith(productionQueue: advanced);
    var updatedUnits = state.units;

    if (advanced.isCompleteFor(cityRuleset, paceBalance: paceBalance)) {
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
            mapData: mapData,
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
      }
    }

    return PersistentCityProductionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCity(state.cities, cityIndex, updatedCity),
        units: updatedUnits,
        playerGold: updatedGold,
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
    PaceBalance paceBalance,
  ) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: CityProductionRules.targetCost(
              target,
              ruleset: cityRuleset,
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

  static MapData _mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static ({int cityIndex, GameCity city})? _cityById(
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
