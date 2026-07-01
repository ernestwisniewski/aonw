import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:test/test.dart';

void main() {
  test('defaults are empty', () {
    const state = PersistentGameState();

    expect(state.playerWarWeariness, isEmpty);
    expect(state.playerStabilityNet, isEmpty);
  });

  test('round-trips through json', () {
    const state = PersistentGameState(
      playerWarWeariness: {'p1': 3},
      playerStabilityNet: {'p1': -2},
    );

    final restored = PersistentGameState.fromJson(state.toJson());

    expect(restored.playerWarWeariness['p1'], 3);
    expect(restored.playerStabilityNet['p1'], -2);
  });

  test('old saves without the fields load cleanly', () {
    final restored = PersistentGameState.fromJson(const {
      'playerGold': <String, int>{},
    });

    expect(restored.playerWarWeariness, isEmpty);
    expect(restored.playerStabilityNet, isEmpty);
  });

  test('copyWith replaces the maps', () {
    const state = PersistentGameState();
    final next = state.copyWith(
      playerWarWeariness: {'p1': 5},
      playerStabilityNet: {'p1': 1},
    );

    expect(next.playerWarWeariness['p1'], 5);
    expect(next.playerStabilityNet['p1'], 1);
  });

  test('equality accounts for the new maps', () {
    const a = PersistentGameState(playerWarWeariness: {'p1': 1});
    const b = PersistentGameState(playerWarWeariness: {'p1': 2});

    expect(a == b, isFalse);
  });
}
