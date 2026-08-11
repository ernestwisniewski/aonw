import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_movement_domain.dart';
import 'package:test/test.dart';

void main() {
  test('defines stable land, naval, and air movement domains', () {
    expect(UnitMovementDomain.values, [
      UnitMovementDomain.land,
      UnitMovementDomain.naval,
      UnitMovementDomain.air,
    ]);
    expect(GameUnitType.warrior.movementDomain, UnitMovementDomain.land);
    expect(GameUnitType.scoutShip.movementDomain, UnitMovementDomain.naval);
    expect(GameUnitType.reconPlane.movementDomain, UnitMovementDomain.air);
    expect(UnitMovementDomain.land.isNaval, isFalse);
    expect(UnitMovementDomain.naval.isNaval, isTrue);
    expect(UnitMovementDomain.air.isNaval, isFalse);
  });
}
