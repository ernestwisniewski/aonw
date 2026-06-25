import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_definition.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitProductionCatalog {
  static const standard = <GameUnitType, UnitProductionDefinition>{
    GameUnitType.commander: UnitProductionDefinition(
      type: GameUnitType.commander,
      productionCost: 54,
    ),
    GameUnitType.warrior: UnitProductionDefinition(
      type: GameUnitType.warrior,
      productionCost: 15,
    ),
    GameUnitType.archer: UnitProductionDefinition(
      type: GameUnitType.archer,
      productionCost: 16,
    ),
    GameUnitType.settler: UnitProductionDefinition(
      type: GameUnitType.settler,
      productionCost: 22,
    ),
    GameUnitType.worker: UnitProductionDefinition(
      type: GameUnitType.worker,
      productionCost: 14,
    ),
    GameUnitType.merchant: UnitProductionDefinition(
      type: GameUnitType.merchant,
      productionCost: 24,
    ),
    GameUnitType.scout: UnitProductionDefinition(
      type: GameUnitType.scout,
      productionCost: 12,
    ),
    GameUnitType.spearman: UnitProductionDefinition(
      type: GameUnitType.spearman,
      productionCost: 18,
    ),
    GameUnitType.cavalry: UnitProductionDefinition(
      type: GameUnitType.cavalry,
      productionCost: 38,
      requirements: [
        UnitResourceRequirement({ResourceType.horses}),
      ],
    ),
    GameUnitType.catapult: UnitProductionDefinition(
      type: GameUnitType.catapult,
      productionCost: 40,
    ),
    GameUnitType.heavyInfantry: UnitProductionDefinition(
      type: GameUnitType.heavyInfantry,
      productionCost: 46,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
    ),
    GameUnitType.fieldCannon: UnitProductionDefinition(
      type: GameUnitType.fieldCannon,
      productionCost: 58,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
    ),
    GameUnitType.rifleman: UnitProductionDefinition(
      type: GameUnitType.rifleman,
      productionCost: 52,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
    ),
    GameUnitType.tank: UnitProductionDefinition(
      type: GameUnitType.tank,
      productionCost: 84,
      requirements: [
        UnitResourceRequirement({ResourceType.oil}),
      ],
    ),
    GameUnitType.scoutShip: UnitProductionDefinition(
      type: GameUnitType.scoutShip,
      productionCost: 34,
    ),
    GameUnitType.warship: UnitProductionDefinition(
      type: GameUnitType.warship,
      productionCost: 70,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
    ),
    GameUnitType.reconPlane: UnitProductionDefinition(
      type: GameUnitType.reconPlane,
      productionCost: 62,
      requirements: [
        UnitResourceRequirement({ResourceType.aluminium, ResourceType.oil}),
      ],
    ),
  };
}
