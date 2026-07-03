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
      ),
      upkeep: 1,
    );

    expect(spec, equals(spec.copyWith()));
    expect(spec.copyWith(productionCost: 20).productionCost, 20);
    expect(spec.capabilities.naval, isFalse);
  });
}
