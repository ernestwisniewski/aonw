import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strategic production command serialization', () {
    test('round-trips an explicit resource option', () {
      const original = StartUnitProductionCommand(
        'city-7',
        GameUnitType.reconPlane,
        resourceOptionIndex: 1,
      );

      final restored = DomainCommandCodec.fromJson(
        DomainCommandCodec.toJson(original),
      );

      expect(restored, original);
    });

    test('encodes only an explicitly selected resource option', () {
      final defaultJson = DomainCommandCodec.toJson(
        const StartUnitProductionCommand('city-1', GameUnitType.warrior),
      );
      final selectedJson = DomainCommandCodec.toJson(
        const StartUnitProductionCommand(
          'city-1',
          GameUnitType.reconPlane,
          resourceOptionIndex: 1,
        ),
      );

      expect(defaultJson.containsKey('resourceOptionIndex'), isFalse);
      expect(selectedJson['resourceOptionIndex'], 1);
    });
  });
}
