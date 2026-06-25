import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_definition.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_unlock.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class TechnologyUnlockQuery {
  static bool hasBuildingUnlocked({
    required String playerId,
    required CityBuildingType buildingType,
    required ResearchState research,
    required TechnologyRuleset ruleset,
  }) {
    final requiredUnlock = unlockIdForBuilding(buildingType);
    if (requiredUnlock == null) return true;

    final playerResearch = research.forPlayer(playerId);
    for (final technologyId in playerResearch.unlockedTechnologyIds) {
      final technology = ruleset.technologies[technologyId];
      if (technology == null) continue;
      if (_unlocksBuilding(technology, requiredUnlock)) return true;
    }
    return false;
  }

  static TechnologyDefinition? unlockingTechnologyForBuilding({
    required CityBuildingType buildingType,
    required TechnologyRuleset ruleset,
  }) {
    final requiredUnlock = unlockIdForBuilding(buildingType);
    if (requiredUnlock == null) return null;

    for (final technology in ruleset.technologies.values) {
      if (_unlocksBuilding(technology, requiredUnlock)) {
        return technology;
      }
    }
    return null;
  }

  static bool hasUnitUnlocked({
    required String playerId,
    required GameUnitType unitType,
    required ResearchState research,
    required TechnologyRuleset ruleset,
  }) {
    if (!unitType.canBeProducedByCities) return false;

    final requiredTechnology = unlockingTechnologyForUnit(
      unitType: unitType,
      ruleset: ruleset,
    );
    if (requiredTechnology == null) return true;

    final playerResearch = research.forPlayer(playerId);
    return playerResearch.hasUnlocked(requiredTechnology.id);
  }

  static TechnologyDefinition? unlockingTechnologyForUnit({
    required GameUnitType unitType,
    required TechnologyRuleset ruleset,
  }) {
    for (final technology in ruleset.technologies.values) {
      if (_unlocksUnit(technology, unitType)) {
        return technology;
      }
    }
    return null;
  }

  static bool hasFieldImprovementUnlocked({
    required String playerId,
    required FieldImprovementType improvementType,
    required ResearchState research,
    required TechnologyRuleset ruleset,
  }) {
    final requiredTechnology = unlockingTechnologyForFieldImprovement(
      improvementType: improvementType,
      ruleset: ruleset,
    );
    if (requiredTechnology == null) return true;

    final playerResearch = research.forPlayer(playerId);
    return playerResearch.hasUnlocked(requiredTechnology.id);
  }

  static TechnologyDefinition? unlockingTechnologyForFieldImprovement({
    required FieldImprovementType improvementType,
    required TechnologyRuleset ruleset,
  }) {
    for (final technology in ruleset.technologies.values) {
      if (_unlocksFieldImprovement(technology, improvementType)) {
        return technology;
      }
    }
    return null;
  }

  static CityBuildingUnlockId? unlockIdForBuilding(CityBuildingType type) {
    if (type == CityBuildingType.granary) return null;
    return CityBuildingUnlockId.fromString(type.name);
  }

  static CityBuildingType? buildingTypeForUnlock(
    CityBuildingUnlockId unlockId,
  ) {
    return CityBuildingType.fromString(unlockId.name);
  }

  static bool _unlocksBuilding(
    TechnologyDefinition technology,
    CityBuildingUnlockId requiredUnlock,
  ) {
    for (final unlock in technology.unlocks) {
      if (unlock is UnlockCityBuilding && unlock.buildingId == requiredUnlock) {
        return true;
      }
    }
    return false;
  }

  static bool _unlocksUnit(
    TechnologyDefinition technology,
    GameUnitType unitType,
  ) {
    for (final unlock in technology.unlocks) {
      if (unlock is UnlockUnitType && unlock.unitType == unitType) {
        return true;
      }
    }
    return false;
  }

  static bool _unlocksFieldImprovement(
    TechnologyDefinition technology,
    FieldImprovementType improvementType,
  ) {
    for (final unlock in technology.unlocks) {
      if (unlock is UnlockFieldImprovement &&
          unlock.improvementType == improvementType) {
        return true;
      }
    }
    return false;
  }
}
