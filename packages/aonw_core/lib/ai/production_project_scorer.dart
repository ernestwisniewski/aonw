part of 'production_scorer.dart';

final class _ProjectProductionScorecard {
  const _ProjectProductionScorecard({
    required this.projectType,
    required this.context,
    required this.assessment,
    required this.planState,
    required this.productionOutput,
    required this.hasResearchTarget,
    required this.availableUnitSupply,
    required this.hasInfrastructureWindow,
    required this.essentialsPressure,
    required this.secondCityPressure,
    required this.thirdCityPressure,
  });

  final CityProjectType projectType;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final AiProductionPlanState planState;
  final int productionOutput;
  final bool hasResearchTarget;
  final int availableUnitSupply;
  final bool hasInfrastructureWindow;
  final double essentialsPressure;
  final double secondCityPressure;
  final double thirdCityPressure;

  double score() {
    return _baseScore() -
        essentialsPressure -
        secondCityPressure -
        thirdCityPressure;
  }

  double _baseScore() {
    return switch (projectType) {
      CityProjectType.wealth => _wealthScore(),
      CityProjectType.research => _researchScore(),
    };
  }

  double _wealthScore() {
    final weights = context.effectiveWeights;

    if (!hasResearchTarget) {
      return 5.0 + productionOutput * 0.35 + supplyPressure;
    }
    if (assessment.netGoldPerTurn < 0) {
      return 6.0 + productionOutput * 0.35 + supplyPressure;
    }
    if (assessment.needsGoldReserve && !assessment.wantsExpansion) {
      return 6.0 + productionOutput * 0.35 + supplyPressure;
    }
    if (assessment.needsGoldReserve) {
      return 1.8 + productionOutput * 0.2 + supplyPressure * 0.5;
    }
    if (_shouldBalanceResearchWithWealth()) {
      return 4.5 +
          weights.economy * 0.3 +
          productionOutput * 0.25 +
          supplyPressure;
    }
    if (_wantsEconomicReserve(context, assessment)) {
      return 4.5 + productionOutput * 0.25 + supplyPressure;
    }

    return 0.9 + productionOutput * 0.15 + supplyPressure * 0.5;
  }

  bool _shouldBalanceResearchWithWealth() {
    final weights = context.effectiveWeights;
    return hasResearchTarget &&
        assessment.cityCount >= 2 &&
        planState.wealthProjectCount == 0 &&
        planState.researchProjectCount > 0 &&
        (weights.economy > weights.science || assessment.netGoldPerTurn < 2);
  }

  double _researchScore() {
    if (_shouldStartFirstResearchProject()) {
      return _firstResearchProjectScore();
    }
    if (hasResearchTarget) {
      return _followUpResearchProjectScore();
    }
    return 0.2;
  }

  bool _shouldStartFirstResearchProject() {
    return hasResearchTarget &&
        assessment.cityCount >= 2 &&
        planState.researchProjectCount == 0;
  }

  double _firstResearchProjectScore() {
    final weights = context.effectiveWeights;
    return 4.2 +
        weights.science * 0.8 +
        productionOutput * 0.35 +
        supplyPressure +
        (hasInfrastructureWindow ? 5.0 : 0) +
        (isTechRush ? 2.0 : 0);
  }

  double _followUpResearchProjectScore() {
    final weights = context.effectiveWeights;
    return 2.8 +
        weights.science * 0.7 +
        productionOutput * 0.3 +
        supplyPressure * 0.5 +
        (hasInfrastructureWindow ? 4.0 : 0) +
        (isTechRush ? 1.2 : 0);
  }

  double get supplyPressure {
    return availableUnitSupply <= 1
        ? 2.4
        : availableUnitSupply <= 2
        ? 1.2
        : 0.0;
  }

  bool get isTechRush => context.strategicPlan?.mode == StrategicMode.techRush;
}
