part of 'local_command_transport_test.dart';

void _registerUnitActionTransportTests() {
  test(
    'unit action transport preserves sparse canonical session at new offset',
    () async {
      final unit = GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 3,
      );
      final baseSnapshot = SaveSnapshot(
        save: _save(
          players: const [],
          gameMode: GameMode.multiplayer,
          playerStates: const {'player_1': PlayerTurnState.active},
        ),
        playerColors: const {'player_1': 0xFF010203},
        playerCountries: const {'country_only': PlayerCountry.canada},
        units: [unit],
        runtimeState: GameRuntimeState.snapshot(
          submittedPlayerIds: const {'session_only'},
          timeoutStreaksByPlayerId: const {'timeout_only': 2},
          afkPlayerIds: const {'afk_only'},
          kickedPlayerIds: const {'kicked_only'},
        ),
        eventLogOffset: 73,
      );
      final before = SaveSnapshotCodec.toJson(baseSnapshot);
      final originalSession = baseSnapshot.session;
      final repository = _MemoryGameRepository(baseSnapshot);
      final transport = LocalCommandTransport(
        reducer: GameStateReducer(mapData: _map()),
        gameRepository: repository,
        eventLog: _MemoryEventLog(latestOffsetFloor: 73),
        snapshotStore: _MemorySnapshotStore(),
        clock: _FixedClock(DateTime.utc(2026, 7, 30, 12)),
      );

      final result = await transport.dispatch(
        saveId: baseSnapshot.save.id,
        currentState: baseSnapshot.toGameState(activePlayerId: 'player_1'),
        command: const SkipUnitTurnCommand('unit_1'),
        context: const GameCommandContext(
          actorPlayerId: 'player_1',
          commandTick: 3,
        ),
      );
      final snapshot = result.snapshot!;
      final after = SaveSnapshotCodec.toJson(snapshot);

      expect(
        _unreviewedTransportEnvelopeBytes(after),
        _unreviewedTransportEnvelopeBytes(before),
      );
      expect(result.offset, 74);
      expect(snapshot.eventLogOffset, 74);
      expect(snapshot.canonical.eventLogOffset, 74);
      expect(snapshot.session, originalSession);
      expect(snapshot.session.turnStartedAt, baseSnapshot.save.savedAt.toUtc());
      expect(snapshot.persistedTurnStartedAt, isNull);
      expect(snapshot.save.savedAt, DateTime.utc(2026, 7, 30, 12));
      expect(snapshot.units.single.movementPoints, 0);
    },
  );
}

String _unreviewedTransportEnvelopeBytes(Map<String, dynamic> source) {
  final copy = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  (copy['save'] as Map<String, dynamic>).remove('savedAt');
  copy
    ..remove('units')
    ..remove('artifacts')
    ..remove('eventLogOffset');
  (copy['runtimeState'] as Map<String, dynamic>)
    ..remove('cityFoundingDraft')
    ..remove('pendingAction');
  return jsonEncode(copy);
}
