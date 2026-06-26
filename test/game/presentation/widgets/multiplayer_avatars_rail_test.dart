import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_status_sheet_provider.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  GameState? gameState,
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

void main() {
  testWidgets('hides itself outside multiplayer mode', (tester) async {
    await _pumpRail(tester, save: _save(gameMode: GameMode.hotSeat));

    expect(find.byKey(const Key('multiplayerAvatarsRail')), findsNothing);
  });

  testWidgets('renders multiplayer statuses with fixed row geometry', (
    tester,
  ) async {
    await _pumpRail(
      tester,
      save: _save(),
      timerLabels: const {'player_1': '01:20'},
    );

    expect(find.byKey(const Key('multiplayerAvatarsRail')), findsOneWidget);
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_2.submitted')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_3.waiting')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_4.thinking')),
      findsOneWidget,
    );
    expect(find.text('01:20'), findsOneWidget);

    final itemSize = tester.getSize(
      find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
    );
    expect(itemSize.width, MultiplayerAvatarsRail.itemWidth);
    expect(itemSize.height, MultiplayerAvatarsRail.itemHeight);
  });

  testWidgets('uses compact mobile avatars with full list sheet', (
    tester,
  ) async {
    String? tappedPlayerId;
    await _pumpRail(
      tester,
      save: _save(),
      screenSize: const Size(390, 844),
      onAvatarTapped: (playerId) => tappedPlayerId = playerId,
    );

    expect(find.byKey(const Key('multiplayerAvatarsRail')), findsOneWidget);
    expect(
      find.byKey(const Key('multiplayerCompactAvatarTile.player_1.active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
      findsNothing,
    );
    expect(find.text('Alice'), findsNothing);

    final compactSize = tester.getSize(
      find.byKey(const Key('multiplayerCompactAvatarTile.player_1.active')),
    );
    expect(compactSize.width, MultiplayerAvatarsRail.compactItemSize);
    expect(compactSize.height, MultiplayerAvatarsRail.compactItemSize);

    await tester.tap(find.byKey(const Key('multiplayerAvatarsRail.openSheet')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('multiplayerAvatarsRail.sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarsRail.fullList')),
      findsOneWidget,
    );
    expect(find.text('Alice'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('multiplayerAvatarTile.player_2.submitted')),
    );
    await tester.pumpAndSettle();

    expect(tappedPlayerId, 'player_2');
    expect(find.byKey(const Key('multiplayerAvatarsRail.sheet')), findsNothing);
  });

  testWidgets('keeps compact avatars on landscape phones', (tester) async {
    await _pumpRail(tester, save: _save(), screenSize: const Size(844, 390));

    expect(find.byKey(const Key('multiplayerAvatarsRail')), findsOneWidget);
    expect(
      find.byKey(const Key('multiplayerCompactAvatarTile.player_1.active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
      findsNothing,
    );
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('dismisses requested status sheet when the turn advances', (
    tester,
  ) async {
    final save = _save(
      players: const [_alice, _bob],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );

    await _pumpRailOverlay(tester, save: save);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MultiplayerAvatarsRailOverlay)),
      listen: false,
    );

    container
        .read(multiplayerStatusSheetRequestProvider.notifier)
        .request(save: save, activePlayerId: 'player_1');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('multiplayerAvatarsRail.sheet')),
      findsOneWidget,
    );

    await _pumpRailOverlay(
      tester,
      save: save.copyWith(
        turn: save.turn + 1,
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('multiplayerAvatarsRail.sheet')), findsNothing);
  });

  testWidgets('expanded rail opens status sheet with wider leader chips', (
    tester,
  ) async {
    const longNamePlayer = Player(
      id: 'player_1',
      name: 'Alexandros Megas of Macedon',
      colorValue: 0xFF2563EB,
    );

    await _pumpRail(
      tester,
      save: _save(
        players: const [longNamePlayer, _bob],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      ),
      screenSize: const Size(900, 700),
    );

    expect(
      find.byKey(const Key('multiplayerAvatarsRail.openSheet')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('multiplayerAvatarsRail.openSheet')));
    await tester.pumpAndSettle();

    final fullList = find.byKey(const Key('multiplayerAvatarsRail.fullList'));
    expect(fullList, findsOneWidget);
    expect(find.text('Alexandros Megas of Macedon'), findsWidgets);

    final sheetTile = find.descendant(
      of: fullList,
      matching: find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
    );
    expect(sheetTile, findsOneWidget);
    expect(
      tester.getSize(sheetTile).width,
      greaterThan(MultiplayerAvatarsRail.itemWidth),
    );
  });

  testWidgets('full list sheet includes empire stats when state is available', (
    tester,
  ) async {
    final gameState = GameState(
      activePlayerId: 'player_1',
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Krakow',
          population: 4,
          center: CityHex(col: 0, row: 0),
        ),
        GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_1',
          name: 'Gdansk',
          population: 2,
          center: CityHex(col: 1, row: 0),
        ),
        GameCity(
          id: 'city_3',
          ownerPlayerId: 'player_2',
          name: 'Rome',
          population: 5,
          center: CityHex(col: 2, row: 0),
        ),
      ],
      units: [
        GameUnit(
          id: 'unit_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'unit_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.archer,
          name: 'Archer',
          col: 1,
          row: 0,
        ),
        GameUnit(
          id: 'unit_3',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 2,
          row: 0,
        ),
      ],
      artifacts: const [
        WorldArtifact(
          id: 'artifact.crown',
          type: WorldArtifactType.ancientImperialCrown,
          location: WorldArtifactLocation.stored(cityId: 'city_1'),
        ),
      ],
    );

    await _pumpRail(
      tester,
      save: _save(),
      gameState: gameState,
      screenSize: const Size(390, 844),
    );

    await tester.tap(find.byKey(const Key('multiplayerAvatarsRail.openSheet')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('multiplayerStatusStats.panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerStatusStats.shareBar.cities')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerStatusStats.shareBar.units')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerStatusStats.shareBar.population')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerStatusStats.shareBar.artifacts')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('multiplayerStatusStats.player.player_1.citiesValue'),
        ),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('multiplayerStatusStats.player.player_1.unitsValue'),
        ),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('multiplayerStatusStats.player.player_1.populationValue'),
        ),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('multiplayerStatusStats.player.player_1.artifactsValue'),
        ),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('status sheet marks rival stats unknown for scoped snapshots', (
    tester,
  ) async {
    final gameState = GameState(
      fogOfWar: FogOfWarState(
        players: {'player_1': PlayerFogOfWar(playerId: 'player_1')},
      ),
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Krakow',
          population: 3,
          center: CityHex(col: 0, row: 0),
        ),
      ],
      units: [GameUnit.startingCommander(ownerPlayerId: 'player_1')],
    );

    await _pumpRail(
      tester,
      save: _save(players: const [_alice, _bob]),
      gameState: gameState,
      screenSize: const Size(390, 844),
    );

    await tester.tap(find.byKey(const Key('multiplayerAvatarsRail.openSheet')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(
          const Key('multiplayerStatusStats.player.player_1.citiesValue'),
        ),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('multiplayerStatusStats.player.player_2.citiesValue'),
        ),
        matching: find.text('?'),
      ),
      findsOneWidget,
    );
  });

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
