import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder/wonder_definition.dart';
import 'package:aonw_core/game/domain/wonder/wonder_effect.dart';
import 'package:aonw_core/game/domain/wonder/wonder_requirement.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class WonderCatalog {
  static const standard = <WonderType, WonderDefinition>{
    WonderType.greatLibrary: WonderDefinition(
      type: WonderType.greatLibrary,
      productionCost: 120,
      unlockTech: TechnologyId.writing,
      standingEffects: [EmpireScienceEffect(1)],
      completionEffects: [GrantFreeTechnology()],
    ),
    WonderType.hangingGardens: WonderDefinition(
      type: WonderType.hangingGardens,
      productionCost: 120,
      unlockTech: TechnologyId.waterEngineering,
      requirements: [WonderAdjacentRiverRequirement()],
      standingEffects: [
        HostCityFlatYieldEffect(
          TileYield(food: 2, production: 0, gold: 0, defense: 0),
        ),
        EmpireFlatYieldEffect(
          TileYield(food: 1, production: 0, gold: 0, defense: 0),
        ),
      ],
    ),
    WonderType.greatWall: WonderDefinition(
      type: WonderType.greatWall,
      productionCost: 140,
      unlockTech: TechnologyId.militaryOrganization,
      standingEffects: [
        EmpireFlatYieldEffect(
          TileYield(food: 0, production: 0, gold: 0, defense: 3),
        ),
      ],
    ),
    WonderType.petra: WonderDefinition(
      type: WonderType.petra,
      productionCost: 150,
      unlockTech: TechnologyId.stoneworking,
      requirements: [
        WonderHostTerrainRequirement({TerrainType.desert}),
      ],
      standingEffects: [
        HostCityFlatYieldEffect(
          TileYield(food: 2, production: 2, gold: 1, defense: 0),
        ),
      ],
    ),
    WonderType.centralBank: WonderDefinition(
      type: WonderType.centralBank,
      productionCost: 220,
      unlockTech: TechnologyId.banking,
      standingEffects: [EmpireGoldMultiplierEffect(0.15)],
      completionEffects: [GrantGold(120)],
    ),
    WonderType.imperialUniversity: WonderDefinition(
      type: WonderType.imperialUniversity,
      productionCost: 240,
      unlockTech: TechnologyId.education,
      standingEffects: [EmpireScienceEffect(2)],
    ),
    WonderType.grandCathedral: WonderDefinition(
      type: WonderType.grandCathedral,
      productionCost: 200,
      unlockTech: TechnologyId.law,
      requirements: [
        WonderResourceRequirement({ResourceType.marble}),
      ],
      standingEffects: [StabilityEffect(4)],
    ),
    WonderType.motherFactory: WonderDefinition(
      type: WonderType.motherFactory,
      productionCost: 360,
      unlockTech: TechnologyId.steamPower,
      requirements: [
        WonderResourceRequirement({ResourceType.coal, ResourceType.iron}),
      ],
      standingEffects: [EmpireProductionMultiplierEffect(0.10)],
      completionEffects: [ProductionBurst(80)],
    ),
    WonderType.nationalObservatory: WonderDefinition(
      type: WonderType.nationalObservatory,
      productionCost: 380,
      unlockTech: TechnologyId.scientificMethod,
      requirements: [WonderAdjacentMountainRequirement()],
      standingEffects: [EmpireScienceEffect(3)],
    ),
    WonderType.svalbardSeedVault: WonderDefinition(
      type: WonderType.svalbardSeedVault,
      productionCost: 340,
      unlockTech: TechnologyId.nuclearPhysics,
      requirements: [
        WonderHostTerrainRequirement({TerrainType.snow}),
      ],
      standingEffects: [
        EmpireFlatYieldEffect(
          TileYield(food: 1, production: 0, gold: 0, defense: 0),
        ),
        StabilityEffect(3),
      ],
    ),
    WonderType.grandExposition: WonderDefinition(
      type: WonderType.grandExposition,
      productionCost: 400,
      unlockTech: TechnologyId.radio,
      standingEffects: [
        EmpireFlatYieldEffect(
          TileYield(food: 0, production: 0, gold: 2, defense: 0),
        ),
        StabilityEffect(2),
      ],
    ),
  };
}
