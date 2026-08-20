part of 'game_command_test.dart';

void _runCommandEqualityTailScenarios() {
  test('different command types with same data are not equal', () {
    // e.g. SelectUnitCommand and SelectCityCommand both take a String
    // but must not be equal to each other.
    expect(
      const SelectUnitCommand('x'),
      isNot(equals(const SelectCityCommand('x'))),
    );
  });
  test('equal commands have equal hashCodes', () {
    expect(
      const TileTappedCommand(1, 2).hashCode,
      equals(const TileTappedCommand(1, 2).hashCode),
    );
    expect(
      const ToggleMoveTargetingCommand().hashCode,
      equals(const ToggleMoveTargetingCommand().hashCode),
    );
  });
}
