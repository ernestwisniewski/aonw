import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/production_models.dart';
import 'package:aonw_core/ai/production_scoring_cache.dart';
import 'package:aonw_core/ai/production_scoring_math.dart';
import 'package:aonw_core/ai/production_unit_scorer.dart';
import 'package:aonw_core/ai/production_yield_weights.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

export 'package:aonw_core/ai/production_models.dart';

part 'production_building_scorer.dart';
part 'production_project_scorer.dart';

class AiProductionScorer {
  final AiUnitProductionScorer unitScorer;

  const AiProductionScorer({this.unitScorer = const AiUnitProductionScorer()});

  AiProductionRecommendation recommend({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
  }) {
    final cache = AiProductionScoringCache(view: view, context: context);
    AiProductionRecommendation? best;
    for (final candidate in [
      ..._unitCandidates(
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      ),
      ..._buildingCandidates(
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      ),
      ..._projectCandidates(
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      ),
    ]) {
      if (best == null || _compareRecommendations(candidate, best) < 0) {
        best = candidate;
      }
    }

    return best!;
  }

  Iterable<AiProductionRecommendation> _unitCandidates({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) sync* {
    for (final unitType in GameUnitType.values) {
      if (!_canProduceUnit(
        view,
        city: city,
        unitType: unitType,
        reservedSupply: planState.reservedUnitSupply,
        cache: cache,
      )) {
        continue;
      }
      final score = unitScorer.score(
        unitType,
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      );
      if (score <= 0) continue;
      yield AiProductionRecommendation(
        cityId: city.id,
        target: UnitProductionTarget(unitType),
        score: score,
        reason: 'unit ${unitType.name}',
      );
    }
  }

  Iterable<AiProductionRecommendation> _buildingCandidates({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) sync* {
    for (final buildingType in CityBuildingType.values) {
      if (!_canBuild(
        view,
        city: city,
        buildingType: buildingType,
        cache: cache,
      )) {
        continue;
      }
      final score = _scoreBuilding(
        buildingType,
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
        cache: cache,
      );
      if (score <= 0) continue;
      yield AiProductionRecommendation(
        cityId: city.id,
        target: BuildingProductionTarget(buildingType),
        score: score,
        reason: 'building ${buildingType.name}',
      );
    }
  }

  Iterable<AiProductionRecommendation> _projectCandidates({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) sync* {
    for (final projectType in CityProjectType.values) {
      yield AiProductionRecommendation(
        cityId: city.id,
        target: ProjectProductionTarget(projectType),
        score: _scoreProject(
          projectType,
          city: city,
          view: view,
          context: context,
          assessment: assessment,
          planState: planState,
          cache: cache,
        ),
        reason: 'project ${projectType.name}',
      );
    }
  }

  double _scoreBuilding(
    CityBuildingType buildingType, {
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) {
    final definition = view.ruleset.city.buildingDefinitionFor(buildingType);
    final economy = _economyFor(view, city, cache: cache);
    return _BuildingProductionScorecard(
      buildingType: buildingType,
      city: city,
      view: view,
      context: context,
      assessment: assessment,
      planState: planState,
      cache: cache,
      definition: definition,
      economy: economy,
      buildingProfile: _BuildingProductionProfile.forType(buildingType),
      yieldWeights: productionYieldWeights(
        economy: economy,
        context: context,
        assessment: assessment,
      ),
      essentialsPressure: _essentialProductionPressure(assessment, planState),
      secondCityPressure: _stableSecondCityExpansionPressure(
        assessment,
        planState,
      ),
      thirdCityPressure: _stableThirdCityExpansionPressure(
        assessment,
        planState,
      ),
    ).score();
  }

  double _scoreProject(
    CityProjectType projectType, {
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) {
    final economy = _economyFor(view, city, cache: cache);
    return _ProjectProductionScorecard(
      projectType: projectType,
      context: context,
      assessment: assessment,
      planState: planState,
      productionOutput: CityProjectRules.outputFor(
        type: projectType,
        productionPerTurn: CityProductionRules.productionPerTurn(
          economy.netYield.production,
        ),
      ),
      hasResearchTarget:
          view.ownResearch.activeTechnologyId != null ||
          planState.hasResearchTarget,
      availableUnitSupply: _availableUnitSupply(view, planState, cache: cache),
      hasInfrastructureWindow: _hasInfrastructureWindow(
        context,
        assessment,
        planState,
      ),
      essentialsPressure: _essentialProductionPressure(assessment, planState),
      secondCityPressure: _stableSecondCityExpansionPressure(
        assessment,
        planState,
      ),
      thirdCityPressure: _stableThirdCityExpansionPressure(
        assessment,
        planState,
      ),
    ).score();
  }

  bool _canProduceUnit(
    GameView view, {
    required GameCity city,
    required GameUnitType unitType,
    required int reservedSupply,
    required AiProductionScoringCache cache,
  }) {
    final research = _researchFor(view, cache: cache);
    final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: view.forPlayerId,
      unitType: unitType,
      research: research,
      ruleset: view.ruleset.technology,
    );
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: view.forPlayerId,
      unitType: unitType,
      cities: view.ownCities,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      research: research,
      resourceTradeAgreements: view.resourceTradeAgreements,
    );
    if (!CityProductionRules.canProduceUnit(
      unitType,
      ruleset: view.ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return false;
    }
    if (!CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: unitType,
      mapData: view.mapData,
    )) {
      return false;
    }
    return CityUnitSupplyRules.canQueueUnit(
      playerId: view.forPlayerId,
      unitType: unitType,
      cities: view.ownCities,
      units: view.ownUnits,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
      cityRuleset: view.ruleset.city,
      research: research,
      technologyRuleset: view.ruleset.technology,
      replacingCityId: city.id,
      reservedSupply: reservedSupply,
    );
  }

  bool _canBuild(
    GameView view, {
    required GameCity city,
    required CityBuildingType buildingType,
    required AiProductionScoringCache cache,
  }) {
    final research = _researchFor(view, cache: cache);
    final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: view.forPlayerId,
      buildingType: buildingType,
      research: research,
      ruleset: view.ruleset.technology,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: buildingType,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      research: research,
    );
    return CityProductionRules.canBuild(
      city.buildings,
      buildingType,
      ruleset: view.ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    );
  }

  CityEconomyBreakdown _economyFor(
    GameView view,
    GameCity city, {
    AiProductionScoringCache? cache,
  }) {
    if (cache != null) return cache.economyFor(city);
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: view.forPlayerId,
      research: _researchFor(view),
      ruleset: view.ruleset.technology,
    );
    final cityYield = CityYieldCalculator.totalFor(
      city,
      view.mapData,
      fieldImprovements: view.ownImprovements,
      units: view.ownUnits,
      ruleset: view.ruleset.city,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      paceBalance: view.ruleset.paceBalance,
      technologyEffects: technologyEffects,
    );
  }

  ResearchState _researchFor(GameView view, {AiProductionScoringCache? cache}) {
    if (cache != null) return cache.research;
    return ResearchState(players: {view.forPlayerId: view.ownResearch});
  }

  int _availableUnitSupply(
    GameView view,
    AiProductionPlanState planState, {
    AiProductionScoringCache? cache,
  }) {
    if (cache != null) return cache.availableUnitSupply(planState);
    final breakdown = CityUnitSupplyRules.forPlayer(
      playerId: view.forPlayerId,
      cities: view.ownCities,
      units: view.ownUnits,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
      cityRuleset: view.ruleset.city,
      research: _researchFor(view),
      technologyRuleset: view.ruleset.technology,
    );
    final available = breakdown.available - planState.reservedUnitSupply;
    return available < 0 ? 0 : available;
  }

  int _compareRecommendations(
    AiProductionRecommendation a,
    AiProductionRecommendation b,
  ) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return _targetOrder(a.target).compareTo(_targetOrder(b.target));
  }

