part of '../game_providers_test.dart';

void _registerAtomicEndTurnProviderCase() {
  test(
    'end turn persists and presents next-player queued movement once',
    () async {
      final queuedUnit = GameUnit(
        id: 'queued_unit',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 0,
        queuedPath: QueuedMovePath(
          targetCol: 1,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );
      final save = _makeSave(players: const [_player1, _player2]);
      final renderer = _SpyGameRenderer(mapData: _makeLandMap());
      final gameRepository = _FakeGameRepository(
        snapshots: {
          save.id: _makeSnapshot(save: save, units: [queuedUnit]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            _makeSession(mapData: _makeLandMap()),
          ),
          activeGameRendererProvider.overrideWithValue(renderer),
          activeRendererViewModelProvider.overrideWithValue(
            TestRendererViewModel(renderer),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ..._transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gameStateProvider(save.id).future);
      final controller = container.read(gameCommandControllerProvider.notifier);
      final presentation = await controller.dispatchForHandoffPresentation(
        const EndTurnCommand('player_1'),
      );

      final persisted = gameRepository.snapshots[save.id]!;
      expect(persisted.units.single.col, 1);
      expect(persisted.units.single.row, 0);
      expect(persisted.units.single.queuedPath, isNull);
      expect(persisted.eventLogOffset, 1);
      expect(presentation.events.whereType<TurnEndedEvent>(), hasLength(1));
      expect(presentation.events.whereType<UnitMovedEvent>(), hasLength(1));
      expect(
        presentation.uiEffects.whereType<AnimateUnitMoveEffect>(),
        isEmpty,
      );
      expect(presentation.movementExecutions, hasLength(1));
      expect(presentation.offset, 1);
      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
        isEmpty,
      );

      await controller.presentHandoffPresentation(presentation);

      final animations = renderer.handledEffects
          .whereType<AnimateUnitMoveEffect>()
          .toList();
      expect(animations, hasLength(1));
      expect(animations.single.unitId, queuedUnit.id);
      expect(animations.single.fromCol, 0);
      expect(animations.single.steps.single.col, 1);

      container.invalidate(gameStateProvider(save.id));
      final reloaded = await container.read(gameStateProvider(save.id).future);
      expect(reloaded.units.single.col, 1);
      expect(reloaded.units.single.queuedPath, isNull);
    },
  );
}
