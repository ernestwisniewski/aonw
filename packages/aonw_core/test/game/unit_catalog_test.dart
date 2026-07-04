import 'package:aonw_core/game/domain/combat/combat_ruleset.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_catalog.dart';
import 'package:aonw_core/game/domain/unit/unit_production_catalog.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:test/test.dart';

void main() {
  test('UnitCatalog matches legacy sources for every unit type', () {
    expect(UnitCatalog.standard.keys, unorderedEquals(GameUnitType.values));
    _expectCompleteTruthTable(_producibleByCities, reason: 'producible table');
    _expectCompleteTruthTable(_naval, reason: 'naval table');
    _expectCompleteTruthTable(_gainsExperience, reason: 'experience table');
    _expectCompleteTruthTable(_upkeep, reason: 'upkeep table');

    for (final type in GameUnitType.values) {
      final spec = UnitCatalog.specFor(type);
      final legacyProduction = UnitProductionCatalog.standard[type]!;

      expect(spec.type, type, reason: '$type type');
      expect(
        spec.productionCost,
        legacyProduction.productionCost,
        reason: '$type cost',
      );
      _expectRequirements(
        spec.requirements,
        legacyProduction.requirements,
        reason: '$type requirements',
      );
      expect(
        spec.baseStats,
        CombatRuleset.standard.baseStatsFor(type),
        reason: '$type stats',
      );
      expect(
        spec.capabilities.producibleByCities,
        _producibleByCities[type],
        reason: '$type producible',
      );
      expect(spec.capabilities.naval, _naval[type], reason: '$type naval');
      expect(
        spec.capabilities.gainsExperience,
        _gainsExperience[type],
        reason: '$type experience',
      );
      expect(spec.upkeep, _upkeep[type], reason: '$type upkeep');
    }
  });

  test('rifleman anchors the line while field cannon stays standoff', () {
    final rifleman = UnitCatalog.specFor(GameUnitType.rifleman);
    final fieldCannon = UnitCatalog.specFor(GameUnitType.fieldCannon);

    expect(rifleman.baseStats.defense, 7);
    expect(rifleman.baseStats.range, 1);
    expect(fieldCannon.baseStats.range, 2);
    expect(
      CombatRuleset.standard.baseStatsFor(GameUnitType.rifleman),
      rifleman.baseStats,
    );
  });
}

void _expectRequirements(
  List<UnitProductionRequirement> actual,
  List<UnitProductionRequirement> expected, {
  required String reason,
}) {
  expect(actual.length, expected.length, reason: reason);
  for (var i = 0; i < actual.length; i++) {
    switch ((actual[i], expected[i])) {
      case (
        UnitResourceRequirement(resources: final actualResources),
        UnitResourceRequirement(resources: final expectedResources),
      ):
        expect(actualResources, expectedResources, reason: reason);
    }
  }
}

void _expectCompleteTruthTable(
  Map<GameUnitType, Object> table, {
  required String reason,
}) {
  expect(table.keys, unorderedEquals(GameUnitType.values), reason: reason);
}

const _producibleByCities = <GameUnitType, bool>{
  GameUnitType.commander: true,
  GameUnitType.warrior: true,
  GameUnitType.archer: true,
  GameUnitType.settler: true,
  GameUnitType.worker: true,
  GameUnitType.merchant: true,
  GameUnitType.scout: true,
  GameUnitType.spearman: true,
  GameUnitType.cavalry: true,
  GameUnitType.catapult: true,
  GameUnitType.heavyInfantry: true,
  GameUnitType.fieldCannon: true,
  GameUnitType.rifleman: true,
  GameUnitType.tank: true,
  GameUnitType.scoutShip: true,
  GameUnitType.warship: true,
  GameUnitType.reconPlane: true,
};

const _naval = <GameUnitType, bool>{
  GameUnitType.commander: false,
  GameUnitType.warrior: false,
  GameUnitType.archer: false,
  GameUnitType.settler: false,
  GameUnitType.worker: false,
  GameUnitType.merchant: false,
  GameUnitType.scout: false,
  GameUnitType.spearman: false,
  GameUnitType.cavalry: false,
  GameUnitType.catapult: false,
  GameUnitType.heavyInfantry: false,
  GameUnitType.fieldCannon: false,
  GameUnitType.rifleman: false,
  GameUnitType.tank: false,
  GameUnitType.scoutShip: true,
  GameUnitType.warship: true,
  GameUnitType.reconPlane: false,
};

const _gainsExperience = <GameUnitType, bool>{
  GameUnitType.commander: true,
  GameUnitType.warrior: true,
  GameUnitType.archer: true,
  GameUnitType.settler: false,
  GameUnitType.worker: false,
  GameUnitType.merchant: false,
  GameUnitType.scout: true,
  GameUnitType.spearman: true,
  GameUnitType.cavalry: true,
  GameUnitType.catapult: true,
  GameUnitType.heavyInfantry: true,
  GameUnitType.fieldCannon: true,
  GameUnitType.rifleman: true,
  GameUnitType.tank: true,
  GameUnitType.scoutShip: true,
  GameUnitType.warship: true,
  GameUnitType.reconPlane: true,
};

const _upkeep = <GameUnitType, int>{
  GameUnitType.commander: 0,
  GameUnitType.warrior: 1,
  GameUnitType.archer: 1,
  GameUnitType.settler: 2,
  GameUnitType.worker: 1,
  GameUnitType.merchant: 1,
  GameUnitType.scout: 1,
  GameUnitType.spearman: 1,
  GameUnitType.cavalry: 2,
  GameUnitType.catapult: 2,
  GameUnitType.heavyInfantry: 2,
  GameUnitType.fieldCannon: 2,
  GameUnitType.rifleman: 2,
  GameUnitType.tank: 3,
  GameUnitType.scoutShip: 1,
  GameUnitType.warship: 2,
  GameUnitType.reconPlane: 2,
};
