import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/technology_branch_classifier.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';

final class AiTechnologyPersonaScorer {
  const AiTechnologyPersonaScorer({
    this.branchClassifier = const AiTechnologyBranchClassifier(),
  });

  final AiTechnologyBranchClassifier branchClassifier;

  double score({
    required TechnologyDefinition definition,
    required PersonaWeights weights,
    required TechBranchPreferences techBias,
    StrategicMode? mode,
  }) {
    var score = _branchScore(definition.id, weights, techBias, mode);
    for (final unlock in definition.unlocks) {
      score += _unlockScore(unlock, weights) * 0.1;
    }
    for (final effect in definition.effects) {
      score += _effectScore(effect, weights) * 0.2;
    }
    return score;
  }

  double _branchScore(
    TechnologyId id,
    PersonaWeights weights,
    TechBranchPreferences techBias,
    StrategicMode? mode,
  ) {
    final branch = branchClassifier.branchFor(id);
    final base = switch (branch) {
      TechBranch.military => weights.aggression,
      TechBranch.expansion => weights.expansion,
      TechBranch.economy => weights.economy,
      TechBranch.science => weights.science,
    };
    return base *
        techBias.weightFor(branch) *
        _strategicBranchBias(mode, branch);
  }

  double _strategicBranchBias(StrategicMode? mode, TechBranch branch) {
    return switch ((mode, branch)) {
      (StrategicMode.military, TechBranch.military) => 1.3,
      (StrategicMode.military, TechBranch.expansion) => 0.8,
      (StrategicMode.expand, TechBranch.expansion) => 1.3,
      (StrategicMode.expand, TechBranch.economy) => 1.1,
      (StrategicMode.techRush, TechBranch.science) => 1.35,
      (StrategicMode.techRush, TechBranch.economy) => 1.1,
      (StrategicMode.recover, TechBranch.economy) => 1.25,
      (StrategicMode.recover, TechBranch.expansion) => 0.8,
      (StrategicMode.consolidate, TechBranch.economy) => 1.2,
      (StrategicMode.consolidate, TechBranch.science) => 1.1,
      _ => 1.0,
    };
  }

  double _unlockScore(TechnologyUnlock unlock, PersonaWeights weights) {
    return switch (unlock) {
      UnlockUnitType() => weights.aggression,
      UnlockFieldImprovement(:final improvementType) => _improvementScore(
        improvementType,
        weights,
      ),
      UnlockCityBuilding(:final buildingId) => _buildingScore(
        buildingId,
        weights,
      ),
    };
  }

  double _effectScore(TechnologyEffect effect, PersonaWeights weights) {
    return switch (effect) {
      StrategicResourceProductionBonus() => weights.economy,
      GlobalGoldMultiplier() => weights.economy,
      CityDefenseBonus() => weights.aggression,
      ArmyProductionMultiplier() => weights.aggression,
      ArmyStrengthMultiplier() => weights.aggression,
      ArmyCombatStatsBonus() => weights.aggression,
      MaxCityPopulationBonus() => weights.expansion,
      MaxControlledHexesBonus() => weights.expansion,
      CityScienceBonus() => weights.science,
    };
  }

  double _improvementScore(
    FieldImprovementType improvementType,
    PersonaWeights weights,
  ) {
    return switch (improvementType) {
      FieldImprovementType.farm ||
      FieldImprovementType.riverFarm ||
      FieldImprovementType.pasture ||
      FieldImprovementType.fishingBoats ||
      FieldImprovementType.orchard ||
      FieldImprovementType.horseRanch ||
      FieldImprovementType.pearlDivers => weights.expansion,
      FieldImprovementType.mine ||
      FieldImprovementType.lumberMill ||
      FieldImprovementType.quarry ||
      FieldImprovementType.plantation ||
      FieldImprovementType.vineyard ||
      FieldImprovementType.tradingPost ||
      FieldImprovementType.prospectorCamp ||
      FieldImprovementType.coalShaft ||
      FieldImprovementType.oilWell ||
      FieldImprovementType.bauxiteMine ||
      FieldImprovementType.uraniumMine => weights.economy,
      FieldImprovementType.camp => weights.aggression,
    };
  }

  double _buildingScore(
    CityBuildingUnlockId buildingId,
    PersonaWeights weights,
  ) {
    return switch (buildingId) {
      CityBuildingUnlockId.barracks ||
      CityBuildingUnlockId.stable ||
      CityBuildingUnlockId.trainingGrounds ||
      CityBuildingUnlockId.walls ||
      CityBuildingUnlockId.armory ||
      CityBuildingUnlockId.siegeWorkshop ||
      CityBuildingUnlockId.citadel ||
      CityBuildingUnlockId.warCollege ||
      CityBuildingUnlockId.conscriptionOffice ||
      CityBuildingUnlockId.borderFort ||
      CityBuildingUnlockId.airfield ||
      CityBuildingUnlockId.shipyard ||
      CityBuildingUnlockId.dryDock ||
      CityBuildingUnlockId.navalAcademy => weights.aggression,
      CityBuildingUnlockId.merchantHall ||
      CityBuildingUnlockId.marketplace ||
      CityBuildingUnlockId.bank ||
      CityBuildingUnlockId.workshop ||
      CityBuildingUnlockId.stonemason ||
      CityBuildingUnlockId.forge ||
      CityBuildingUnlockId.buildersGuild ||
      CityBuildingUnlockId.factory ||
      CityBuildingUnlockId.artisansGuild ||
      CityBuildingUnlockId.masterWorkshop ||
      CityBuildingUnlockId.steelworks ||
      CityBuildingUnlockId.railDepot ||
      CityBuildingUnlockId.powerPlant ||
      CityBuildingUnlockId.assemblyPlant ||
      CityBuildingUnlockId.refinery ||
      CityBuildingUnlockId.harborCustoms => weights.economy,
      CityBuildingUnlockId.storehouse ||
      CityBuildingUnlockId.waterMill ||
      CityBuildingUnlockId.housing ||
      CityBuildingUnlockId.port ||
      CityBuildingUnlockId.aqueduct ||
      CityBuildingUnlockId.lighthouse ||
      CityBuildingUnlockId.townHall ||
      CityBuildingUnlockId.monument ||
      CityBuildingUnlockId.governorsOffice ||
      CityBuildingUnlockId.planningOffice ||
      CityBuildingUnlockId.publicBaths ||
      CityBuildingUnlockId.parliament ||
      CityBuildingUnlockId.worldFairGrounds => weights.expansion,
      CityBuildingUnlockId.archive ||
      CityBuildingUnlockId.academy ||
      CityBuildingUnlockId.university ||
      CityBuildingUnlockId.observatory ||
      CityBuildingUnlockId.laboratory ||
      CityBuildingUnlockId.reactor ||
      CityBuildingUnlockId.surveyorsOffice ||
      CityBuildingUnlockId.apothecary ||
      CityBuildingUnlockId.hospital ||
      CityBuildingUnlockId.mapRoom ||
      CityBuildingUnlockId.museum => weights.science,
      CityBuildingUnlockId.courthouse ||
      CityBuildingUnlockId.court ||
      CityBuildingUnlockId.ministries ||
      CityBuildingUnlockId.broadcastTower => weights.expansion,
    };
  }
}
