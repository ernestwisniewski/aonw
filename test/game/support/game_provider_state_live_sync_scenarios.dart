part of '../game_providers_test.dart';

void _registerGameStateNotifierLiveSyncScenarios() {
  group('GameStateNotifier: live sync', () {
    setUp(LiveEventSubscription.resetLocalCommandEchoGuardForTesting);
    test(
      'does not synthesize movement animation from snapshot-only direct deltas',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
        final moved = commander.copyWith(col: 1, row: 0);
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = _FakeGameRepository(
          snapshots: {
            save.id: _makeSnapshot(save: save, units: [commander]),
          },
        );
        final fakeStream = _FakeMultiplayerStream();
        final renderer = _SpyGameRenderer(mapData: _makeLandMap());
        final container = _liveMovementContainer(
          save: save,
          gameRepository: gameRepository,
          fakeStream: fakeStream,
          renderer: renderer,
        );
        addTearDown(container.dispose);

        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened.timeout(const Duration(seconds: 1));

        final snapshot = _makeSnapshot(
          save: save,
          units: [moved],
          eventLogOffset: 1,
        );
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'server_1',
            matchId: save.id,
            offset: 1,
            snapshot: const SnapshotCodec().toWire(
              matchId: save.id,
              snapshot: snapshot,
            ),
          ),
        );

        await _waitFor(() {
          final state = container.read(gameStateProvider(save.id)).value;
          return state?.units.single.col == 1;
        });

        expect(
          renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
          isEmpty,
        );
      },
    );
    test('refreshes save metadata after live multiplayer snapshots', () async {
      final save = _makeSave(
        players: const [_player1, _player2],
        gameMode: GameMode.multiplayer,
      );
      final advancedSave = save.copyWith(
        turn: 2,
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: _makeSnapshot(save: save)},
      );
      final fakeStream = _FakeMultiplayerStream();
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          multiplayerStreamConnectorProvider.overrideWithValue(
            fakeStream.connector,
          ),
          networkSessionProvider.overrideWithValue(
            api.NetworkSession(
              userId: 'user_1',
              playerId: 'player_1',
              token: AuthToken('jwt-token'),
              matchId: save.id,
              connectionState: const NetworkConnectionState(
                status: NetworkConnectionStatus.connected,
              ),
            ),
          ),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);
      final saveSubscription = container.listen(
        gameSaveProvider(save.id),
        (_, _) {},
      );
      addTearDown(saveSubscription.close);
      final stateSubscription = container.listen(
        gameStateProvider(save.id),
        (_, _) {},
      );
      addTearDown(stateSubscription.close);

      await container.read(gameSaveProvider(save.id).future);
      await container.read(gameStateProvider(save.id).future);
      await fakeStream.listened.timeout(const Duration(seconds: 1));
      gameRepository.snapshots[save.id] = _makeSnapshot(
        save: advancedSave,
        eventLogOffset: 1,
      );
      fakeStream.add(
        sp.MultiplayerServerMessage(
          serverMessageId: 'server_1',
          matchId: save.id,
          offset: 1,
          event: const EventCodec().toWire(
            matchId: save.id,
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 27, 12),
            actorPlayerId: 'player_2',
            command: const SubmitTurnCommand('player_2'),
            events: [
              AllPlayersSubmittedEvent(
                turn: 1,
                playerIds: ['player_1', 'player_2'],
              ),
            ],
          ),
        ),
      );

      await _waitFor(() {
        return container.read(gameSaveProvider(save.id)).value?.turn == 2;
      });
    });
    test(
      'marks multiplayer session reconnecting when live stream closes',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = _FakeGameRepository(
          snapshots: {save.id: _makeSnapshot(save: save)},
        );
        final fakeStream = _FakeMultiplayerStream();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            multiplayerStreamConnectorProvider.overrideWithValue(
              fakeStream.connector,
            ),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(networkSessionStateProvider.notifier)
            .set(
              api.NetworkSession(
                userId: 'user_1',
                playerId: 'player_1',
                token: AuthToken('jwt-token'),
                matchId: save.id,
                connectionState: const NetworkConnectionState(
                  status: NetworkConnectionStatus.connected,
                ),
              ),
            );

        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened.timeout(const Duration(seconds: 1));

        await fakeStream.close();

        await _waitFor(() {
          return container.read(multiplayerConnectionStatusProvider)?.status ==
              NetworkConnectionStatus.reconnecting;
        });
        expect(
          container.read(multiplayerConnectionStatusProvider)?.message,
          'Live event stream reconnecting',
        );
      },
    );
    test('dispatch updates provider state and persists the snapshot', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _makeSave(players: const [_player1]);
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(
              mapData: _makeLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gameStateProvider('save_1').future);
      final notifier = container.read(gameStateProvider('save_1').notifier);

      await notifier.syncActivePlayer(playerId: 'player_1', canAct: true);

      final uiEffects = await notifier.dispatch(
        MoveUnitCommand(commander.id, 1, 0),
      );

      final state = container.read(gameStateProvider('save_1')).value!;
      expect(state.units.single.col, 1);
      expect(gameRepository.snapshots[save.id]!.units.single.col, 1);
      expect(uiEffects, isEmpty);
    });
    _registerAtomicEndTurnProviderCase();
    test(
      'serializes concurrent local dispatches before event log writes',
      () async {
        final save = _makeSave(players: const [_player1]);
        final gameRepository = _FakeGameRepository(
          snapshots: {save.id: _makeSnapshot(save: save)},
        );
        final eventLog = _TrackedEventLog();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap(), gameMode: GameMode.hotSeat),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            eventLogProvider.overrideWithValue(eventLog),
            snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(subscription.close);

        await container.read(gameStateProvider(save.id).future);
        final notifier = container.read(gameStateProvider(save.id).notifier);

        await Future.wait([
          notifier.dispatch(const EndTurnCommand('player_1')),
          notifier.dispatch(const EndTurnCommand('player_1')),
          notifier.dispatch(const EndTurnCommand('player_1')),
        ]);

        expect(eventLog.maxConcurrentOperations, 1);
        expect(eventLog.commands.map((command) => command.offset), [1, 2, 3]);
        expect(
          eventLog.commands.map((command) => command.command),
          everyElement(isA<EndTurnCommand>()),
        );
      },
    );
  });
}
