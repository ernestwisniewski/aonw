part of 'multiplayer_avatars_rail_test.dart';

const _alice = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB);
const _bob = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFDC2626);
const _carol = Player(id: 'player_3', name: 'Carol', colorValue: 0xFF7C3AED);
const _cpu = Player(
  id: 'player_4',
  name: 'CPU 1',
  colorValue: 0xFFEA580C,
  kind: PlayerKind.ai,
  ai: AiPlayer(
    strategyId: AiStrategyId.random,
    difficulty: AiDifficulty.normal,
    persona: AiPersona.balanced,
    seed: 7,
  ),
);

GameSave _save({
  GameMode gameMode = GameMode.multiplayer,
  List<Player> players = const [_alice, _bob, _carol, _cpu],
  Map<String, PlayerTurnState> playerStates = const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.finished,
    'player_3': PlayerTurnState.active,
    'player_4': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    turn: 1,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 5, 5),
    camera: CameraState.zero,
    players: players,
    gameMode: gameMode,
  );
}

Future<void> _pumpRail(
  WidgetTester tester, {
  required GameSave save,
  String activePlayerId = 'player_1',
  ValueChanged<String>? onAvatarTapped,
  Map<String, String> timerLabels = const {},
  Set<String> timedOutPlayerIds = const {},
  DiplomacyState diplomacy = DiplomacyState.empty,
  GameClientState? gameState,
  Size? screenSize,
}) {
  if (screenSize != null) {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiplayerAvatarsRail(
          gameSave: save,
          activePlayerId: activePlayerId,
          diplomacy: diplomacy,
          gameState: gameState,
          onAvatarTapped: onAvatarTapped ?? (_) {},
          timerLabels: timerLabels,
          timedOutPlayerIds: timedOutPlayerIds,
        ),
      ),
    ),
  );
}

Future<void> _pumpRailOverlay(WidgetTester tester, {required GameSave save}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [gamePlayerControlSaveProvider.overrideWithValue(save)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [MultiplayerAvatarsRailOverlay(gameSave: save)],
          ),
        ),
      ),
    ),
  );
}

void _runMultiplayerAvatarTailScenarios() {
  testWidgets('timeout status has priority over turn state', (tester) async {
    await _pumpRail(
      tester,
      save: _save(),
      timedOutPlayerIds: const {'player_2'},
    );

    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_2.timeout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_2.submitted')),
      findsNothing,
    );
  });

  testWidgets('renders relation status for rival players', (tester) async {
    await _pumpRail(
      tester,
      save: _save(),
      diplomacy: DiplomacyState.empty.registerCityAttack(
        attackerPlayerId: 'player_1',
        defenderPlayerId: 'player_2',
      ),
    );

    expect(
      find.byKey(const Key('multiplayerRelationChip.war')),
      findsOneWidget,
    );
  });

  testWidgets('tapping an avatar reports the player id', (tester) async {
    String? tappedPlayerId;
    await _pumpRail(
      tester,
      save: _save(),
      onAvatarTapped: (playerId) => tappedPlayerId = playerId,
    );

    await tester.tap(
      find.byKey(const Key('multiplayerAvatarTile.player_3.waiting')),
    );

    expect(tappedPlayerId, 'player_3');
  });
}
