import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_capabilities.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/game/domain/unit/unit_spec.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitCatalog {
  static const _landMilitary = UnitCapabilities(
    producibleByCities: true,
    naval: false,
    gainsExperience: true,
    military: true,
    recon: false,
  );

  static const _navalMilitary = UnitCapabilities(
    producibleByCities: true,
    naval: true,
    gainsExperience: true,
    military: true,
    recon: false,
  );

  static const _civilian = UnitCapabilities(
    producibleByCities: true,
    naval: false,
    gainsExperience: false,
    military: false,
    recon: false,
  );

  static const _landRecon = UnitCapabilities(
    producibleByCities: true,
    naval: false,
    gainsExperience: true,
    military: true,
    recon: true,
  );

  static const _navalRecon = UnitCapabilities(
    producibleByCities: true,
    naval: true,
    gainsExperience: true,
    military: true,
    recon: true,
  );

  static const standard = <GameUnitType, UnitSpec>{
    GameUnitType.commander: UnitSpec(
      type: GameUnitType.commander,
      productionCost: 54,
      baseStats: CombatStats(
        attack: 1,
        defense: 1,
        hp: 8,
        range: 1,
        mobility: 2,
      ),
      capabilities: _landMilitary,
      upkeep: 0,
      supplyCost: 0,
      scoreValue: 30,
    ),
    GameUnitType.warrior: UnitSpec(
      type: GameUnitType.warrior,
      productionCost: 15,
      baseStats: CombatStats(
        attack: 4,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 15,
    ),
    GameUnitType.archer: UnitSpec(
      type: GameUnitType.archer,
      productionCost: 16,
      baseStats: CombatStats(
        attack: 3,
        defense: 1,
        hp: 7,
        range: 2,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 17,
    ),
    GameUnitType.settler: UnitSpec(
      type: GameUnitType.settler,
      productionCost: 22,
      baseStats: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
      capabilities: _civilian,
      upkeep: 2,
      supplyCost: 1,
      scoreValue: 18,
    ),
    GameUnitType.worker: UnitSpec(
      type: GameUnitType.worker,
      productionCost: 14,
      baseStats: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
      capabilities: _civilian,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 12,
    ),
    GameUnitType.merchant: UnitSpec(
      type: GameUnitType.merchant,
      productionCost: 24,
      baseStats: CombatStats(
        attack: 0,
        defense: 1,
        hp: 1,
        range: 1,
        mobility: 1,
      ),
      capabilities: _civilian,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 14,
    ),
    GameUnitType.scout: UnitSpec(
      type: GameUnitType.scout,
      productionCost: 12,
      baseStats: CombatStats(
        attack: 1,
        defense: 1,
        hp: 5,
        range: 1,
        mobility: 3,
      ),
      capabilities: _landRecon,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 10,
    ),
    GameUnitType.spearman: UnitSpec(
      type: GameUnitType.spearman,
      productionCost: 18,
      baseStats: CombatStats(
        attack: 3,
        defense: 5,
        hp: 10,
        range: 1,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 18,
    ),
    GameUnitType.cavalry: UnitSpec(
      type: GameUnitType.cavalry,
      productionCost: 38,
      requirements: [
        UnitResourceRequirement({ResourceType.horses}),
      ],
      baseStats: CombatStats(
        attack: 6,
        defense: 3,
        hp: 10,
        range: 1,
        mobility: 3,
      ),
      capabilities: _landMilitary,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 24,
    ),
    GameUnitType.catapult: UnitSpec(
      type: GameUnitType.catapult,
      productionCost: 40,
      baseStats: CombatStats(
        attack: 7,
        defense: 1,
        hp: 7,
        range: 2,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 25,
    ),
    GameUnitType.heavyInfantry: UnitSpec(
      type: GameUnitType.heavyInfantry,
      productionCost: 46,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
      baseStats: CombatStats(
        attack: 7,
        defense: 6,
        hp: 13,
        range: 1,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 30,
    ),
    GameUnitType.fieldCannon: UnitSpec(
      type: GameUnitType.fieldCannon,
      productionCost: 58,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
      baseStats: CombatStats(
        attack: 10,
        defense: 2,
        hp: 8,
        range: 2,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 35,
    ),
    GameUnitType.rifleman: UnitSpec(
      type: GameUnitType.rifleman,
      productionCost: 52,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
      baseStats: CombatStats(
        attack: 8,
        defense: 7,
        hp: 11,
        range: 1,
        mobility: 1,
      ),
      capabilities: _landMilitary,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 38,
    ),
    GameUnitType.tank: UnitSpec(
      type: GameUnitType.tank,
      productionCost: 84,
      requirements: [
        UnitResourceRequirement({ResourceType.oil}),
      ],
      baseStats: CombatStats(
        attack: 13,
        defense: 9,
        hp: 16,
        range: 1,
        mobility: 3,
      ),
      capabilities: _landMilitary,
      upkeep: 3,
      supplyCost: 3,
      scoreValue: 50,
    ),
    GameUnitType.scoutShip: UnitSpec(
      type: GameUnitType.scoutShip,
      productionCost: 34,
      baseStats: CombatStats(
        attack: 3,
        defense: 3,
        hp: 8,
        range: 1,
        mobility: 3,
      ),
      capabilities: _navalRecon,
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 20,
    ),
    GameUnitType.warship: UnitSpec(
      type: GameUnitType.warship,
      productionCost: 70,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
      baseStats: CombatStats(
        attack: 10,
        defense: 7,
        hp: 14,
        range: 2,
        mobility: 2,
      ),
      capabilities: _navalMilitary,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 40,
    ),
    GameUnitType.reconPlane: UnitSpec(
      type: GameUnitType.reconPlane,
      productionCost: 62,
      requirements: [
        UnitResourceRequirement({ResourceType.aluminium, ResourceType.oil}),
      ],
      baseStats: CombatStats(
        attack: 1,
        defense: 3,
        hp: 6,
        range: 3,
        mobility: 5,
      ),
      capabilities: _landRecon,
      upkeep: 2,
      supplyCost: 2,
      scoreValue: 36,
    ),
  };

  static UnitSpec specFor(GameUnitType type) {
    final spec = standard[type];
    if (spec == null) {
      throw StateError('No UnitSpec registered for $type');
    }
    return spec;
  }

  static int supplyCostFor(GameUnitType type) {
    return specFor(type).supplyCost;
  }

  static int scoreValueFor(GameUnitType type) {
    return specFor(type).scoreValue;
  }

  static bool isMilitaryType(GameUnitType type) {
    return specFor(type).capabilities.military;
  }

  static bool isReconType(GameUnitType type) {
    return specFor(type).capabilities.recon;
  }
}
