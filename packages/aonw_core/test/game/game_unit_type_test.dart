import 'package:aonw_core/game/domain/unit.dart';
import 'package:test/test.dart';

void main() {
  group('GameUnitType', () {
    test('uses stable enum tokens as default persisted names', () {
      for (final type in GameUnitType.values) {
        expect(type.defaultNameToken, type.name);
      }
    });
  });
}
