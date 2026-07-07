import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_capabilities.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/game/domain/unit/unit_spec.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  test('UnitSpec holds unit data and supports value equality', () {
    const spec = UnitSpec(
      type: GameUnitType.warrior,
      productionCost: 15,
      requirements: [
        UnitResourceRequirement({ResourceType.iron}),
      ],
      baseStats: CombatStats(attack: 4, defense: 3, hp: 10),
      capabilities: UnitCapabilities(
        producibleByCities: true,
        naval: false,
        gainsExperience: true,
        military: true,
        recon: false,
      ),
      upkeep: 1,
      supplyCost: 1,
      scoreValue: 15,
    );

    expect(spec, equals(spec.copyWith()));
    expect(spec.copyWith(productionCost: 20).productionCost, 20);
    expect(spec.copyWith(scoreValue: 18).scoreValue, 18);
    expect(spec.capabilities.naval, isFalse);
  });

  test('UnitProductionRequirement uses value equality for resource sets', () {
    const ironOrOil = UnitResourceRequirement({
      ResourceType.iron,
      ResourceType.oil,
    });
    const oilOrIron = UnitResourceRequirement({
      ResourceType.oil,
      ResourceType.iron,
    });

    expect(oilOrIron, ironOrOil);
    expect(oilOrIron.hashCode, ironOrOil.hashCode);
  });

  test('UnitSpec compares equivalent requirements by value', () {
    const spec = UnitSpec(
      type: GameUnitType.cavalry,
      productionCost: 35,
      requirements: [
        UnitResourceRequirement({ResourceType.horses}),
      ],
      baseStats: CombatStats(attack: 6, defense: 3, hp: 10),
      capabilities: UnitCapabilities(
        producibleByCities: true,
        naval: false,
        gainsExperience: true,
        military: true,
        recon: false,
      ),
      upkeep: 2,
      supplyCost: 1,
      scoreValue: 35,
    );
    const sameSpec = UnitSpec(
      type: GameUnitType.cavalry,
      productionCost: 35,
      requirements: [
        UnitResourceRequirement({ResourceType.horses}),
      ],
      baseStats: CombatStats(attack: 6, defense: 3, hp: 10),
      capabilities: UnitCapabilities(
        producibleByCities: true,
        naval: false,
        gainsExperience: true,
        military: true,
        recon: false,
      ),
      upkeep: 2,
      supplyCost: 1,
      scoreValue: 35,
    );

    expect(sameSpec, spec);
    expect(sameSpec.hashCode, spec.hashCode);
  });
}
