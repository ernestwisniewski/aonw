import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartUnitProductionCommand strategic resource option', () {
    test('stores the selected option', () {
      const command = StartUnitProductionCommand(
        'city-2',
        GameUnitType.reconPlane,
        resourceOptionIndex: 1,
      );

      expect(command.cityId, 'city-2');
      expect(command.unitType, GameUnitType.reconPlane);
      expect(command.resourceOptionIndex, 1);
    });

    test('selected option participates in value equality', () {
      expect(
        const StartUnitProductionCommand(
          'c',
          GameUnitType.reconPlane,
          resourceOptionIndex: 0,
        ),
        isNot(
          const StartUnitProductionCommand(
            'c',
            GameUnitType.reconPlane,
            resourceOptionIndex: 1,
          ),
        ),
      );
    });
  });
}
