part of '../game_providers_test.dart';

void _registerGameCommandControllerScenarios() {
  group('GameCommandController', () {
    test(
      'dispatch forwards commands to active game state and returns effects',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = providerSave(players: const [player1]);
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
            ...transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);

        final effects = await container
            .read(gameCommandControllerProvider.notifier)
            .dispatch(MoveUnitCommand(commander.id, 1, 0));

        final state = container.read(gameStateProvider(save.id)).value!;
        expect(state.units.single.col, 1);
        expect(gameRepository.snapshots[save.id]!.units.single.col, 1);
        expect(effects, isEmpty);
      },
    );

    test('presentation shows HUD feedback effects', () async {
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            providerSession(mapData: providerLandMap()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(gameCommandControllerProvider.notifier)
          .presentHandoffPresentation(
            HandoffPresentation(
              command: const CancelUnitActionCommand('unit_1'),
              state: GameClientState(),
              previousState: GameClientState(),
              events: [],
              uiEffects: [
                const ShowHudFeedbackEffect(
                  title: 'City occupied',
                  body: 'Only one unit can stand in a city.',
                ),
              ],
            ),
          );

      final feedback = container.read(hudFeedbackProvider).single;
      expect(feedback.kind, HudFeedbackKind.actionBlocked);
      expect(feedback.title, 'City occupied');
    });

    test('turn-start focus renders a slower camera transition', () async {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 2,
        row: 3,
      );
      final save = providerSave(players: const [player1]);
      final gameRepository = FakeGameRepository(
        snapshots: {
          save.id: providerSnapshot(save: save, units: [commander]),
        },
      );
      final renderer = SpyRenderer(mapData: providerLandMap());
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            providerSession(mapData: providerLandMap()),
          ),
          activeGameRendererProvider.overrideWithValue(renderer),
          activeRendererViewModelProvider.overrideWithValue(
            TestRendererViewModel(renderer),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ...transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gameStateProvider(save.id).future);

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatchIntent(const FocusTurnStartActionCommand('player_1'));

      final effect = renderer.handledEffects
          .whereType<SmoothCameraEffect>()
          .single;
      expect(effect.col, 2);
      expect(effect.row, 3);
      expect(effect.duration, 0.85);
      final focus = renderer.handledEffects
          .whereType<ShowActionTargetFocusEffect>()
          .single;
      expect(focus.unitId, commander.id);
      expect(focus.col, 2);
      expect(focus.row, 3);
    });

    test(
      'next-action focus keeps the default camera transition speed',
      () async {
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 2,
          row: 3,
        );
        final save = providerSave(players: const [player1]);
        final gameRepository = FakeGameRepository(
          snapshots: {
            save.id: providerSnapshot(save: save, units: [commander]),
          },
        );
        final renderer = SpyRenderer(mapData: providerLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              providerSession(mapData: providerLandMap()),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            activeRendererViewModelProvider.overrideWithValue(
              TestRendererViewModel(renderer),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ...transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);

        await container
            .read(gameCommandControllerProvider.notifier)
            .dispatchIntent(const FocusNextPendingActionCommand('player_1'));

        final effect = renderer.handledEffects
            .whereType<SmoothCameraEffect>()
            .single;
        expect(effect.col, 2);
        expect(effect.row, 3);
        expect(effect.duration, 0.48);
      },
    );

    test(
      'dispatch logs and preserves current state when save snapshot is missing',
      () async {
        final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
        final save = providerSave(players: const [player1]);
        final gameRepository = FakeGameRepository(
          snapshots: {
            save.id: providerSnapshot(save: save, units: [commander]),
          },
        );
        final logger = FakeGameLogger();
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              providerSession(
                mapData: providerLandMap(),
                gameMode: GameMode.multiplayer,
              ),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            gameLoggerProvider.overrideWithValue(logger),
            ...transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);
        gameRepository.snapshots.clear();

        final effects = await container
            .read(gameCommandControllerProvider.notifier)
            .dispatch(MoveUnitCommand(commander.id, 1, 0));

        final state = container.read(gameStateProvider(save.id)).value!;
        expect(effects, isEmpty);
        expect(state.units.single.col, 0);
        expect(logger.warnings, hasLength(1));
        expect(logger.warnings.single.tag, 'GameCommandController');
        expect(logger.warnings.single.message, 'command dispatch failed');
      },
    );

    test(
      'saveCamera stores the current session camera through repository',
      () async {
        final save = providerSave();
        final session = providerSession();
        final renderer = _makeRenderer();
        final saves = {save.id: save};
        final gameRepository = FakeGameRepository(saves: saves);
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(session),
            activeGameRendererProvider.overrideWithValue(renderer),
            gameRepositoryProvider.overrideWithValue(gameRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(gameCommandControllerProvider.notifier)
            .saveCamera();

        final updated = saves[save.id]!;
        expect(updated.camera.zoom, 1);
        expect(updated.savedAt.isAfter(save.savedAt), isTrue);
      },
    );

    test('saveCamera skips active network matches', () async {
      final save = providerSave(gameMode: GameMode.multiplayer);
      final session = providerSession(
        saveId: save.id,
        gameMode: GameMode.multiplayer,
      );
      final renderer = _makeRenderer();
      final gameRepository = FakeGameRepository(
        snapshots: {save.id: providerSnapshot(save: save)},
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(session),
          activeGameRendererProvider.overrideWithValue(renderer),
          gameRepositoryProvider.overrideWithValue(gameRepository),
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

      await container.read(gameCommandControllerProvider.notifier).saveCamera();

      expect(gameRepository.loadCount, 0);
    });

    test(
      'focusTurnStartMapTarget shows production bubbles once per player turn',
      () async {
        final city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 1, row: 1),
          productionQueue: CityProductionQueue.project(
            projectType: CityProjectType.wealth,
          ),
        );
        final save = providerSave(turn: 4, players: const [player1]);
        final gameRepository = FakeGameRepository(
          snapshots: {
            save.id: providerSnapshot(
              save: save,
              cities: [city],
              research: ResearchState(
                players: {
                  'player_1': PlayerResearchState(
                    activeTechnologyId: TechnologyId.agriculture,
                  ),
                },
              ),
            ),
          },
        );
        final renderer = SpyRenderer(mapData: providerLandMap());
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(
              providerSession(mapData: providerLandMap()),
            ),
            activeGameRendererProvider.overrideWithValue(renderer),
            activeRendererViewModelProvider.overrideWithValue(
              TestRendererViewModel(renderer),
            ),
            gameRepositoryProvider.overrideWithValue(gameRepository),
            ...transportOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await container.read(gameStateProvider(save.id).future);
        final controller = container.read(
          gameCommandControllerProvider.notifier,
        );

        await controller.focusTurnStartMapTarget('player_1');
        await controller.focusTurnStartMapTarget('player_1');

        expect(
          renderer.handledEffects.whereType<ShowCityProductionBubbleEffect>(),
          hasLength(1),
        );
        final smoothDurations = renderer.handledEffects
            .whereType<SmoothCameraEffect>()
            .map((effect) => effect.duration)
            .toList(growable: false);
        expect(smoothDurations, isNotEmpty);
        expect(smoothDurations, everyElement(0.85));
      },
    );

    test(
      'saveCamera is a no-op when activeGameSessionProvider is null',
      () async {
        final saves = <String, GameSave>{};
        final container = ProviderContainer(
          overrides: [
            activeGameSessionProvider.overrideWithValue(null),
            gameRepositoryProvider.overrideWithValue(
              FakeGameRepository(saves: saves),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(gameCommandControllerProvider.notifier)
            .saveCamera();

        expect(saves, isEmpty);
      },
    );
  });
}
