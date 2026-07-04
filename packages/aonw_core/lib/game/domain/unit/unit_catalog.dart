import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_capabilities.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/game/domain/unit/unit_spec.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitCatalog {
  static const _land = UnitCapabilities(
    producibleByCities: true,
    naval: false,
    gainsExperience: true,
  );

  static const _naval = UnitCapabilities(
    producibleByCities: true,
    naval: true,
    gainsExperience: true,
  );

  static const _civilian = UnitCapabilities(
    producibleByCities: true,
    naval: false,
    gainsExperience: false,
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
      capabilities: _land,
      upkeep: 0,
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
      capabilities: _land,
      upkeep: 1,
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
      capabilities: _land,
      upkeep: 1,
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
      capabilities: _land,
      upkeep: 1,
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
      capabilities: _land,
      upkeep: 1,
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
      capabilities: _land,
      upkeep: 2,
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
      capabilities: _land,
      upkeep: 2,
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
      capabilities: _land,
      upkeep: 2,
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
      capabilities: _land,
      upkeep: 2,
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
      capabilities: _land,
      upkeep: 2,
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
      capabilities: _land,
      upkeep: 3,
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
      capabilities: _naval,
      upkeep: 1,
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
      capabilities: _naval,
      upkeep: 2,
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
      capabilities: _land,
      upkeep: 2,
    ),
  };

  static UnitSpec specFor(GameUnitType type) {
    final spec = standard[type];
    if (spec == null) {
      throw StateError('No UnitSpec registered for $type');
    }
    return spec;
  }
}
