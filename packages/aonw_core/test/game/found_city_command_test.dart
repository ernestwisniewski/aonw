import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('FoundCityCommand', () {
    test('owns an immutable controlled-hex snapshot', () {
      const hex = CityHex(col: 1, row: 0);
      final source = [hex];
      final command = FoundCityCommand('settler_1', controlledHexes: source);
      final equalSnapshot = FoundCityCommand(
        'settler_1',
        controlledHexes: const [hex],
      );
      final originalHashCode = command.hashCode;

      source.add(const CityHex(col: 0, row: 1));

      expect(command.controlledHexes, const [hex]);
      expect(command, equalSnapshot);
      expect(command.hashCode, originalHashCode);
      expect(command.controlledHexes.clear, throwsUnsupportedError);
    });

    test('round-trips a self-contained controlled-hex payload', () {
      final command = FoundCityCommand(
        'settler_1',
        controlledHexes: const [
          CityHex(col: 1, row: 0),
          CityHex(col: 0, row: 1),
        ],
      );
      final json = GameCommandSerializer.toJson(command);

      expect(json, {
        'type': 'FoundCity',
        'founderId': 'settler_1',
        'controlledHexes': [
          {'col': 1, 'row': 0},
          {'col': 0, 'row': 1},
        ],
      });
      expect(GameCommandSerializer.fromJson(json), command);
    });

    test('decodes a legacy payload without controlledHexes', () {
      expect(
        GameCommandSerializer.fromJson({
          'type': 'FoundCity',
          'founderId': 'settler_1',
        }),
        FoundCityCommand('settler_1', controlledHexes: const []),
      );
    });
  });
}
