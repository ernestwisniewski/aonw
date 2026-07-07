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
import 'package:aonw_core/game/domain/wonder/wonder_effect_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';

abstract final class ScienceYieldCalculator {
  static int totalAmountForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required ResearchState research,
    required TechnologyRuleset ruleset,
    Iterable<WorldArtifact> artifacts = const [],
    CityRuleset cityRuleset = CityRulesets.standard,
    WonderRegistry wonderRegistry = WonderRegistry.empty,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) {
    return _totalForPlayer(
      playerId: playerId,
      cities: cities,
      research: research,
      ruleset: ruleset,
      artifacts: artifacts,
      cityRuleset: cityRuleset,
      wonderRegistry: wonderRegistry,
      wonderRuleset: wonderRuleset,
      collectSources: false,
    ).total;
  }

  static ScienceYieldBreakdown totalForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required ResearchState research,
    required TechnologyRuleset ruleset,
    Iterable<WorldArtifact> artifacts = const [],
    CityRuleset cityRuleset = CityRulesets.standard,
    WonderRegistry wonderRegistry = WonderRegistry.empty,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
  }) {
    return _totalForPlayer(
      playerId: playerId,
      cities: cities,
      research: research,
      ruleset: ruleset,
      artifacts: artifacts,
      cityRuleset: cityRuleset,
      wonderRegistry: wonderRegistry,
      wonderRuleset: wonderRuleset,
      collectSources: true,
    );
  }

  static ScienceYieldBreakdown _totalForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required ResearchState research,
    required TechnologyRuleset ruleset,
    required Iterable<WorldArtifact> artifacts,
    required CityRuleset cityRuleset,
    required WonderRegistry wonderRegistry,
    required WonderRuleset wonderRuleset,
    required bool collectSources,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: research,
      ruleset: ruleset,
    );

    final byCityId = collectSources ? <String, int>{} : null;
    final sources = collectSources ? <ScienceYieldSource>[] : null;
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
      final wonderAmount = WonderEffectResolver.scienceForCity(
        city: city,
        cities: cities,
        registry: wonderRegistry,
        ruleset: wonderRuleset,
      );
      final amount = baseAmount + artifactAmount + wonderAmount;
      if (amount <= 0) continue;

      if (collectSources) {
        byCityId![city.id] = amount;
        if (baseAmount > 0) {
          sources!.add(
            ScienceYieldSource(
              cityId: city.id,
              amount: baseAmount,
              label: ScienceYieldSourceLabels.cityScience,
            ),
          );
        }
        if (artifactAmount > 0) {
          sources!.add(
            ScienceYieldSource(
              cityId: city.id,
              amount: artifactAmount,
              label: ScienceYieldSourceLabels.worldArtifact,
            ),
          );
        }
        if (wonderAmount > 0) {
          sources!.add(
            ScienceYieldSource(
              cityId: city.id,
              amount: wonderAmount,
              label: ScienceYieldSourceLabels.worldWonder,
            ),
          );
        }
      }
      total += amount;
    }

    if (total == 0) return ScienceYieldBreakdown.empty;
    return ScienceYieldBreakdown(
      total: total,
      byCityId: byCityId == null ? const {} : Map.unmodifiable(byCityId),
      sources: sources == null ? const [] : List.unmodifiable(sources),
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
