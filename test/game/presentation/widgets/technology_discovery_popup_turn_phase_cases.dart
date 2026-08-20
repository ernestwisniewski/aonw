part of 'technology_discovery_popup_overlay_test.dart';

void _registerTechnologyDiscoveryPopupTurnPhaseCases() {
  testWidgets(
    'defers local single-player technology popup until human planning',
    (tester) async {
      await _pumpOverlay(tester, save: _localAiResolvingSave);
      await tester.pumpAndSettle();
      final container = _container(tester);
      final control = container.read(
        gamePlayerControlControllerProvider.notifier,
      );

      expect(
        container.read(gamePlayerControlControllerProvider).phase,
        LocalSinglePlayerTurnPhase.aiResolving,
      );

      _addTechnologyNotification(container, TechnologyId.agriculture);
      await tester.pump();
      await tester.pump();

      expect(find.text('Technology discovered'), findsNothing);
      expect(container.read(gameEventNotificationsProvider), isNotEmpty);

      control.beginTurnOpening('player_1');
      await tester.pump();

      expect(
        container.read(gamePlayerControlControllerProvider).phase,
        LocalSinglePlayerTurnPhase.turnOpening,
      );
      expect(find.text('Technology discovered'), findsNothing);

      await control.releaseHumanTurn('player_1');
      await tester.pump();
      await tester.pump();

      expect(
        container.read(gamePlayerControlControllerProvider).phase,
        LocalSinglePlayerTurnPhase.humanPlanning,
      );
      expect(find.text('Technology discovered'), findsOneWidget);
      expect(find.text('Agriculture'), findsOneWidget);
    },
  );

  testWidgets('defers minimized technology restore until human planning', (
    tester,
  ) async {
    await _pumpOverlay(tester, save: _localAiResolvingSave);
    await tester.pumpAndSettle();
    final container = _container(tester);
    final control = container.read(
      gamePlayerControlControllerProvider.notifier,
    );
    final entry = HudMinimizedPopupEntry(
      id: _technologyDiscoveryPopupId(
        TechnologyId.agriculture,
        saveId: _localAiResolvingSave.id,
      ),
      kind: HudMinimizedPopupKind.technologyDiscovery,
      title: 'Technology discovered',
      subtitle: 'Agriculture - Alice',
      payload: const {'playerId': 'player_1', 'technologyId': 'agriculture'},
    );

    container.read(hudMinimizedPopupsProvider.notifier)
      ..minimize(entry)
      ..requestRestore(entry.id);
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsNothing);
    expect(container.read(hudMinimizedPopupsProvider).hasEntry(entry.id), true);

    control.beginTurnOpening('player_1');
    await tester.pump();

    expect(find.text('Technology discovered'), findsNothing);
    expect(container.read(hudMinimizedPopupsProvider).hasEntry(entry.id), true);

    await control.releaseHumanTurn('player_1');
    await tester.pump();
    await tester.pump();

    expect(find.text('Technology discovered'), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(entry.id),
      false,
    );
  });
}

final _localAiResolvingSave = _save.copyWith(
  id: 'local_single_player',
  playerStates: const {
    'player_1': PlayerTurnState.finished,
    'player_2': PlayerTurnState.active,
  },
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
    Player(
      id: 'player_2',
      name: 'Bruno',
      colorValue: 0xFFB83A3A,
      kind: PlayerKind.ai,
      ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 42),
    ),
  ],
  gameMode: GameMode.multiplayer,
  origin: GameSaveOrigin.local,
);