  int _targetOrder(CityProductionTarget target) {
    return switch (target) {
      UnitProductionTarget(:final unitType) => 100 + unitType.index,
      BuildingProductionTarget(:final buildingType) => 200 + buildingType.index,
      ProjectProductionTarget(:final projectType) => 300 + projectType.index,
    };
  }

  double _essentialProductionPressure(
    AiEmpireAssessment assessment,
    AiProductionPlanState planState,
  ) {
    final workerDeficit =
        (assessment.desiredWorkerCount - planState.workerCount)
            .clamp(0, 4)
            .toDouble();
    final needsDefenseCoverage =
        planState.militaryCount > 0 || assessment.visibleEnemyMilitaryCount > 0;
    final defenseCoverageDeficit = needsDefenseCoverage
        ? (assessment.cityCount - planState.militaryCount)
              .clamp(0, 4)
              .toDouble()
        : 0.0;
    return workerDeficit * 3.0 + defenseCoverageDeficit * 2.5;
  }

  double _stableSecondCityExpansionPressure(
    AiEmpireAssessment assessment,
    AiProductionPlanState planState,
  ) {
    if (!assessment.wantsExpansion) return 0;
    if (assessment.cityCount != 1 || planState.settlerCount > 0) return 0;
    if (planState.militaryCount < 2) return 0;
    if (assessment.netGoldPerTurn < -2) return 0;
    if (assessment.enemyMilitaryPressure) {
      return planState.militaryCount >= 3 ? 18.0 : 0.0;
    }
    return 22.0;
  }

