import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city/city_economy_breakdown.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_project_rules.dart';
import 'package:aonw_core/game/domain/city/city_project_type.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/city_turn_growth_rules.dart';
import 'package:aonw_core/game/domain/city/city_turn_result.dart';
import 'package:aonw_core/game/domain/city/city_turn_science.dart';
import 'package:aonw_core/game/domain/city/city_unit_production_rules.dart';
import 'package:aonw_core/game/domain/city/city_yield_calculator.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability/stability_modifier.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class CityTurnProcessor {
  static CityTurnBatchResult advanceForPlayer({
    required String playerId,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required MapTileLookup mapData,
    List<GameUnit> units = const [],
    List<WorldArtifact> artifacts = const [],
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    WonderRegistry wonderRegistry = WonderRegistry.empty,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    StabilityModifier stabilityModifier = StabilityModifier.stable,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final updatedCities = List<GameCity>.of(cities);
    var updatedImprovements = List<FieldImprovement>.of(fieldImprovements);
    var updatedUnits = List<GameUnit>.of(units);
    final events = <CityTurnEvent>[];
    final scienceSources = <ScienceYieldSource>[];
    final scienceByCityId = <String, int>{};
    var goldGained = 0;
    var scienceGained = 0;
    var hasStateChanges = false;
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: research,
      ruleset: technologyRuleset,
    );

    for (var i = 0; i < updatedCities.length; i++) {
      final city = updatedCities[i];
      if (city.ownerPlayerId != playerId) continue;
      hasStateChanges = true;

      final result = _advanceCity(
        city: city,
        cities: updatedCities,
        fieldImprovements: updatedImprovements,
        units: updatedUnits,
        mapData: mapData,
        ruleset: ruleset,
        paceBalance: paceBalance,
        wonderRegistry: wonderRegistry,
        wonderRuleset: wonderRuleset,
        technologyEffects: technologyEffects,
        stabilityModifier: stabilityModifier,
        artifacts: artifacts,
      );
      updatedCities[i] = result.city;
      updatedImprovements = result.fieldImprovements;
      updatedUnits = result.units;
      events.addAll(result.events);
      goldGained += result.goldGained;
      scienceGained += result.scienceGained.total;
      scienceSources.addAll(result.scienceGained.sources);
      for (final entry in result.scienceGained.byCityId.entries) {
        scienceByCityId[entry.key] =
            (scienceByCityId[entry.key] ?? 0) + entry.value;
      }
    }

    return CityTurnBatchResult(
      cities: List.unmodifiable(updatedCities),
      fieldImprovements: List.unmodifiable(updatedImprovements),
      units: List.unmodifiable(updatedUnits),
      events: List.unmodifiable(events),
      goldGained: goldGained,
      scienceGained: scienceGained <= 0
          ? ScienceYieldBreakdown.empty
          : ScienceYieldBreakdown(
              total: scienceGained,
              byCityId: Map.unmodifiable(scienceByCityId),
              sources: List.unmodifiable(scienceSources),
            ),
      hasStateChanges: hasStateChanges,
    );
  }

  static _SingleCityTurnResult _advanceCity({
    required GameCity city,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required List<GameUnit> units,
    required MapTileLookup mapData,
    required CityRuleset ruleset,
    required PaceBalance paceBalance,
    required WonderRegistry wonderRegistry,
    required WonderRuleset wonderRuleset,
    required TechnologyEffectSummary technologyEffects,
    required StabilityModifier stabilityModifier,
    required List<WorldArtifact> artifacts,
  }) {
    final events = <CityTurnEvent>[];
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: fieldImprovements,
      units: units,
      artifacts: artifacts,
      ruleset: ruleset,
    );
    final economy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapTiles: mapData,
      ruleset: ruleset,
      paceBalance: paceBalance,
      technologyEffects: technologyEffects,
      stabilityModifier: stabilityModifier,
      cities: cities,
      wonderRegistry: wonderRegistry,
      wonderRuleset: wonderRuleset,
    );
    final goldGained = economy.netYield.gold < 0 ? 0 : economy.netYield.gold;
    var projectGoldGained = 0;
    var projectScienceGained = ScienceYieldBreakdown.empty;
    final artifactScienceGained = CityTurnScience.artifactFor(city, artifacts);

    var nextCity = city.copyWith(storedFood: economy.storedFoodAfterTurn);

    var grew = false;
    if (nextCity.storedFood >= economy.growthCost) {
      nextCity = nextCity.copyWith(
        population: nextCity.population + 1,
        storedFood: nextCity.storedFood - economy.growthCost,
      );
      grew = true;
      events.add(CityTurnEvent(type: CityTurnEventType.grew, cityId: city.id));
    }
    nextCity = CityTurnGrowthRules.applyPopulationTier(nextCity, ruleset);
    if (grew) {
      final expanded = CityTurnGrowthRules.expandTerritoryAfterGrowth(
        city: nextCity,
        cities: cities,
        mapData: mapData,
        ruleset: ruleset,
        technologyEffects: technologyEffects,
      );
      if (expanded.hex != null) {
        nextCity = expanded.city;
        events.add(
          CityTurnEvent(
            type: CityTurnEventType.claimedHex,
            cityId: city.id,
            hex: expanded.hex,
          ),
        );
      }
    }

    final queue = nextCity.productionQueue;
    if (queue != null) {
      var productionPerTurn = CityProductionRules.productionPerTurn(
        economy.netYield.production,
      );
      switch (queue.target) {
        case ProjectProductionTarget(:final projectType):
          productionPerTurn =
              CitySpecializationRules.productionPerTurnForTarget(
                productionPerTurn: productionPerTurn,
                target: queue.target,
                specialization: nextCity.specialization,
              );
          final output = CityProjectRules.outputFor(
            type: projectType,
            productionPerTurn: productionPerTurn,
          );
          switch (projectType) {
            case CityProjectType.wealth:
              projectGoldGained += output;
            case CityProjectType.research:
              if (output > 0) {
                projectScienceGained = ScienceYieldBreakdown(
                  total: output,
                  byCityId: {city.id: output},
                  sources: [
                    ScienceYieldSource(
                      cityId: city.id,
                      amount: output,
                      label: ScienceYieldSourceLabels.cityResearchProject,
                    ),
                  ],
                );
              }
          }
        case UnitProductionTarget():
          productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
            productionPerTurn,
            effects: technologyEffects,
          );
          productionPerTurn =
              CitySpecializationRules.productionPerTurnForTarget(
                productionPerTurn: productionPerTurn,
                target: queue.target,
                specialization: nextCity.specialization,
              );
          nextCity = _advanceFiniteProduction(
            city: city,
            nextCity: nextCity,
            queue: queue,
            productionPerTurn: productionPerTurn,
            units: units,
            mapData: mapData,
            ruleset: ruleset,
            wonderRuleset: wonderRuleset,
            paceBalance: paceBalance,
            events: events,
            updateUnits: (updated) => units = updated,
            artifactExperience: WorldArtifactBonuses.producedUnitExperienceFor(
              cityId: nextCity.id,
              artifacts: artifacts,
            ),
          );
        case BuildingProductionTarget():
          productionPerTurn =
              CitySpecializationRules.productionPerTurnForTarget(
                productionPerTurn: productionPerTurn,
                target: queue.target,
                specialization: nextCity.specialization,
              );
          nextCity = _advanceFiniteProduction(
            city: city,
            nextCity: nextCity,
            queue: queue,
            productionPerTurn: productionPerTurn,
            units: units,
            mapData: mapData,
            ruleset: ruleset,
            wonderRuleset: wonderRuleset,
            paceBalance: paceBalance,
            events: events,
            updateUnits: (updated) => units = updated,
            artifactExperience: 0,
          );
        case WonderProductionTarget():
          productionPerTurn =
              CitySpecializationRules.productionPerTurnForTarget(
                productionPerTurn: productionPerTurn,
                target: queue.target,
                specialization: nextCity.specialization,
              );
          nextCity = _advanceFiniteProduction(
            city: city,
            nextCity: nextCity,
            queue: queue,
            productionPerTurn: productionPerTurn,
            units: units,
            mapData: mapData,
            ruleset: ruleset,
            wonderRuleset: wonderRuleset,
            paceBalance: paceBalance,
            events: events,
            updateUnits: (updated) => units = updated,
            artifactExperience: 0,
          );
      }
    }

    return _SingleCityTurnResult(
      city: nextCity,
      fieldImprovements: List.unmodifiable(fieldImprovements),
      units: List.unmodifiable(units),
      events: List.unmodifiable(events),
      goldGained: goldGained + projectGoldGained,
      scienceGained: CityTurnScience.combine(
        projectScienceGained,
        artifactScienceGained,
      ),
    );
  }

  static GameCity _advanceFiniteProduction({
    required GameCity city,
    required GameCity nextCity,
    required CityProductionQueue queue,
    required int productionPerTurn,
    required List<GameUnit> units,
    required MapTileLookup mapData,
    required CityRuleset ruleset,
    required WonderRuleset wonderRuleset,
    required PaceBalance paceBalance,
    required List<CityTurnEvent> events,
    required void Function(List<GameUnit> units) updateUnits,
    required int artifactExperience,
  }) {
    final advanced =
        queue.isCompleteFor(
          ruleset,
          wonderRuleset: wonderRuleset,
          paceBalance: paceBalance,
        )
        ? queue
        : queue.advancedBy(productionPerTurn);
    if (advanced.isCompleteFor(
      ruleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    )) {
      final targetCost = CityProductionRules.targetCost(
        advanced.target,
        ruleset: ruleset,
        wonderRuleset: wonderRuleset,
        paceBalance: paceBalance,
      );
      final productionOverflow = CityProductionRules.completionOverflow(
        productionCost: targetCost,
        investedProduction: advanced.investedProduction,
      );
      switch (advanced.target) {
        case BuildingProductionTarget(:final buildingType):
          events.add(
            CityTurnEvent(
              type: CityTurnEventType.builtBuilding,
              cityId: city.id,
            ),
          );
          return nextCity.copyWith(
            buildings: {...nextCity.buildings, buildingType},
            productionQueue: null,
            productionOverflow: productionOverflow,
          );
        case UnitProductionTarget(:final unitType):
          final producedUnit = CityUnitProductionRules.produce(
            city: nextCity,
            unitType: unitType,
            units: units,
            mapTiles: mapData,
          );
          if (producedUnit != null) {
            final unitWithArtifactExperience = UnitVeterancyRules.addExperience(
              producedUnit,
              artifactExperience,
            );
            final updatedUnits = [...units, unitWithArtifactExperience];
            updateUnits(updatedUnits);
            events.add(
              CityTurnEvent(
                type: CityTurnEventType.producedUnit,
                cityId: city.id,
                producedUnit: unitWithArtifactExperience,
              ),
            );
            return nextCity.copyWith(
              productionQueue: null,
              productionOverflow: productionOverflow,
            );
          } else {
            return nextCity.copyWith(productionQueue: advanced);
          }
        case ProjectProductionTarget():
          return nextCity;
        case WonderProductionTarget():
          return nextCity.copyWith(productionQueue: advanced);
      }
    }
    return nextCity.copyWith(productionQueue: advanced);
  }
}

class _SingleCityTurnResult {
  final GameCity city;
  final List<FieldImprovement> fieldImprovements;
  final List<GameUnit> units;
  final List<CityTurnEvent> events;
  final int goldGained;
  final ScienceYieldBreakdown scienceGained;

  const _SingleCityTurnResult({
    required this.city,
    required this.fieldImprovements,
    required this.units,
    required this.events,
    required this.goldGained,
    this.scienceGained = ScienceYieldBreakdown.empty,
  });
}
