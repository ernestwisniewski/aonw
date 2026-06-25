import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city/city_building_effect.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';

abstract final class ScienceYieldCalculator {
  static ScienceYieldBreakdown totalForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required ResearchState research,
    required TechnologyRuleset ruleset,
    Iterable<WorldArtifact> artifacts = const [],
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: research,
      ruleset: ruleset,
    );

    final byCityId = <String, int>{};
    final sources = <ScienceYieldSource>[];
    var total = 0;

    for (final city in cities) {
      if (city.ownerPlayerId != playerId) continue;

      final uncappedBaseAmount =
          ruleset.science.baseSciencePerCity +
          technologyEffects.cityScienceBonus +
          CitySpecializationRules.scienceFor(city.specialization) +
          _buildingScienceFor(city, ruleset.science, cityRuleset);
      final cap = ruleset.science.maxSciencePerCity;
      final baseAmount = cap <= 0 || uncappedBaseAmount < cap
          ? uncappedBaseAmount
          : cap;
      final artifactAmount = WorldArtifactBonuses.cityScienceFor(
        cityId: city.id,
        artifacts: artifacts,
      );
      final amount = baseAmount + artifactAmount;
      if (amount <= 0) continue;

      byCityId[city.id] = amount;
      if (baseAmount > 0) {
        sources.add(
          ScienceYieldSource(
            cityId: city.id,
            amount: baseAmount,
            label: 'City science',
          ),
        );
      }
      if (artifactAmount > 0) {
        sources.add(
          ScienceYieldSource(
            cityId: city.id,
            amount: artifactAmount,
            label: 'World artifact',
          ),
        );
      }
      total += amount;
    }

    if (total == 0) return ScienceYieldBreakdown.empty;
    return ScienceYieldBreakdown(
      total: total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable(sources),
    );
  }

  static int _buildingScienceFor(
    GameCity city,
    ScienceBalance scienceBalance,
    CityRuleset cityRuleset,
  ) {
    final amounts = <int>[];
    for (final buildingType in city.buildings) {
      for (final effect
          in cityRuleset.buildingDefinitionFor(buildingType).effects) {
        if (effect case FlatCityScienceEffect(:final amount) when amount > 0) {
          amounts.add(amount);
        }
      }
    }
    if (amounts.isEmpty) return 0;

    amounts.sort((a, b) => b.compareTo(a));
    var total = 0.0;
    for (var i = 0; i < amounts.length; i++) {
      final multiplier = switch (i) {
        0 => 1.0,
        1 => scienceBalance.secondScienceBuildingMultiplier,
        _ => scienceBalance.thirdScienceBuildingMultiplier,
      };
      total += amounts[i] * multiplier;
    }
    return total.round();
  }
}
