part of 'diplomatic_message_popup_overlay_test.dart';

void _registerDiplomaticMessagePopupTurnPhaseCases() {
  testWidgets('defers local single-player diplomacy until human planning', (
    tester,
  ) async {
    await _pumpOverlay(tester, gameSave: _localAiResolvingSave);
    await tester.pumpAndSettle();
    final container = _container(tester);
    final control = container.read(gamePlayerControlControllerProvider.notifier)
      ..selectPlayer(_localAiResolvingSave, 'player_2');
    await tester.pump();

    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.aiResolving,
    );

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsNothing);

    control.beginTurnOpening('player_2');
    await tester.pump();

    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.turnOpening,
    );
    expect(find.text('New dispatch'), findsNothing);

    await control.releaseHumanTurn('player_2');
    await tester.pump();
    await tester.pump();

    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.humanPlanning,
    );
    expect(find.text('New dispatch'), findsOneWidget);
  });

  testWidgets('blocked local response is presented again after turn opening', (
    tester,
  ) async {
    await _pumpOverlay(tester, gameSave: _localHumanPlanningSave);
    await tester.pumpAndSettle();
    final container = _container(tester);
    final control = container.read(gamePlayerControlControllerProvider.notifier)
      ..selectPlayer(_localHumanPlanningSave, 'player_2');
    await tester.pump();

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();
    expect(find.text('New dispatch'), findsOneWidget);

    control.beginTurnOpening('player_2');
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('diplomaticMessageDialog.response.neutral')),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(gamePlayerControlControllerProvider).canInteract,
      false,
    );
    expect(find.text('New dispatch'), findsNothing);
    expect(container.read(gameEventNotificationsProvider), isNotEmpty);

    await control.releaseHumanTurn('player_2');
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsOneWidget);
  });

  testWidgets('network multiplayer diplomacy presentation is unchanged', (
    tester,
  ) async {
    await _pumpOverlay(tester, gameSave: _networkMultiplayerSave);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_networkMultiplayerSave, 'player_2');
    await tester.pump();

    expect(
      container.read(gamePlayerControlControllerProvider).phase,
      LocalSinglePlayerTurnPhase.notApplicable,
    );

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsOneWidget);
  });
}

final _localHumanPlanningSave = GameSave(
  id: 'local_single_player',
  name: 'Local single-player',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 8, 20),
  camera: CameraState.zero,
  players: const [
    Player(
      id: 'player_1',
      name: 'Alice',
      colorValue: 0xFF4A7FC4,
      kind: PlayerKind.ai,
      ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 42),
    ),
    Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
  ],
  gameMode: GameMode.multiplayer,
  origin: GameSaveOrigin.local,
);

final _localAiResolvingSave = GameSave(
  id: 'local_single_player',
  name: 'Local single-player',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.finished,
  },
  savedAt: DateTime.utc(2026, 8, 20),
  camera: CameraState.zero,
  players: _localHumanPlanningSave.players,
  gameMode: GameMode.multiplayer,
  origin: GameSaveOrigin.local,
);

final _networkMultiplayerSave = GameSave(
  id: 'network_multiplayer',
  name: 'Network multiplayer',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 8, 20),
  camera: CameraState.zero,
  players: _localHumanPlanningSave.players,
  gameMode: GameMode.multiplayer,
  origin: GameSaveOrigin.network,
);
