part of '../game_renderer_keyboard_test.dart';

void _registerRendererActionPaletteTargetConfirmationScenarios() {
  test('move preview pill confirms the selected target', () async {
    final map = kbMap(3, 2);
    final commands = <GameIntent>[];
    final commander = GameUnit.produced(
      id: 'commander_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.commander,
      col: 0,
      row: 0,
    );
    final preview = UnitMovementPlan(
      unitId: 'commander_1',
      targetCol: 1,
      targetRow: 0,
      totalCost: 1,
      availableMovementUnits: 2,
      steps: [
        const UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        const UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
    );
    final game = GameRenderer(
      mapData: map,
      onCommand: (command) async => commands.add(command),
    );
    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [commander],
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: kbTile(map, 0, 0)),
          movePreview: preview,
          moveCommandActive: true,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    game.update(0);

    final popup = game.movePreviewPillForTesting;
    expect(game.actionPaletteVisibleForTesting, isTrue);
    expect(game.actionPaletteComponentForTesting, isNull);
    expect(popup, isNotNull);
    expect(popup!.labelForTesting, 'Confirm (1 turn)');
    _expectVectorClose(popup.position, UnitMarkerLayer.worldPositionFor(1, 0));

    popup.tapForTesting();
    await Future<void>.delayed(Duration.zero);

    expect(commands, [const TileTappedCommand(1, 0)]);
  });
  test(
    'move preview pill includes current progress and artifact movement cap',
    () async {
      final map = kbMap(4, 2);
      final commands = <GameIntent>[];
      final warrior = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWithCarriedArtifact('artifact_1');
      final preview = UnitMovementPlan(
        unitId: 'warrior_1',
        targetCol: 3,
        targetRow: 0,
        totalCost: 8,
        availableMovementUnits: 1,
        steps: _artifactCarrierPreviewSteps,
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      await gameRendererFlameTester.initializeWithState(
        game,
        GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          units: [warrior],
          interaction: InteractionState(
            selection: GameSelection.tile(kbTile(map, 1, 0)),
            movePreview: preview,
            moveCommandActive: true,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      game.update(0);

      final popup = game.movePreviewPillForTesting;
      expect(game.actionPaletteVisibleForTesting, isTrue);
      expect(popup, isNotNull);
      expect(popup!.labelForTesting, '3 turns');

      popup.tapForTesting();
      await Future<void>.delayed(Duration.zero);

      expect(commands, isEmpty);
    },
  );
  test(
    'city founding waits for selected hexes before showing confirmation',
    () async {
      final map = kbMap(3, 3);
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 1,
        row: 1,
      );
      final draft = CityFoundingDraft(
        unitId: 'settler_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 1, row: 1),
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      await gameRendererFlameTester.initializeWithState(
        game,
        GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          units: [settler],
          interaction: InteractionState(
            selection: GameSelection.unit(settler, tile: kbTile(map, 1, 1)),
            cityFoundingDraft: draft,
          ),
        ),
      );

      expect(game.actionPaletteVisibleForTesting, isFalse);
    },
  );
  test(
    'city founding does not use the map action palette for confirmation',
    () async {
      final map = kbMap(3, 3);
      final settler = GameUnit.produced(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 1,
        row: 1,
      );
      final draft = CityFoundingDraft(
        unitId: 'settler_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 1, row: 1),
        controlledHexes: const [
          CityHex(col: 1, row: 0),
          CityHex(col: 2, row: 1),
        ],
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      await gameRendererFlameTester.initializeWithState(
        game,
        GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          units: [settler],
          interaction: InteractionState(
            selection: GameSelection.unit(settler, tile: kbTile(map, 1, 1)),
            cityFoundingDraft: draft,
          ),
        ),
      );

      expect(game.actionPaletteVisibleForTesting, isFalse);
      expect(game.actionPaletteComponentForTesting, isNull);
      expect(game.actionPalettePositionForTesting, isNull);
    },
  );
  test('worker action palette dispatches preview and confirm', () async {
    final map = kbMap(3, 2);
    final commands = <GameIntent>[];
    final worker = GameUnit.produced(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      col: 1,
      row: 0,
    );
    final game = GameRenderer(
      mapData: map,
      workerActionPaletteOptionsBuilder:
          ({
            required state,
            required worker,
            required pendingAction,
            required mapData,
          }) => const [
            ActionPaletteOption(
              id: 'farm',
              iconAtlasRow: 0,
              iconAtlasColumn: 0,
              label: 'Farm',
              yieldChips: [
                ActionPaletteYieldChip(
                  kind: ActionPaletteYieldKind.food,
                  value: 1,
                ),
              ],
              turns: 2,
              state: ActionPaletteOptionState.available,
              ctaLabel: 'ZBUDUJ',
            ),
          ],
      onCommand: (command) async => commands.add(command),
    );
    GameClientState state({FieldImprovementType? improvementType}) =>
        GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          units: [worker],
          interaction: InteractionState(
            selection: GameSelection.unit(worker, tile: kbTile(map, 1, 0)),
            pendingAction: PendingWorkerActionSelection(
              ownerPlayerId: 'player_1',
              unitId: 'worker_1',
              improvementType: improvementType,
            ),
          ),
        );

    await gameRendererFlameTester.initializeWithState(game, state());

    game.actionPaletteComponentForTesting?.tapOptionForTesting('farm');
    await Future<void>.delayed(Duration.zero);

    expect(commands, [
      const ChooseWorkerImprovementIntent(
        'worker_1',
        FieldImprovementType.farm,
      ),
    ]);

    game
      ..applyState(state(improvementType: FieldImprovementType.farm))
      ..actionPaletteComponentForTesting?.tapCtaForTesting();
    await Future<void>.delayed(Duration.zero);

    expect(commands.last, const ConfirmWorkerImprovementIntent('worker_1'));
  });
  test('worker action palette keeps blocked options local', () async {
    final map = kbMap(3, 2);
    final commands = <GameIntent>[];
    final worker = GameUnit.produced(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      col: 1,
      row: 0,
    );
    final game = GameRenderer(
      mapData: map,
      workerActionPaletteOptionsBuilder:
          ({
            required state,
            required worker,
            required pendingAction,
            required mapData,
          }) => const [
            ActionPaletteOption(
              id: 'mine',
              iconAtlasRow: 0,
              iconAtlasColumn: 0,
              label: 'Mine',
              yieldChips: [],
              turns: 3,
              state: ActionPaletteOptionState.blocked,
              ctaLabel: 'ZBUDUJ',
              blockedReason: 'Requires hills',
            ),
          ],
      onCommand: (command) async => commands.add(command),
    );
    await gameRendererFlameTester.initializeWithState(
      game,
      GameClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [worker],
        interaction: InteractionState(
          selection: GameSelection.unit(worker, tile: kbTile(map, 1, 0)),
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      ),
    );

    game.actionPaletteComponentForTesting?.tapOptionForTesting('mine');
    await Future<void>.delayed(Duration.zero);

    expect(commands, isEmpty);
    expect(
      game.actionPaletteComponentForTesting?.tooltipMessageForTesting,
      'Requires hills',
    );
  });
}
