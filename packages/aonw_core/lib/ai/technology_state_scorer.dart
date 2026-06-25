import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_persona.dart';
import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/technology_branch_classifier.dart';
import 'package:aonw_core/ai/technology_score_snapshot.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class AiTechnologyStateScorer {
  const AiTechnologyStateScorer({
    this.branchClassifier = const AiTechnologyBranchClassifier(),
  });

  final AiTechnologyBranchClassifier branchClassifier;

  double score({
    required GameView view,
    required TechnologyDefinition definition,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiTechnologyScoreSnapshot snapshot,
    StrategicMode? mode,
  }) {
    final id = definition.id;
    final branch = branchClassifier.branchFor(id);
    var score = _openingScore(view, id, context.persona);

    final shouldPrioritizeMilitary =
        assessment.needsMilitary &&
        (assessment.cityCount > 0 || view.visibleEnemyUnits.isNotEmpty);
    if (shouldPrioritizeMilitary && branchClassifier.isMilitaryTechnology(id)) {
      score += 0.55 + snapshot.militaryPressure * 0.25;
    }
    if (assessment.needsGoldReserve && branchClassifier.isGoldTechnology(id)) {
      score += 0.55 + snapshot.goldPressure * 0.25;
    }
    if (assessment.wantsExpansion &&
        branchClassifier.isExpansionTechnology(id)) {
      score += 0.35 + snapshot.growthPressure * 0.15;
    }
    if (assessment.needsWorkers &&
        branchClassifier.isWorkerEnablingTechnology(id)) {
      score += 0.25;
    }

    score += switch (branch) {
      TechBranch.military => snapshot.militaryPressure * 0.18,
      TechBranch.expansion => snapshot.growthPressure * 0.12,
      TechBranch.economy =>
        snapshot.productionPressure * 0.12 + snapshot.goldPressure * 0.10,
      TechBranch.science => snapshot.sciencePressure * 0.16,
    };

    for (final unlock in definition.unlocks) {
      score += _unlockScore(
        unlock,
        view: view,
        shouldPrioritizeMilitary: shouldPrioritizeMilitary,
        assessment: assessment,
        snapshot: snapshot,
      );
    }
    for (final effect in definition.effects) {
      score += _effectScore(effect, assessment, snapshot);
    }

    final satisfiedDiscount = TechnologyBoostEvaluator.bestDiscountFor(
      playerId: view.forPlayerId,
      technology: definition,
      cities: view.ownCities,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
    );
    score += satisfiedDiscount * 0.8;

    if (branchClassifier.isCoastalTechnology(definition) &&
        !snapshot.hasCoastalOpportunity) {
      score -= 0.30;
    }
    if (mode == StrategicMode.recover && branch == TechBranch.military) {
      score -= 0.12;
    }

    return score;
  }

  double _openingScore(GameView view, TechnologyId id, AiPersona persona) {
    if (view.ownResearch.unlockedTechnologyIds.isNotEmpty) return 0;
    return switch ((persona, id)) {
      (AiPersona.aggressive, TechnologyId.hunting) => 0.8,
      (AiPersona.economic, TechnologyId.mining) => 0.7,
      (AiPersona.expansive, TechnologyId.agriculture) => 0.8,
      (AiPersona.scientific, TechnologyId.agriculture) => 0.5,
      (AiPersona.balanced, TechnologyId.agriculture) => 0.7,
      _ => 0.0,
    };
  }

  double _unlockScore(
    TechnologyUnlock unlock, {
    required GameView view,
    required bool shouldPrioritizeMilitary,
    required AiEmpireAssessment assessment,
    required AiTechnologyScoreSnapshot snapshot,
  }) {
    return switch (unlock) {
      UnlockUnitType(:final unitType) => _unitUnlockScore(
        unitType,
        view,
        shouldPrioritizeMilitary,
        assessment,
        snapshot,
      ),
      UnlockFieldImprovement(:final improvementType) => _fieldImprovementScore(
        improvementType,
        view: view,
        assessment: assessment,
        snapshot: snapshot,
      ),
      UnlockCityBuilding(:final buildingId) => _buildingScore(
        buildingId,
        view: view,
        assessment: assessment,
        snapshot: snapshot,
      ),
    };
  }

  double _unitUnlockScore(
    GameUnitType unitType,
    GameView view,
    bool shouldPrioritizeMilitary,
    AiEmpireAssessment assessment,
    AiTechnologyScoreSnapshot snapshot,
  ) {
    if (unitType == GameUnitType.worker) {
      return assessment.needsWorkers ? 0.35 : 0.08;
    }
    if (unitType == GameUnitType.settler) {
      return assessment.wantsExpansion ? 0.35 : 0.08;
    }
    final stats = view.ruleset.combat.baseStatsFor(unitType);
    if (stats.attack > 0 || stats.defense > 0) {
      return shouldPrioritizeMilitary
          ? 0.45 + snapshot.militaryPressure * 0.20
          : 0.10;
    }
    return assessment.wantsExpansion ? 0.16 : 0.06;
  }

  double _fieldImprovementScore(
    FieldImprovementType type, {
    required GameView view,
    required AiEmpireAssessment assessment,
    required AiTechnologyScoreSnapshot snapshot,
  }) {
    final definition = view.ruleset.city.improvementDefinitionFor(type);
    final yield = definition.tileYield;
    final fit = snapshot.visibleImprovementFit(type, view.ruleset.city);
    final yieldAvailability = definition.resourceSpecialist
        ? fit
        : fit > 0
        ? 1.0
        : 0.0;
    var score = fit * (definition.resourceSpecialist ? 0.90 : 0.25);

    score +=
        yield.food *
        (0.08 + snapshot.growthPressure * 0.18) *
        yieldAvailability;
    score +=
        yield.production *
        (0.10 + snapshot.productionPressure * 0.22) *
        yieldAvailability;
    score +=
        yield.gold * (0.08 + snapshot.goldPressure * 0.20) * yieldAvailability;
    score +=
        yield.defense *
        (0.06 + snapshot.militaryPressure * 0.16) *
        yieldAvailability;

    if (assessment.wantsExpansion && yield.food > 0 && yieldAvailability > 0) {
      score += 0.08;
    }
    if (assessment.needsGoldReserve &&
        yield.gold > 0 &&
        yieldAvailability > 0) {
      score += 0.12;
    }
    if (assessment.needsWorkers && fit > 0) score += 0.08;
    if (definition.resourceSpecialist && fit == 0) score -= 0.12;
    return score;
  }

  double _buildingScore(
    CityBuildingUnlockId buildingId, {
    required GameView view,
    required AiEmpireAssessment assessment,
    required AiTechnologyScoreSnapshot snapshot,
  }) {
    final buildingType = CityBuildingType.fromString(buildingId.name);
    final definition = view.ruleset.city.buildingDefinitionFor(buildingType);
    var score = 0.0;

    for (final effect in definition.effects) {
      score += switch (effect) {
        FlatCityYieldEffect(:final yield) => _yieldScore(
          yield,
          assessment,
          snapshot,
        ),
        FlatCityScienceEffect(:final amount) => _scienceScore(amount, snapshot),
        RiverHexCityYieldEffect(:final yieldPerRiverHex) =>
          snapshot.hasRiverTile
              ? _yieldScore(yieldPerRiverHex, assessment, snapshot) * 1.8
              : 0.02,
        MaxControlledHexesEffect() => assessment.wantsExpansion ? 0.28 : 0.08,
        FoodDepositMultiplierEffect() => 0.10 + snapshot.growthPressure * 0.22,
      };
    }

    if (view.ownCities.isNotEmpty &&
        definition.requirements.isNotEmpty &&
        !view.ownCities.any(
          (city) => CityBuildingRequirementRules.meetsRequirements(
            city: city,
            buildingType: buildingType,
            mapData: view.mapData,
            ruleset: view.ruleset.city,
            research: ResearchState(
              players: {view.forPlayerId: view.ownResearch},
            ),
          ),
        )) {
      score -= 0.15;
    }

    return score;
  }

  double _yieldScore(
    TileYield yield,
    AiEmpireAssessment assessment,
    AiTechnologyScoreSnapshot snapshot,
  ) {
    var score = 0.0;
    score += yield.food * (0.08 + snapshot.growthPressure * 0.16);
    score += yield.production * (0.10 + snapshot.productionPressure * 0.22);
    score += yield.gold * (0.08 + snapshot.goldPressure * 0.20);
    score += yield.defense * (0.08 + snapshot.militaryPressure * 0.18);
    if (assessment.wantsExpansion && yield.food > 0) score += 0.08;
    if (assessment.needsGoldReserve && yield.gold > 0) score += 0.14;
    if (assessment.needsMilitary && yield.defense > 0) score += 0.10;
    return score;
  }

  double _scienceScore(int amount, AiTechnologyScoreSnapshot snapshot) {
    return amount * (0.12 + snapshot.sciencePressure * 0.22);
  }

  double _effectScore(
    TechnologyEffect effect,
    AiEmpireAssessment assessment,
    AiTechnologyScoreSnapshot snapshot,
  ) {
    return switch (effect) {
      StrategicResourceProductionBonus(
        :final resourceType,
        :final production,
      ) =>
        snapshot.controlsResource(resourceType)
            ? 0.20 + production * (0.12 + snapshot.productionPressure * 0.22)
            : snapshot.hasVisibleResource(resourceType)
            ? 0.12 + production * 0.08
            : 0.02,
      GlobalGoldMultiplier(:final multiplier) =>
        (assessment.needsGoldReserve ? 0.38 : 0.16) +
            multiplier * (1.0 + snapshot.goldPressure),
      CityDefenseBonus(:final amount) =>
        amount * (0.10 + snapshot.militaryPressure * 0.18),
      ArmyProductionMultiplier(:final multiplier) =>
        (assessment.needsMilitary ? 0.30 : 0.10) +
            multiplier * (1.0 + snapshot.productionPressure),
      ArmyStrengthMultiplier(:final multiplier) =>
        (assessment.needsMilitary ? 0.34 : 0.12) +
            multiplier * (1.2 + snapshot.militaryPressure),
      ArmyCombatStatsBonus(:final attack, :final defense, :final hp) =>
        (attack + defense + hp * 0.5) *
            (0.08 + snapshot.militaryPressure * 0.14),
      MaxCityPopulationBonus(:final amount) =>
        amount * (0.10 + snapshot.growthPressure * 0.16),
      MaxControlledHexesBonus(:final amount) =>
        amount *
            ((assessment.wantsExpansion ? 0.24 : 0.10) +
                snapshot.growthPressure * 0.08),
      CityScienceBonus(:final amount) =>
        amount * (0.14 + snapshot.sciencePressure * 0.18),
    };
  }
}
