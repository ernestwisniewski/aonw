part of 'production_scorer.dart';

class _WonderProductionScorer {
  const _WonderProductionScorer();

  Iterable<AiProductionRecommendation> candidates({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) sync* {
    if (planState.hasPlannedWonder) return;
    for (final wonderType in WonderType.values) {
      final availability = WonderAvailabilityPolicy.availabilityFor(
        city: city,
        wonderType: wonderType,
        cities: view.ownCities,
        registry: view.wonderRegistry,
        research: cache.research,
        mapData: view.mapData,
        ruleset: view.ruleset.wonders,
      );
      if (!availability.isAvailable) continue;

      final score = _score(
        wonderType,
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        cache: cache,
      );
      if (score <= 0) continue;
      yield AiProductionRecommendation(
        cityId: city.id,
        target: WonderProductionTarget(wonderType),
        score: score,
        reason: 'wonder ${wonderType.name}',
      );
    }
  }

  double _score(
    WonderType wonderType, {
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionScoringCache cache,
  }) {
    final definition = view.ruleset.wonders.definitionFor(wonderType);
    final economy = cache.economyFor(city);
    final yieldWeights = productionYieldWeights(
      economy: economy,
      context: context,
      assessment: assessment,
    );
    var value = 0.0;
    for (final effect in definition.standingEffects) {
      value += switch (effect) {
        EmpireFlatYieldEffect(:final yieldPerCity) =>
          _yieldValue(yieldPerCity, yieldWeights) * view.ownCities.length * 8,
        HostCityFlatYieldEffect(:final yield) =>
          _yieldValue(yield, yieldWeights) * 10,
        EmpireScienceEffect(:final perCity) =>
          perCity * view.ownCities.length * 10,
        EmpireGoldMultiplierEffect(:final multiplier) =>
          (assessment.netGoldPerTurn.abs() + 6) * multiplier * 20,
        EmpireProductionMultiplierEffect(:final multiplier) =>
          _empireProduction(view, cache) * multiplier * 12,
        StabilityEffect(:final delta) => delta * 9,
      };
    }
    for (final effect in definition.completionEffects) {
      value += switch (effect) {
        GrantFreeTechnology() =>
          view.ownResearch.activeTechnologyId == null ? 0 : 35,
        ProductionBurst(:final amount) => amount * 0.25,
        GrantGold(:final amount) => amount * 0.15,
      };
    }

    final cost = CityProductionRules.wonderProductionCost(
      wonderType,
      ruleset: view.ruleset.wonders,
      paceBalance: view.ruleset.paceBalance,
    );
    final productionPerTurn = CityProductionRules.productionPerTurn(
      economy.netYield.production,
    );
    final turnsRisk = productionPerTurn <= 0 ? 40.0 : cost / productionPerTurn;
    return value - cost * 0.06 - turnsRisk * 2.0;
  }

  double _yieldValue(TileYield yield, AiProductionYieldWeights weights) {
    return weightedProductionYield(yield, weights);
  }

  double _empireProduction(GameView view, AiProductionScoringCache cache) {
    var total = 0.0;
    for (final city in view.ownCities) {
      total += CityProductionRules.productionPerTurn(
        cache.economyFor(city).netYield.production,
      );
    }
    return total;
  }
}
