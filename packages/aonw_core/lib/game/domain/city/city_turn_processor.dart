import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city/city_economy_breakdown.dart';
import 'package:aonw_core/game/domain/city/city_expansion_selector.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_project_rules.dart';
import 'package:aonw_core/game/domain/city/city_project_type.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/city_turn_result.dart';
import 'package:aonw_core/game/domain/city/city_unit_production_rules.dart';
import 'package:aonw_core/game/domain/city/city_yield_calculator.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class CityTurnProcessor {
  static CityTurnBatchResult advanceForPlayer({
    required String playerId,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required MapData mapData,
    List<GameUnit> units = const [],
    List<WorldArtifact> artifacts = const [],
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
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
        technologyEffects: technologyEffects,
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
    required MapData mapData,
    required CityRuleset ruleset,
    required PaceBalance paceBalance,
    required TechnologyEffectSummary technologyEffects,
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
      mapData: mapData,
      ruleset: ruleset,
      paceBalance: paceBalance,
      technologyEffects: technologyEffects,
    );
    final goldGained = economy.netYield.gold < 0 ? 0 : economy.netYield.gold;
    var projectGoldGained = 0;
    var projectScienceGained = ScienceYieldBreakdown.empty;
    final artifactScienceGained = _artifactScienceFor(city, artifacts);

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
    nextCity = _applyPopulationTier(nextCity, ruleset);
    if (grew) {
      final expanded = _expandTerritoryAfterGrowth(
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

    // Production queue advancement
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
                      label: 'City research project',
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
      scienceGained: _combineScience(
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
    required MapData mapData,
    required CityRuleset ruleset,
    required PaceBalance paceBalance,
    required List<CityTurnEvent> events,
    required void Function(List<GameUnit> units) updateUnits,
    required int artifactExperience,
  }) {
    final advanced = queue.isCompleteFor(ruleset, paceBalance: paceBalance)
        ? queue
        : queue.advancedBy(productionPerTurn);
    if (advanced.isCompleteFor(ruleset, paceBalance: paceBalance)) {
      final targetCost = CityProductionRules.targetCost(
        advanced.target,
        ruleset: ruleset,
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
            mapData: mapData,
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
      }
    }
    return nextCity.copyWith(productionQueue: advanced);
  }

  static ScienceYieldBreakdown _artifactScienceFor(
    GameCity city,
    Iterable<WorldArtifact> artifacts,
  ) {
    final amount = WorldArtifactBonuses.cityScienceFor(
      cityId: city.id,
      artifacts: artifacts,
    );
    if (amount <= 0) return ScienceYieldBreakdown.empty;
    return ScienceYieldBreakdown(
      total: amount,
      byCityId: {city.id: amount},
      sources: [
        ScienceYieldSource(
          cityId: city.id,
          amount: amount,
          label: 'World artifact',
        ),
      ],
    );
  }

  static ScienceYieldBreakdown _combineScience(
    ScienceYieldBreakdown left,
    ScienceYieldBreakdown right,
  ) {
    if (left.total <= 0) return right;
    if (right.total <= 0) return left;
    final byCityId = <String, int>{...left.byCityId};
    for (final entry in right.byCityId.entries) {
      byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
    }
    return ScienceYieldBreakdown(
      total: left.total + right.total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable([...left.sources, ...right.sources]),
    );
  }

  static ({GameCity city, CityHex? hex}) _expandTerritoryAfterGrowth({
    required GameCity city,
    required List<GameCity> cities,
    required MapData mapData,
    required CityRuleset ruleset,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final citiesWithCurrentCity = _replaceCity(cities, city);
    final hex = CityExpansionSelector.preferredOrBestHex(
      city: city,
      mapData: mapData,
      cities: citiesWithCurrentCity,
      allowCoast: true,
      allowOcean: true,
      ruleset: ruleset,
      technologyEffects: technologyEffects,
    );
    if (hex == null) return (city: city, hex: null);
    return (
      city: city.copyWith(
        controlledHexes: [...city.controlledHexes, hex],
        preferredExpansionHex: null,
      ),
      hex: hex,
    );
  }

  static List<GameCity> _replaceCity(List<GameCity> cities, GameCity city) {
    return [
      for (final existing in cities)
        if (existing.id == city.id) city else existing,
    ];
  }

  static GameCity _applyPopulationTier(GameCity city, CityRuleset ruleset) {
    final progression = ruleset.progression;
    var maxHexes = city.maxHexes;
    var territoryRadius = city.territoryRadius;

    if (city.population >= 10) {
      if (maxHexes < progression.lateGameMaxHexes) {
        maxHexes = progression.lateGameMaxHexes;
      }
      if (territoryRadius < progression.expandedTerritoryRadius) {
        territoryRadius = progression.expandedTerritoryRadius;
      }
    } else if (city.population >= 6) {
      if (maxHexes < progression.midGameMaxHexes) {
        maxHexes = progression.midGameMaxHexes;
      }
    }

    if (maxHexes == city.maxHexes && territoryRadius == city.territoryRadius) {
      return city;
    }
    return city.copyWith(maxHexes: maxHexes, territoryRadius: territoryRadius);
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
