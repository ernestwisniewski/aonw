part of 'save_snapshot_test.dart';

void _registerSaveSnapshotTurnStartTests() {
  test('metadata and camera updates preserve a sparse implicit turn start', () {
    for (final materializeCanonical in [false, true]) {
      final snapshot = SaveSnapshot(
        save: _save().copyWith(
          gameMode: GameMode.multiplayer,
          players: const [],
        ),
      );
      final originalTurnStartedAt = snapshot.save.savedAt;
      if (materializeCanonical) {
        expect(snapshot.canonical.session.turnStartedAt, originalTurnStartedAt);
      }

      final timestampUpdated = snapshot.withSavedAt(DateTime.utc(2026, 1, 2));
      final cameraUpdated = timestampUpdated.withCamera(
        const CameraState(x: 12, y: 34, zoom: 2),
        savedAt: DateTime.utc(2026, 1, 3),
      );

      expect(
        timestampUpdated.session.turnStartedAt,
        originalTurnStartedAt,
        reason: 'materializeCanonical=$materializeCanonical',
      );
      expect(
        cameraUpdated.session.turnStartedAt,
        originalTurnStartedAt,
        reason: 'materializeCanonical=$materializeCanonical',
      );
      expect(timestampUpdated.metadata.savedAtUtc, DateTime.utc(2026, 1, 2));
      expect(cameraUpdated.metadata.savedAtUtc, DateTime.utc(2026, 1, 3));
      expect(
        cameraUpdated.metadata.camera,
        const GameSnapshotCamera(x: 12, y: 34, zoom: 2),
      );
      expect(timestampUpdated.persistedTurnStartedAt, isNull);
      expect(cameraUpdated.persistedTurnStartedAt, isNull);
      expect(
        timestampUpdated.rawPersistentState.runtimeState.toJson().containsKey(
          'turnStartedAt',
        ),
        isFalse,
      );
      expect(
        cameraUpdated.rawPersistentState.runtimeState.toJson().containsKey(
          'turnStartedAt',
        ),
        isFalse,
      );
      expect(timestampUpdated.rawPersistentState, snapshot.rawPersistentState);
      expect(cameraUpdated.rawPersistentState, snapshot.rawPersistentState);
    }
  });

  test('real turn and mode changes recompute sparse implicit turn start', () {
    for (final materializeCanonical in [false, true]) {
      final snapshot = SaveSnapshot(
        save: _save().copyWith(
          gameMode: GameMode.multiplayer,
          players: const [],
        ),
      );
      if (materializeCanonical) {
        expect(snapshot.canonical.session.turnStartedAt, snapshot.save.savedAt);
      }
      final nextSavedAt = DateTime.utc(2026, 1, 4);

      final turnChanged = snapshot.copyWith(
        save: snapshot.save.copyWith(turn: 2, savedAt: nextSavedAt),
      );
      final modeChanged = snapshot.copyWith(
        save: snapshot.save.copyWith(
          gameMode: GameMode.hotSeat,
          savedAt: nextSavedAt,
        ),
      );

      expect(
        turnChanged.session.turnStartedAt,
        nextSavedAt,
        reason: 'materializeCanonical=$materializeCanonical',
      );
      expect(
        modeChanged.session.turnStartedAt,
        isNull,
        reason: 'materializeCanonical=$materializeCanonical',
      );
      expect(turnChanged.persistedTurnStartedAt, isNull);
      expect(modeChanged.persistedTurnStartedAt, isNull);
    }
  });
}
