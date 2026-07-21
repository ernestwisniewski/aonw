part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerSnapshotTests() {
  group('DecodedMatchSnapshot canonical cache', () {
    test('memoizes the canonical snapshot', () {
      final decoded = DecodedMatchSnapshot(
        _save(),
        const PersistentGameState(),
        7,
      );

      final canonical = decoded.toCanonical();

      expect(identical(decoded.toCanonical(), canonical), isTrue);
      expect(canonical.eventLogOffset, 7);
    });

    test('withState creates a fresh cache for submitted state', () {
      final decoded = DecodedMatchSnapshot(
        _save(),
        const PersistentGameState(),
        7,
      );
      final canonical = decoded.toCanonical();
      final submittedState = decoded.state.copyWith(
        runtimeState: decoded.state.runtimeState.copyWith(
          submittedPlayerIds: const {'player_1'},
        ),
      );

      final refreshed = decoded.withState(submittedState).toCanonical();

      expect(identical(refreshed, canonical), isFalse);
      expect(canonical.session.submittedPlayerIds, isEmpty);
      expect(refreshed.session.submittedPlayerIds, {'player_1'});
    });
  });
}
