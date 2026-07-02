part of 'production_scorer.dart';

final class _BuildingProductionScorecard {
  const _BuildingProductionScorecard({
    required this.buildingType,
    required this.city,
    required this.view,
    required this.context,
    required this.assessment,
    required this.planState,
    required this.cache,
    required this.definition,
    required this.economy,
    required this.buildingProfile,
    required this.yieldWeights,
    required this.essentialsPressure,
    required this.secondCityPressure,
    required this.thirdCityPressure,
  });

  final CityBuildingType buildingType;
  final GameCity city;
  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final AiProductionPlanState planState;
  final AiProductionScoringCache cache;
  final CityBuildingDefinition definition;
  final CityEconomyBreakdown economy;
  final _BuildingProductionProfile buildingProfile;
  final AiProductionYieldWeights yieldWeights;
  final double essentialsPressure;
  final double secondCityPressure;
  final double thirdCityPressure;

  double score() {
    final effectScore = _scoreDefinitionEffects();

    return 1.0 +
        effectScore.score +
        _granaryOpeningBonus() +
        _firstInfrastructureBonus() +
        _militaryReadinessBonus() +
        _localDefenseBonus() +
        _strategicModeBonus() +
        _stabilityRecoveryBonus() +
        _economicBuildingBonus() +
        _infrastructureWindowBonus() +
        _productionYieldBonus(effectScore.hasProductionYield) +
        _goldReserveBonus() -
        _nonMilitaryOpportunityPenalty() -
        _expansionAndEssentialsPenalty() -
        _productionCostPenalty();
  }

  _BuildingEffectScore _scoreDefinitionEffects() {
    var score = 0.0;
    var hasProductionYield = false;

    for (final effect in definition.effects) {
      final effectScore = _scoreEffect(effect);
      score += effectScore.score;
      hasProductionYield |= effectScore.hasProductionYield;
    }

    return _BuildingEffectScore(
      score: score,
      hasProductionYield: hasProductionYield,
    );
  }

  _BuildingEffectScore _scoreEffect(CityBuildingEffect effect) {
    return switch (effect) {
      FlatCityYieldEffect(:final yield) => _BuildingEffectScore(
        score: weightedProductionYield(yield, yieldWeights),
        hasProductionYield: yield.production > 0,
      ),
      FlatCityScienceEffect(:final amount) => _BuildingEffectScore(
        score: amount * yieldWeights.science,
      ),
      RiverHexCityYieldEffect(
        :final yieldPerRiverHex,
        :final maxApplications,
      ) =>
        _BuildingEffectScore(
          score:
              weightedProductionYield(yieldPerRiverHex, yieldWeights) *
              _effectiveApplicationCount(
                _riverHexCount(city, view.mapData),
                maxApplications,
              ),
          hasProductionYield: yieldPerRiverHex.production > 0,
        ),
      MaxControlledHexesEffect(:final amount) => _BuildingEffectScore(
        score:
            amount *
            _territoryCapacityMultiplier() *
            context.effectiveWeights.expansion,
      ),
      FoodDepositMultiplierEffect(:final multiplier) => _BuildingEffectScore(
        score: economy.netYield.food > 0 ? 1.4 * multiplier : 0.4,
      ),
    };
  }

  double _territoryCapacityMultiplier() {
    final effectiveMaxHexes = CityBuildingRules.effectiveMaxHexes(
      city,
      ruleset: view.ruleset.city,
    );
    return city.territoryHexCount >= effectiveMaxHexes ? 1.2 : 0.7;
  }

  double _granaryOpeningBonus() {
    return buildingType == CityBuildingType.granary ? 2.6 : 0.0;
  }

  double _firstInfrastructureBonus() {
    if (view.turn > 36 || !_isFirstCoreInfrastructure) return 0.0;

    final empireHasBuildings = view.ownCities.any(
      (city) => city.buildings.isNotEmpty,
    );
    final base = empireHasBuildings ? 2.4 : 4.8;
    final secondCityBonus = assessment.cityCount >= 2 ? 1.8 : 0.0;
    final focusBonus = switch (buildingType) {
      CityBuildingType.granary => 1.8,
      _ when buildingProfile.isScience => 1.0,
      _ when buildingProfile.isEconomic => 0.7,
      _ => 0.0,
    };

    return base + secondCityBonus + focusBonus;
  }

  double _militaryReadinessBonus() {
    if (!buildingProfile.isMilitary || !assessment.needsMilitary) return 0.0;
    return 2.0 * context.effectiveWeights.aggression;
  }

