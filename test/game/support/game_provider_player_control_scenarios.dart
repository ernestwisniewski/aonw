part of '../game_providers_test.dart';

void _registerGamePlayerControlScenarios() {
  group('GamePlayerControlController', () {
    test('syncWithSave selects the first save player', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final save = _makeSave(players: const [_player1, _player2]);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);

      final state = container.read(gamePlayerControlControllerProvider);
      expect(state.activePlayerId, 'player_1');
      expect(state.canAct, isTrue);
    });

    test('syncWithSave mirrors active player into GameStateNotifier', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = _makeSave(players: const [_player1, _player2]);
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
      final subscription = container.listen(
        gameStateProvider('save_1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(gameStateProvider('save_1').future);

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(gameStateProvider('save_1')).value!;
      expect(state.activePlayerId, 'player_1');
      expect(state.activePlayerCanAct, isTrue);
    });

    test('selectPlayer updates control state for finished players', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final save = _makeSave(
        players: const [_player1, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .selectPlayer(save, 'player_2');

      final state = container.read(gamePlayerControlControllerProvider);
      expect(state.activePlayerId, 'player_2');
      expect(state.canAct, isFalse);
    });

    test('selectPlayer mirrors canAct into GameStateNotifier', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
      final save = _makeSave(
        players: const [_player1, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [commander]),
        },
      );
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
      final subscription = container.listen(
        gameStateProvider('save_1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container.read(gameStateProvider('save_1').future);

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .selectPlayer(save, 'player_2');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(gameStateProvider('save_1')).value!;
      expect(state.activePlayerId, 'player_2');
      expect(state.activePlayerCanAct, isFalse);
    });

    test(
      'endTurn keeps control on finished player while turn continues',
      () async {
        final save = _makeSave(players: const [_player1, _player2]);
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
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

        container
            .read(gamePlayerControlControllerProvider.notifier)
            .syncWithSave(save);
        final updated = await container
            .read(gamePlayerControlControllerProvider.notifier)
            .endTurn(save);

        expect(updated, isNotNull);
        expect(updated!.turn, 1);
        expect(updated.playerStates['player_1'], PlayerTurnState.finished);

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_1');
        expect(state.canAct, isFalse);
      },
    );

    test(
      'endTurn keeps current control until new-turn handoff is confirmed',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
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

        container
            .read(gamePlayerControlControllerProvider.notifier)
            .syncWithSave(save);
        container
            .read(gamePlayerControlControllerProvider.notifier)
            .selectPlayer(save, 'player_2');
        final updated = await container
            .read(gamePlayerControlControllerProvider.notifier)
            .endTurn(save);

        expect(updated, isNotNull);
        expect(updated!.turn, 2);

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_2');
        expect(state.canAct, isTrue);
        expect(container.read(gameHandoffProvider)?.playerId, 'player_1');
      },
    );

    test(
      'endTurn starts handoff when a hotseat session waits for another player',
      () async {
        final save = _makeSave(players: const [_player1, _player2]);
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
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

        container
            .read(gamePlayerControlControllerProvider.notifier)
            .syncWithSave(save);
        final updated = await container
            .read(gamePlayerControlControllerProvider.notifier)
            .endTurn(save);

        expect(updated, isNotNull);
        final handoff = container.read(gameHandoffProvider);
        expect(handoff?.playerId, 'player_2');
        expect(handoff?.playerName, 'Bob');
      },
    );

    test(
      'confirmHandoff reloads the latest save before selecting player',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final saves = {save.id: save};
        final gameRepository = _FakeGameRepository(saves: saves);
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
        final saveSubscription = container.listen(
          gameSaveProvider(save.id),
          (_, _) {},
        );
        addTearDown(saveSubscription.close);

        await container.read(gameSaveProvider(save.id).future);
        await container.read(gameStateProvider(save.id).future);
        final controller = container.read(
          gamePlayerControlControllerProvider.notifier,
        )..selectPlayer(save, 'player_2');

        final updated = await controller.endTurn(save);
        expect(updated?.turn, 2);
        expect(container.read(gameHandoffProvider)?.playerId, 'player_1');

        await controller.confirmHandoff('player_1');

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_1');
        expect(state.canAct, isTrue);
      },
    );

    test(
      'confirmHandoff logs repository failures instead of throwing',
      () async {
        final save = _makeSave(players: const [_player1, _player2]);
        final gameRepository = _FakeGameRepository(throwOnLoad: true);
        final logger = _FakeGameLogger();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(mapData: _makeLandMap()),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            gameLoggerProvider.overrideWithValue(logger),
            ..._transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          gamePlayerControlControllerProvider.notifier,
        )..syncWithSave(save);

        await controller.confirmHandoff('player_2');

        final state = container.read(gamePlayerControlControllerProvider);
        expect(state.activePlayerId, 'player_1');
        expect(logger.warnings, hasLength(1));
        expect(logger.warnings.single.tag, 'GamePlayerControlController');
        expect(logger.warnings.single.message, 'confirm handoff failed');
      },
    );

    test('endTurn does not start handoff in multiplayer sessions', () async {
      final save = _makeSave(players: const [_player1, _player2]);
      final saves = {save.id: save};
      final gameRepository = _FakeGameRepository(saves: saves);
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

      container
          .read(gamePlayerControlControllerProvider.notifier)
          .syncWithSave(save);
      final updated = await container
          .read(gamePlayerControlControllerProvider.notifier)
          .endTurn(save);

      expect(updated, isNotNull);
      expect(container.read(gameHandoffProvider), isNull);
    });

    test(
      'connected multiplayer endTurn reloads through the network repository',
      () async {
        final save = _makeSave(
          players: const [_player1, _player2],
          gameMode: GameMode.multiplayer,
        );
        final initialSnapshot = _makeSnapshot(save: save);
        final submittedSave = save.copyWith(
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        );
        final submittedSnapshot = _makeSnapshot(
          save: submittedSave,

          submittedPlayerIds: {'player_1'},

          eventLogOffset: 1,
        );
        final localRepository = _FakeGameRepository(throwOnLoad: true);
        final networkRepository = _FakeGameRepository(
          snapshots: {save.id: initialSnapshot},
        );
        final logger = _FakeGameLogger();
        final fakeStream = _FakeMultiplayerStream();
        final fallbackDispatcher = _FakeWireCommandDispatcher(({
          required saveId,
          required token,
          required afterOffset,
          required wire,
          required clientMessageId,
        }) async {
          throw StateError('Expected end turn to use the live match channel.');
        });
        const snapshotCodec = SnapshotCodec();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              _makeSession(
                mapData: _makeLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(localRepository),
            networkGameRepositoryProvider.overrideWithValue(networkRepository),
            gameLoggerProvider.overrideWithValue(logger),
            eventLogProvider.overrideWithValue(_FakeEventLog()),
            networkEventLogProvider.overrideWith(
              (ref) => ref.watch(eventLogProvider),
            ),
            snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
            wireCommandDispatcherProvider.overrideWithValue(fallbackDispatcher),
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
          ],
        );
        addTearDown(container.dispose);
        addTearDown(fakeStream.close);
        final gameStateSubscription = container.listen(
          gameStateProvider(save.id),
          (_, _) {},
        );
        addTearDown(gameStateSubscription.close);

        await container.read(gameStateProvider(save.id).future);
        await fakeStream.listened;
        final controller = container.read(
          gamePlayerControlControllerProvider.notifier,
        )..syncWithSave(save);

        final pendingEndTurn = controller.endTurn(save);
        await _waitFor(() => fakeStream.clientMessages.isNotEmpty);

        final wire = fakeStream.clientMessages.single.command!;
        expect(wire.command['type'], 'SubmitTurn');
        networkRepository.snapshots[save.id] = submittedSnapshot;
        fakeStream.add(
          sp.MultiplayerServerMessage(
            serverMessageId: 'submit-turn-ack',
            matchId: save.id,
            offset: 1,
            ack: WireCommandAck(
              matchId: save.id,
              accepted: true,
              offset: 1,
              snapshot: snapshotCodec.toWire(
                matchId: save.id,
                snapshot: submittedSnapshot,
              ),
              movementExecutions: WireMovementExecutionList(const []),
            ),
          ),
        );

        final updated = await pendingEndTurn;

        expect(updated, submittedSave);
        expect(localRepository.loadCount, 0);
        expect(networkRepository.loadCount, greaterThanOrEqualTo(3));
        expect(logger.warnings, isEmpty);
        final control = container.read(gamePlayerControlControllerProvider);
        expect(control.activePlayerId, 'player_1');
        expect(control.canAct, isFalse);
      },
    );

    test('endTurn does not use Ref after control provider disposal', () async {
      final save = _makeSave();
      final gate = Completer<void>();
      final saves = {save.id: save};
      final gameRepository = _FakeGameRepository(saves: saves, loadGate: gate);
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

      final notifier = container.read(
        gamePlayerControlControllerProvider.notifier,
      )..syncWithSave(save);
      final future = notifier.endTurn(save);

      container.invalidate(gamePlayerControlControllerProvider);
      gate.complete();

      final updated = await future;
      expect(updated, isNotNull);
      expect(updated!.turn, 2);
    });
  });
}
