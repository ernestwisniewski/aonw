part of 'local_command_transport_test.dart';

void _registerUnitActionTransportTests() {
  test(
    'unit action transport preserves canonical lifecycle at new offset',
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
      final baseSnapshot = GameSnapshotFactory.create(
        save: _save(
          players: const [
            Player(id: 'player_1', name: 'One', colorValue: 0xFF010203),
            Player(id: 'player_2', name: 'Two', colorValue: 0xFF020304),
            Player(id: 'player_3', name: 'Three', colorValue: 0xFF030405),
            Player(id: 'player_4', name: 'Four', colorValue: 0xFF040506),
            Player(id: 'player_5', name: 'Five', colorValue: 0xFF050607),
            Player(
              id: 'player_6',
              name: 'Six',
              colorValue: 0xFF060708,
              country: PlayerCountry.canada,
            ),
          ],
          gameMode: GameMode.multiplayer,
          playerStates: const {'player_1': PlayerTurnState.active},
        ),
        units: [unit],

        submittedPlayerIds: const {'player_2'},
        timeoutStreaksByPlayerId: const {'player_3': 2},
        afkPlayerIds: const {'player_4'},
        kickedPlayerIds: const {'player_5'},

        eventLogOffset: 73,
      );
      final before = SaveSnapshotCodec.toJson(baseSnapshot);
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
        currentState: baseSnapshot.toClientState(activePlayerId: 'player_1'),
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
      expect(snapshot.eventLogOffset, 74);
      expect(snapshot.domain.submittedPlayerIds, {'player_2'});
      expect(snapshot.domain.timeoutStreaksByPlayerId, {'player_3': 2});
      expect(snapshot.domain.afkPlayerIds, {'player_4'});
      expect(snapshot.domain.kickedPlayerIds, {'player_5'});
      expect(snapshot.domain.turnStartedAt, isNull);
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
  (copy['lifecycle'] as Map<String, dynamic>)
    ..remove('cityFoundingDraft')
    ..remove('pendingAction');
  return jsonEncode(copy);
}
