import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'fortified unit exposes fresh movement only through manual move rules',
    () {
      final fortified = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
      ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);

      expect(UnitManualMovementRules.canStartTargeting(fortified), isTrue);
      expect(fortified.movementPoints, 0);
      expect(fortified.posture, UnitPosture.fortified);

      final prepared = UnitManualMovementRules.prepareForCommand(fortified);

      expect(prepared.posture, UnitPosture.active);
      expect(
        prepared.movementPoints,
        UnitMovementBalance.maxMovementPointsForType(fortified.type),
      );
    },
  );

  test('exhausted active unit cannot start manual movement', () {
    final exhausted = GameUnit.startingWarrior(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 0);

    expect(UnitManualMovementRules.canStartTargeting(exhausted), isFalse);
    expect(
      UnitManualMovementRules.prepareForCommand(exhausted),
      same(exhausted),
    );
  });
}