  double _stableThirdCityExpansionPressure(
    AiEmpireAssessment assessment,
    AiProductionPlanState planState,
  ) {
    if (!assessment.wantsExpansion) return 0;
    if (assessment.cityCount != 2 || planState.settlerCount > 0) return 0;
    if (planState.militaryCount < assessment.cityCount) return 0;
    if (assessment.enemyMilitaryPressure) return 0;
    if (assessment.netGoldPerTurn < 0) return 0;

    final expansionDeficit =
        (assessment.desiredCityCount - assessment.cityCount)
            .clamp(0, 4)
            .toDouble();
    final workerCoverageDeficit = (assessment.cityCount - planState.workerCount)
        .clamp(0, 2)
        .toDouble();
    return 13.0 + expansionDeficit * 1.5 - workerCoverageDeficit * 2.0;
  }
}

bool _isMilitaryBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.barracks ||
    CityBuildingType.stable ||
    CityBuildingType.trainingGrounds ||
    CityBuildingType.walls ||
    CityBuildingType.armory ||
    CityBuildingType.siegeWorkshop ||
    CityBuildingType.citadel ||
    CityBuildingType.warCollege ||
    CityBuildingType.conscriptionOffice ||
    CityBuildingType.borderFort ||
    CityBuildingType.airfield ||
    CityBuildingType.shipyard ||
    CityBuildingType.dryDock ||
    CityBuildingType.navalAcademy => true,
    _ => false,
  };
}

bool _isEconomicBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.merchantHall ||
    CityBuildingType.marketplace ||
    CityBuildingType.bank ||
    CityBuildingType.workshop ||
    CityBuildingType.stonemason ||
    CityBuildingType.forge ||
    CityBuildingType.buildersGuild ||
    CityBuildingType.factory ||
    CityBuildingType.artisansGuild ||
    CityBuildingType.masterWorkshop ||
    CityBuildingType.steelworks ||
    CityBuildingType.railDepot ||
    CityBuildingType.powerPlant ||
    CityBuildingType.assemblyPlant ||
    CityBuildingType.refinery ||
    CityBuildingType.harborCustoms => true,
    _ => false,
  };
}

bool _isScienceBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.archive ||
    CityBuildingType.academy ||
    CityBuildingType.university ||
    CityBuildingType.observatory ||
    CityBuildingType.laboratory ||
    CityBuildingType.reactor ||
    CityBuildingType.surveyorsOffice ||
    CityBuildingType.apothecary ||
    CityBuildingType.hospital ||
    CityBuildingType.mapRoom ||
    CityBuildingType.museum => true,
    _ => false,
  };
}

bool _wantsEconomicReserve(AiContext context, AiEmpireAssessment assessment) {
  final weights = context.effectiveWeights;
  if (weights.economy <= weights.science) return false;
  final minimumReserve = 6 + assessment.cityCount * 2;
  final personaReserve = minimumReserve * (1 + (weights.economy - 1) * 4);
  return assessment.goldReserve <= personaReserve.ceil() ||
      (weights.economy >= 1.2 && assessment.netGoldPerTurn <= 0);
}

bool _hasInfrastructureWindow(
  AiContext context,
  AiEmpireAssessment assessment,
  AiProductionPlanState planState,
) {
  final weights = context.effectiveWeights;
  if (assessment.cityCount < 2) return false;
  if (assessment.needsWorkers || assessment.needsMilitary) return false;
  if (assessment.visibleEnemyMilitaryCount > 0) return false;
  if (assessment.wantsExpansion &&
      assessment.cityCount < 3 &&
      planState.settlerCount == 0) {
    return false;
  }
  return weights.expansion < 1.2 || assessment.cityCount >= 3;
}

int _riverHexCount(GameCity city, MapData mapData) {
  var count = 0;
  for (final hex in city.territoryHexes) {
    final tile = mapData.tileAt(hex.col, hex.row);
    if (tile != null && CityTileYieldRules.hasRiver(tile)) count++;
  }
  return count;
}

int _effectiveApplicationCount(int count, int? maxApplications) {
  if (maxApplications == null) return count;
  return count < maxApplications ? count : maxApplications;
}
