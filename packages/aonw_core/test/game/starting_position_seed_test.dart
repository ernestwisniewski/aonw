import 'package:aonw_core/game/domain/unit/starting_position_seed.dart';
import 'package:test/test.dart';

void main() {
  group('StartingPositionSeed', () {
    test('keeps an empty input at the neutral seed', () {
      expect(StartingPositionSeed.fromParts(const []), 0);
    });

    test('canonically mixes supported values into a deterministic seed', () {
      final localInstant = DateTime(2026, 7, 15, 10, 30);
      final instantUtc = localInstant.toUtc();
      final parts = <Object?>[
        null,
        42,
        instantUtc,
        'opening',
        const _StableValue('player_1'),
      ];

      final seed = StartingPositionSeed.fromParts(parts);

      expect(
        seed,
        StartingPositionSeed.fromParts([
          null,
          42,
          localInstant,
          'opening',
          const _StableValue('player_1'),
        ]),
      );
      expect(
        seed,
        isNot(
          StartingPositionSeed.fromParts([
            null,
            42,
            instantUtc,
            'opening',
            const _StableValue('player_2'),
          ]),
        ),
      );
    });
  });
}

final class _StableValue {
  const _StableValue(this.value);

  final String value;

  @override
  String toString() => value;
}
