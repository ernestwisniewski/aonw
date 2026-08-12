import 'package:aonw_core/game/domain/city/city_resource_inventory.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitProductionRequirementRules {
  static bool meetsRequirements({
    required String playerId,
    required GameUnitType unitType,
    required Iterable<GameCity> cities,
    required MapTileLookup mapTiles,
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
    bool ignoreStockpileCosts = false,
  }) {
    return missingResourceChoices(
      playerId: playerId,
      unitType: unitType,
      cities: cities,
      mapTiles: mapTiles,
      ruleset: ruleset,
      research: research,
      resourceTradeAgreements: resourceTradeAgreements,
      ignoreStockpileCosts: ignoreStockpileCosts,
    ).isEmpty;
  }

  static Set<ResourceType> missingResourceChoices({
    required String playerId,
    required GameUnitType unitType,
    required Iterable<GameCity> cities,
    required MapTileLookup mapTiles,
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
    bool ignoreStockpileCosts = false,
  }) {
    final network = EmpireResourceNetworkRules.forPlayer(
      playerId: playerId,
      cities: cities,
      mapTiles: mapTiles,
      ruleset: ruleset,
      research: research,
      resourceTradeAgreements: resourceTradeAgreements,
    );
    final definition = ruleset.unitDefinitionFor(unitType);
    for (final requirement in definition.requirements) {
      switch (requirement) {
        case UnitResourceRequirement(:final resources):
          if (!resources.any(network.controlsVisible)) return resources;
        case UnitStockpileCostRequirement(:final options):
          if (ignoreStockpileCosts) continue;
          final resources = {
            for (final option in options) ...option.amounts.keys,
          };
          if (!resources.any(network.controlsVisible)) return resources;
      }
    }
    return const {};
  }
}
