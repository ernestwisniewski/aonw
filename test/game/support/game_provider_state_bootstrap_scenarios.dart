part of '../game_providers_test.dart';

void _registerGameStateNotifierBootstrapScenarios() {
  group('GameStateNotifier: bootstrap', () {
    setUp(LiveEventSubscription.resetLocalCommandEchoGuardForTesting);
    test('loads state from repository for the active session', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final save = providerSave(
        players: const [
          Player(id: 'player_1', name: 'Alice', colorValue: 0xFF123456),
        ],
      );
      final gameRepository = FakeGameRepository(
        snapshots: {
          save.id: providerSnapshot(
            save: save,
            units: [commander],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    HexCoordinate(col: commander.col, row: commander.row),
                  },
                ),
              },
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            providerSession(mapData: providerLandMap()),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ...transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(gameStateProvider('save_1').future);

      expect(state.playerColors, const {'player_1': 0xFF123456});
      expect(state.units, [commander]);
      expect(state.activePlayerId, 'player_1');
      expect(
        state.activePlayerVisibility.canSeeDynamicAt(
          commander.col,
          commander.row,
        ),
        isTrue,
      );
      expect(state.fogOfWar.playerIds, contains('player_1'));
    });
    test('uses network session player for multiplayer control', () async {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
      final save = providerSave(
        players: const [player1, player2],
        gameMode: GameMode.multiplayer,
      );
      final gameRepository = FakeGameRepository(
        snapshots: {
          save.id: providerSnapshot(save: save, units: [commander]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            providerSession(
              mapData: providerLandMap(),
              gameMode: GameMode.multiplayer,
            ),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          networkSessionProvider.overrideWithValue(
            api.NetworkSession(
              userId: 'user_2',
              playerId: 'player_2',
              token: AuthToken('jwt-token'),
              matchId: save.id,
              connectionState: const NetworkConnectionState(
                status: NetworkConnectionStatus.connected,
              ),
            ),
          ),
          ...transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(gameStateProvider(save.id).future);

      expect(state.activePlayerId, 'player_2');
      expect(state.selectedUnitId, commander.id);
      expect(state.canControlUnit(commander), isTrue);
    });
    test(
      'animates exact authoritative opponent movement from live snapshots',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
        final moved = commander.copyWith(col: 2, row: 0);
        final save = providerSave(
          players: const [player1, player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = FakeGameRepository(
          snapshots: {
            save.id: providerSnapshot(save: save, units: [commander]),
          },
        );
        final fakeStream = FakeMultiplayerStream();
        final renderer = SpyRenderer(mapData: providerLandMap());
        final container = liveMovementContainer(
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
        final snapshot = providerSnapshot(
          save: save,
          units: [moved],
          eventLogOffset: 1,
        );
        final message = sp.MultiplayerServerMessage(
          serverMessageId: 'server_1',
          matchId: save.id,
          offset: 1,
          snapshot: const SnapshotCodec().toWire(
            matchId: save.id,
            snapshot: snapshot,
          ),
          event: const EventCodec()
              .toWire(
                matchId: save.id,
                offset: 1,
                timestamp: DateTime.utc(2026, 4, 27, 12),
                events: const [
                  UnitMovedEvent(
                    unitId: 'commander_player_2',
                    fromCol: 0,
                    fromRow: 0,
                    toCol: 2,
                    toRow: 0,
                  ),
                ],
              )
              .copyWith(
                movementExecutions: WireMovementExecutionList([
                  WireMovementExecution(
                    unitId: 'commander_player_2',
                    fromCol: 0,
                    fromRow: 0,
                    steps: const [
                      WireMovementStep(
                        col: 1,
                        row: 0,
                        enterCost: 7,
                        cumulativeCost: 7,
                      ),
                      WireMovementStep(
                        col: 2,
                        row: 0,
                        enterCost: 13,
                        cumulativeCost: 20,
                      ),
                    ],
                  ),
                ]),
              ),
        );
        fakeStream
          ..add(message)
          ..add(message);

        await waitForGameProviderCondition(() {
          final state = container.read(gameStateProvider(save.id)).value;
          return state?.units.single.col == 2;
        });

        final state = container.read(gameStateProvider(save.id)).value!;
        final effect = renderer.handledEffects
            .whereType<AnimateUnitMoveEffect>()
            .single;
        expect(effect.unitId, 'commander_player_2');
        expect(effect.fromCol, 0);
        expect(effect.fromRow, 0);
        expect(effect.steps, hasLength(2));
        expect(
          effect.steps
              .map(
                (step) =>
                    (step.col, step.row, step.enterCost, step.cumulativeCost),
              )
              .toList(),
          [(1, 0, 7, 7), (2, 0, 13, 20)],
        );
        expect(state.units.single.queuedPath, isNull);
        expect(state.activePlayerId, 'player_1');
        expect(state.canControlUnit(state.units.single), isFalse);
      },
    );
    test(
      'does not infer opponent movement when the authoritative plan is empty',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_2');
        final moved = commander.copyWith(col: 2, row: 0);
        final save = providerSave(
          players: const [player1, player2],
          gameMode: GameMode.multiplayer,
        );
        final gameRepository = FakeGameRepository(
          snapshots: {
            save.id: providerSnapshot(save: save, units: [commander]),
          },
        );
        final fakeStream = FakeMultiplayerStream();
        final renderer = SpyRenderer(mapData: providerLandMap());
        final container = liveMovementContainer(
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

        final snapshot = providerSnapshot(
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
            event: const EventCodec().toWire(
              matchId: save.id,
              offset: 1,
              timestamp: DateTime.utc(2026, 4, 27, 12),
              events: const [],
            ),
          ),
        );

        await waitForGameProviderCondition(() {
          final state = container.read(gameStateProvider(save.id)).value;
          return state?.units.single.col == 2;
        });

        final state = container.read(gameStateProvider(save.id)).value!;
        expect(
          renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
          isEmpty,
        );
        expect(state.activePlayerId, 'player_1');
        expect(state.activePlayerCanAct, isTrue);
        expect(state.canControlUnit(state.units.single), isFalse);
      },
    );
    test('plays live combat before animating a defender retreat', () async {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_2',
        type: GameUnitType.archer,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'defender',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final retreated = defender.copyWith(col: 2, row: 0, hitPoints: 1);
      final save = providerSave(
        players: const [player1, player2],
        gameMode: GameMode.multiplayer,
      );
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      );
      final gameRepository = FakeGameRepository(
        snapshots: {
          save.id: providerSnapshot(
            save: save,
            units: [attacker, defender],
            fogOfWar: fog,
          ),
        },
      );
      final fakeStream = FakeMultiplayerStream();
      final renderer = SpyRenderer(mapData: providerLandMap());
      final audio = _RecordingAudioController();
      final container = liveMovementContainer(
        save: save,
        gameRepository: gameRepository,
        fakeStream: fakeStream,
        renderer: renderer,
        audioController: audio,
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        gameStateProvider(save.id),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(gameStateProvider(save.id).future);
      await fakeStream.listened.timeout(const Duration(seconds: 1));

      final snapshot = providerSnapshot(
        save: save,
        units: [attacker, retreated],
        fogOfWar: fog,
        eventLogOffset: 1,
      );
      final combat = CombatResolvedEvent(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        outcome: CombatOutcome(
          attackerUnitId: 'attacker',
          defenderUnitId: 'defender',
          attackerHpAfter: 7,
          defenderHpAfter: 1,
          attackerKilled: false,
          defenderKilled: false,
          defenderRetreated: true,
          steps: [AttackStep(damage: 5), RetaliationStep(damage: 1)],
        ),
      );
      fakeStream.add(
        sp.MultiplayerServerMessage(
          serverMessageId: 'combat_1',
          matchId: save.id,
          offset: 1,
          snapshot: const SnapshotCodec().toWire(
            matchId: save.id,
            snapshot: snapshot,
          ),
          event: const EventCodec().toWire(
            matchId: save.id,
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 27, 12),
            events: [combat],
          ),
        ),
      );

      await waitForGameProviderCondition(() {
        final state = container.read(gameStateProvider(save.id)).value;
        return state?.unitById('defender')?.col == 2;
      });

      final effects = renderer.handledEffects;
      final combatIndex = effects.indexWhere(
        (effect) => effect is PlayCombatAnimationEffect,
      );
      final retreatEffects = effects
          .whereType<AnimateUnitMoveEffect>()
          .where((effect) => effect.unitId == 'defender')
          .toList();
      expect(combatIndex, greaterThanOrEqualTo(0));
      expect(retreatEffects, hasLength(1));
      expect(effects.indexOf(retreatEffects.single), greaterThan(combatIndex));
      expect(retreatEffects.single.fromCol, 1);
      expect(retreatEffects.single.steps.single.col, 2);
      expect(audio.cues, contains(GameSoundCue.attack));
    });
  });
}
