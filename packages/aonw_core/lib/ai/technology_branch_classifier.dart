import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class AiTechnologyBranchClassifier {
  const AiTechnologyBranchClassifier();

  TechBranch branchFor(TechnologyId id) {
    return switch (id) {
      TechnologyId.hunting ||
      TechnologyId.militaryOrganization ||
      TechnologyId.horsebackRiding ||
      TechnologyId.logistics ||
      TechnologyId.tactics ||
      TechnologyId.fortifications ||
      TechnologyId.strategy ||
      TechnologyId.siegecraft ||
      TechnologyId.navalDoctrine ||
      TechnologyId.steel ||
      TechnologyId.nationalism ||
      TechnologyId.flight => TechBranch.military,
      TechnologyId.agriculture ||
      TechnologyId.animalHusbandry ||
      TechnologyId.fishing ||
      TechnologyId.storage ||
      TechnologyId.waterEngineering ||
      TechnologyId.navigation ||
      TechnologyId.irrigation ||
      TechnologyId.construction ||
      TechnologyId.administration ||
      TechnologyId.shipbuilding ||
      TechnologyId.urbanization ||
      TechnologyId.medicine ||
      TechnologyId.cartography ||
      TechnologyId.urbanPlanning => TechBranch.expansion,
      TechnologyId.mining ||
      TechnologyId.woodworking ||
      TechnologyId.craftsmanship ||
      TechnologyId.trade ||
      TechnologyId.stoneworking ||
      TechnologyId.advancedTrade ||
      TechnologyId.banking ||
      TechnologyId.engineering ||
      TechnologyId.metallurgy ||
      TechnologyId.ironWorking ||
      TechnologyId.coalMining ||
      TechnologyId.machinery ||
      TechnologyId.economy ||
      TechnologyId.guilds ||
      TechnologyId.steamPower ||
      TechnologyId.electricity ||
      TechnologyId.combustion ||
      TechnologyId.massProduction => TechBranch.economy,
      TechnologyId.specialization ||
      TechnologyId.writing ||
      TechnologyId.mathematics ||
      TechnologyId.civilService ||
      TechnologyId.law ||
      TechnologyId.education ||
      TechnologyId.bureaucracy ||
      TechnologyId.scientificMethod ||
      TechnologyId.radio ||
      TechnologyId.nuclearPhysics => TechBranch.science,
    };
  }

  bool isMilitaryTechnology(TechnologyId id) {
    return branchFor(id) == TechBranch.military;
  }

  bool isGoldTechnology(TechnologyId id) {
    return switch (id) {
      TechnologyId.trade ||
      TechnologyId.advancedTrade ||
      TechnologyId.banking ||
      TechnologyId.economy ||
      TechnologyId.guilds => true,
      _ => false,
    };
  }

  bool isExpansionTechnology(TechnologyId id) {
    return branchFor(id) == TechBranch.expansion;
  }

  bool isWorkerEnablingTechnology(TechnologyId id) {
    return switch (id) {
      TechnologyId.agriculture ||
      TechnologyId.mining ||
      TechnologyId.hunting ||
      TechnologyId.animalHusbandry ||
      TechnologyId.fishing ||
      TechnologyId.woodworking ||
      TechnologyId.stoneworking => true,
      _ => false,
    };
  }

  bool isCoastalTechnology(TechnologyDefinition definition) {
    return definition.id == TechnologyId.fishing ||
        definition.id == TechnologyId.navigation ||
        definition.id == TechnologyId.shipbuilding ||
        definition.id == TechnologyId.navalDoctrine ||
        definition.unlocks.any(
          (unlock) =>
              (unlock is UnlockFieldImprovement &&
                  (unlock.improvementType ==
                          FieldImprovementType.fishingBoats ||
                      unlock.improvementType ==
                          FieldImprovementType.pearlDivers)) ||
              (unlock is UnlockUnitType &&
                  (unlock.unitType == GameUnitType.scoutShip ||
                      unlock.unitType == GameUnitType.warship)),
        );
  }
}
