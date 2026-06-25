import 'package:aonw_core/game/domain/city/city_resource_inventory.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitProductionRequirementRules {
  static bool meetsRequirements({
    required String playerId,
    required GameUnitType unitType,
    required Iterable<GameCity> cities,
    required MapData mapData,
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
  }) {
    return missingResourceChoices(
      playerId: playerId,
      unitType: unitType,
      cities: cities,
      mapData: mapData,
      ruleset: ruleset,
      research: research,
      resourceTradeAgreements: resourceTradeAgreements,
    ).isEmpty;
  }

  static Set<ResourceType> missingResourceChoices({
    required String playerId,
    required GameUnitType unitType,
    required Iterable<GameCity> cities,
    required MapData mapData,
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
  }) {
    final network = EmpireResourceNetworkRules.forPlayer(
      playerId: playerId,
      cities: cities,
      mapData: mapData,
      ruleset: ruleset,
      research: research,
      resourceTradeAgreements: resourceTradeAgreements,
    );
    final definition = ruleset.unitDefinitionFor(unitType);
    for (final requirement in definition.requirements) {
      switch (requirement) {
        case UnitResourceRequirement(:final resources):
          if (!resources.any(network.controlsVisible)) return resources;
      }
    }
    return const {};
  }
}
