part of '../game_providers_test.dart';

void _registerGameStateNotifierDispatchScenarios() {
  group('GameStateNotifier: dispatch', () {
    setUp(LiveEventSubscription.resetLocalCommandEchoGuardForTesting);
    test(
      'uses network transport for a connected multiplayer session',
      () async {
        final fixture = _createLiveCommandFixture();
        final commander = fixture.commander;
        final save = fixture.save;
        final container = fixture.container;
        final fakeStream = fixture.stream;
        final snapshotStore = fixture.snapshotStore;
        const eventCodec = EventCodec();
        const snapshotCodec = SnapshotCodec();
        await fixture.bootstrap();
        await Future<void>.delayed(Duration.zero);
        expect(fixture.fallbackCommands.value, 0);

        final pendingResult = container
            .read(gameCommandControllerProvider.notifier)
            .dispatchTransition(MoveUnitCommand(commander.id, 1, 0));
        await waitForGameProviderCondition(
          () =>
              fakeStream.clientMessages.isNotEmpty ||
              fixture.fallbackCommands.value > 0,
        );
        expect(fixture.fallbackCommands.value, 0);

        final sent = fakeStream.clientMessages.single;
        expect(sent.lastSeenOffset, 0);
        final wire = sent.command!;
        expect(wire.actorPlayerId, 'player_1');
        expect(wire.command['type'], 'MoveUnit');
        final moved = commander.copyWith(col: 1, row: 0, movementPoints: 2);
        final serverState = GameClientState(
          units: [moved],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final snapshot = GameSnapshotFactory.fromClientState(
          save: save,
          state: serverState,
          eventLogOffset: 4,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'ack-4',
            matchId: save.id,
            offset: 4,
            ack: WireCommandAck(
              matchId: wire.matchId,
              clientMessageId: sent.clientMessageId,
              accepted: true,
              offset: 4,
              snapshot: snapshotCodec.toWire(
                matchId: wire.matchId,
                snapshot: snapshot,
              ),
              events: eventCodec.eventsToJsonList(const [
                UnitMovedEvent(
                  unitId: 'commander_player_1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ]),
              movementExecutions: WireMovementExecutionList(const []),
            ),
          ),
        );
        final result = await pendingResult;

        expect(result.state.units.single.col, 1);
        expect(result.events.single, isA<UnitMovedEvent>());
        expect(
          snapshotStore.saveIds.single,
          multiplayerSnapshotCacheKey(userId: 'user_1', matchId: save.id),
        );
        expect(snapshotStore.snapshots.single.offset, 4);
        expect(snapshotStore.snapshots.single.state.units.single.col, 1);
      },
    );
    test(
      'ignores local live command echoes while waiting for the ACK',
      () async {
        final fixture = _createLiveCommandFixture();
        final commander = fixture.commander;
        final save = fixture.save;
        final container = fixture.container;
        final fakeStream = fixture.stream;
        final renderer = fixture.renderer;
        final snapshotStore = fixture.snapshotStore;
        const eventCodec = EventCodec();
        const snapshotCodec = SnapshotCodec();
        await fixture.bootstrap();

        final pendingResult = container
            .read(gameCommandControllerProvider.notifier)
            .dispatchTransition(MoveUnitCommand(commander.id, 1, 0));
        await waitForGameProviderCondition(
          () => fakeStream.clientMessages.isNotEmpty,
        );

        final sent = fakeStream.clientMessages.single;
        final wire = sent.command!;
        final moved = commander.copyWith(col: 1, row: 0, movementPoints: 2);
        final serverState = GameClientState(
          units: [moved],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );
        final snapshot = GameSnapshotFactory.fromClientState(
          save: save,
          state: serverState,
          eventLogOffset: 4,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'echo-4',
            matchId: save.id,
            offset: 4,
            snapshot: snapshotCodec.toWire(
              matchId: save.id,
              snapshot: snapshot,
            ),
            event: eventCodec.toWire(
              matchId: save.id,
              offset: 4,
              timestamp: DateTime.utc(2026, 4, 27, 12),
              actorPlayerId: wire.actorPlayerId,
              tick: wire.tick,
              command: const MoveUnitCommand('commander_player_1', 1, 0),
              events: const [
                UnitMovedEvent(
                  unitId: 'commander_player_1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ],
            ),
          ),
        );
        await pumpEventQueue(times: 5);

        expect(
          renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
          isEmpty,
          reason: 'The local command must animate once from the ACK path only.',
        );

        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'ack-4',
            matchId: save.id,
            offset: 4,
            ack: WireCommandAck(
              matchId: wire.matchId,
              clientMessageId: sent.clientMessageId,
              accepted: true,
              offset: 4,
              snapshot: snapshotCodec.toWire(
                matchId: wire.matchId,
                snapshot: snapshot,
              ),
              events: eventCodec.eventsToJsonList(const [
                UnitMovedEvent(
                  unitId: 'commander_player_1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ]),
              movementExecutions: singleStepMovement('commander_player_1'),
            ),
          ),
        );
        final result = await pendingResult;

        expect(result.state.units.single.col, 1);
        expect(result.uiEffects.whereType<AnimateUnitMoveEffect>(), isEmpty);
        expect(result.movementExecutions, hasLength(1));
        expect(snapshotStore.snapshots.single.offset, 4);
      },
    );
    test('surfaces bootstrap load errors as AsyncError', () async {
      final gameRepository = _FakeGameRepository(throwOnLoad: true);
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameStateProvider('broken').future),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(gameStateProvider('broken')),
        isA<AsyncError<GameClientState>>(),
      );
    });
  });
}