  double _localDefenseBonus() {
    final localDefense = context.strategicPlan?.defenses[city.id];
    final localDefenseNeedsProduction =
        localDefense != null &&
        (localDefense.threatLevel > 0 || !localDefense.hasAssignedGarrison);
    if (!buildingProfile.isMilitary || !localDefenseNeedsProduction) {
      return 0.0;
    }

    final threat = localDefense.threatLevel.clamp(0, 12).toDouble();
    return 1.8 * context.effectiveWeights.aggression + threat * 0.15;
  }

  double _strategicModeBonus() {
    return switch (context.strategicPlan?.mode) {
      StrategicMode.military => buildingProfile.isMilitary ? 2.5 : 0.0,
      StrategicMode.recover ||
      StrategicMode.consolidate => buildingProfile.isEconomic ? 1.4 : 0.0,
      StrategicMode.techRush => buildingProfile.isScience ? 1.8 : 0.0,
      StrategicMode.expand || null => 0.0,
    };
  }

  double _stabilityRecoveryBonus() {
    if (!StabilitySourceCatalog.orderBuildings.contains(buildingType)) {
      return 0.0;
    }
    return switch (StabilityPolicy.bandFor(
      view.ownStabilityNet,
      ruleset: view.ruleset.stability,
    )) {
      StabilityBand.content => 0.0,
      StabilityBand.stable => 0.8,
      StabilityBand.strained => 6.0,
      StabilityBand.unrest => 12.0,
    };
  }

  double _nonMilitaryOpportunityPenalty() {
    final weights = context.effectiveWeights;
    final empirePrefersArmy =
        assessment.needsMilitary && weights.aggression > weights.expansion;
    return empirePrefersArmy && !buildingProfile.isMilitary ? 3.0 : 0.0;
  }

  double _economicBuildingBonus() {
    return buildingProfile.isEconomic
        ? 3.0 * context.effectiveWeights.economy
        : 0.0;
  }

  double _infrastructureWindowBonus() {
    if (!_hasInfrastructureWindow(context, assessment, planState)) return 0.0;
    final focusBonus = buildingProfile.isEconomic || buildingProfile.isScience
        ? 2.0
        : 0.0;
    return 7.0 + focusBonus;
  }

  double _productionYieldBonus(bool hasProductionYield) {
    if (!hasProductionYield) return 0.0;
    return 1.2 + (assessment.wantsExpansion ? 0.4 : 0.0);
  }

  double _goldReserveBonus() {
    return buildingProfile.isEconomic && assessment.needsGoldReserve
        ? 1.8
        : 0.0;
  }

  double _expansionAndEssentialsPenalty() {
    return essentialsPressure * _essentialPressureMultiplier() +
        secondCityPressure * _secondCityPressureMultiplier() +
        thirdCityPressure * _thirdCityPressureMultiplier();
  }

  double _essentialPressureMultiplier() {
    if (_isFirstCoreInfrastructure) return 0.7;
    return buildingProfile.isMilitary ? 0.45 : 1.0;
  }

  double _secondCityPressureMultiplier() {
    if (_isFirstCoreInfrastructure) return 0.65;
    return buildingProfile.isMilitary ? 0.5 : 1.0;
  }

  double _thirdCityPressureMultiplier() {
    if (_isFirstCoreInfrastructure) return 0.45;
    return buildingProfile.isMilitary ? 0.55 : 1.0;
  }

  bool get _isFirstCoreInfrastructure {
    if (city.buildings.isNotEmpty) return false;
    return buildingType == CityBuildingType.granary ||
        buildingProfile.isEconomic ||
        buildingProfile.isScience;
  }

  double _productionCostPenalty() {
    return productionCostPenalty(
      view.ruleset.paceBalance.buildingProductionCost(
        definition.productionCost,
      ),
      productionPerTurnForTarget(
        city: city,
        target: BuildingProductionTarget(buildingType),
        cache: cache,
      ),
    );
  }
}

final class _BuildingEffectScore {
  const _BuildingEffectScore({
    required this.score,
    this.hasProductionYield = false,
  });

  final double score;
  final bool hasProductionYield;
}

final class _BuildingProductionProfile {
  const _BuildingProductionProfile({
    required this.isMilitary,
    required this.isEconomic,
    required this.isScience,
  });

  final bool isMilitary;
  final bool isEconomic;
  final bool isScience;

  factory _BuildingProductionProfile.forType(CityBuildingType type) {
    return _BuildingProductionProfile(
      isMilitary: _isMilitaryBuilding(type),
      isEconomic: _isEconomicBuilding(type),
      isScience: _isScienceBuilding(type),
    );
  }
}
