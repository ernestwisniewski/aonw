import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

const _activityEntry = GameEventNotification(
  id: 1,
  event: CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
  state: GameState(activePlayerId: 'player_1'),
  playerId: 'player_1',
);

GameSession _testSession() {
  return GameSession(
    mapData: MapData(
      cols: 1,
      rows: 1,
      tiles: const [
        TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [],
          height: 0,
        ),
      ],
    ),
    viewMode: MapViewMode.tile,
    saveId: 'save',
  );
}

Widget _localizedApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

Future<void> _pumpOptionsOverlay(
  WidgetTester tester, {
  GameSession? session,
  HexDisplaySettings displaySettings = const HexDisplaySettings(),
  VoidCallback? onToggleTerrain,
  VoidCallback? onToggleResources,
  VoidCallback? onToggleHeightBadge,
  VoidCallback? onToggleCitySites,
  VoidCallback? onToggleCityGrowth,
  VoidCallback? onToggleHexBorders,
  VoidCallback? onToggleHeightWalls,
  ValueChanged<Color>? onHexBorderColorChanged,
  ValueChanged<Color>? onWallTintColorChanged,
  VoidCallback? onResetHexBorderColor,
  VoidCallback? onResetWallTintColor,
  VoidCallback? onResignMatch,
  GameSave? gameSave,
  Widget? closedContent,
  List<GameEventNotification> activityLog = const [],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameActivityLogProvider.overrideWith(
          () => _TestActivityLogNotifier(activityLog),
        ),
        if (gameSave != null)
          gamePlayerControlControllerProvider.overrideWithValue(
            const PlayerControlState(activePlayerId: 'player_1'),
          ),
      ],
      child: _localizedApp(
        home: Scaffold(
          body: GameOptionsOverlay(
            session: session ?? _testSession(),
            gameSave: gameSave,
            allowGraphicMode: false,
            onViewModeChanged: (_) {},
            displaySettings: displaySettings,
            onToggleTerrain: onToggleTerrain ?? () {},
            onToggleResources: onToggleResources ?? () {},
            onToggleHeightBadge: onToggleHeightBadge ?? () {},
            onToggleCitySites: onToggleCitySites ?? () {},
            onToggleCityGrowth: onToggleCityGrowth ?? () {},
            onToggleHexBorders: onToggleHexBorders ?? () {},
            onToggleHeightWalls: onToggleHeightWalls ?? () {},
            onHexBorderColorChanged: onHexBorderColorChanged,
            onWallTintColorChanged: onWallTintColorChanged,
            onResetHexBorderColor: onResetHexBorderColor,
            onResetWallTintColor: onResetWallTintColor,
            onResignMatch: onResignMatch,
            closedContent: closedContent,
          ),
        ),
      ),
    ),
  );
}

class _TestActivityLogNotifier extends GameActivityLogNotifier {
  _TestActivityLogNotifier(this.entries);

  final List<GameEventNotification> entries;

  @override
  List<GameEventNotification> build() => entries;
}

void _expectRectInside(Size size, Rect rect) {
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width + 0.1));
  expect(rect.bottom, lessThanOrEqualTo(size.height + 0.1));
}

void main() {
  testWidgets('left menu orders icon actions and can collapse', (tester) async {
    await _pumpOptionsOverlay(
      tester,
      gameSave: _save,
      activityLog: const [_activityEntry],
    );

    expect(find.byKey(const Key('globalHud.action.research')), findsOneWidget);
    expect(find.byKey(const Key('globalHud.action.empire')), findsOneWidget);
    expect(
      find.byKey(const Key('globalHud.action.activityLog')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('gameOptions.optionsButton')), findsOneWidget);
    expect(
      find.byKey(const Key('gameOptions.menuCollapseButton')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('gameOptions.optionsModeGlyph')),
      findsOneWidget,
    );

    final menuRect = tester.getRect(
      find.byKey(const Key('gameOptions.optionsButton')),
    );
    final journalRect = tester.getRect(
      find.byKey(const Key('globalHud.action.activityLog')),
    );
    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );
    final empireRect = tester.getRect(
      find.byKey(const Key('globalHud.action.empire')),
    );
    expect(menuRect.top, lessThan(journalRect.top));
    expect(journalRect.top, lessThan(researchRect.top));
    expect(researchRect.top, lessThan(empireRect.top));

    await tester.longPress(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.byKey(const Key('globalHud.action.research')), findsNothing);
    expect(find.byKey(const Key('globalHud.action.empire')), findsNothing);
    expect(find.byKey(const Key('globalHud.action.activityLog')), findsNothing);
    expect(find.byKey(const Key('gameOptions.optionsButton')), findsNothing);
    expect(
      find.byKey(const Key('gameOptions.menuExpandButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('gameOptions.menuExpandButton')));
    await tester.pump();

    expect(find.byKey(const Key('globalHud.action.research')), findsOneWidget);
    expect(find.byKey(const Key('globalHud.action.empire')), findsOneWidget);
    expect(
      find.byKey(const Key('globalHud.action.activityLog')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('gameOptions.optionsButton')), findsOneWidget);
  });

  testWidgets('visibility toggles update an open game options panel', (
    tester,
  ) async {
    var showHeightBadge = false;
    var showDiceRollTest = false;
    var showHexes = false;
    var showHeightWalls = false;

    await tester.pumpWidget(
      ProviderScope(
        child: _localizedApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return GameOptionsOverlay(
                  session: _testSession(),
                  allowGraphicMode: false,
                  onViewModeChanged: (_) {},
                  displaySettings: HexDisplaySettings(
                    showHeightBadge: showHeightBadge,
                    hexBorderColor: showHexes
                        ? const Color(0xFFFFD766)
                        : Colors.transparent,
                    wallTintColor: showHeightWalls
                        ? const Color(0xFFFFFFFF)
                        : Colors.transparent,
                  ),
                  onToggleTerrain: () {},
                  onToggleResources: () {},
                  onToggleHeightBadge: () {
                    setState(() => showHeightBadge = !showHeightBadge);
                  },
                  onToggleCitySites: () {},
                  onToggleCityGrowth: () {},
                  onToggleHexBorders: () {
                    setState(() => showHexes = !showHexes);
                  },
                  onToggleHeightWalls: () {
                    setState(() => showHeightWalls = !showHeightWalls);
                  },
                  showDiceRollTest: showDiceRollTest,
                  onToggleDiceRollTest: () {
                    setState(() => showDiceRollTest = !showDiceRollTest);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('GROWTH MIAST'), findsNothing);
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('DICE TEST'), findsOneWidget);
    expect(find.text('AUTO ACTION COMPLETION'), findsOneWidget);
    expect(find.text('AUTO TURN COMPLETION'), findsOneWidget);
    expect(find.text('TILES'), findsOneWidget);
    expect(find.text('SHOW HEXES'), findsOneWidget);
    expect(find.text('SHOW HEIGHT'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('HEIGHT')).dy,
      lessThan(tester.getTopLeft(find.text('DICE TEST')).dy),
    );
    expect(
      tester.getTopLeft(find.text('DICE TEST')).dy,
      lessThan(tester.getTopLeft(find.text('AUTO ACTION COMPLETION')).dy),
    );
    expect(
      tester.getTopLeft(find.text('AUTO ACTION COMPLETION')).dy,
      lessThan(tester.getTopLeft(find.text('AUTO TURN COMPLETION')).dy),
    );
    expect(
      tester.getTopLeft(find.text('AUTO TURN COMPLETION')).dy,
      lessThan(tester.getTopLeft(find.text('TILES')).dy),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('gameOptions.autoTurnSeparator')))
          .dy,
      greaterThan(tester.getTopLeft(find.text('AUTO TURN COMPLETION')).dy),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('gameOptions.autoTurnSeparator')))
          .dy,
      lessThan(tester.getTopLeft(find.text('TILES')).dy),
    );
    final heightRow = find.ancestor(
      of: find.text('HEIGHT'),
      matching: find.byType(GameUiVisibilityRow),
    );
    expect(
      find.descendant(
        of: heightRow,
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('HEIGHT'));
    await tester.pump();

    expect(showHeightBadge, isTrue);
    expect(
      find.descendant(
        of: heightRow,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('SHOW HEXES'));
    await tester.pump();
    await tester.tap(find.text('SHOW HEXES'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(showHexes, isTrue);

    await tester.ensureVisible(find.text('SHOW HEIGHT'));
    await tester.pump();
    await tester.tap(find.text('SHOW HEIGHT'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(showHeightWalls, isTrue);

    await tester.tap(find.text('DICE TEST'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(showDiceRollTest, isTrue);
  });

  testWidgets('auto action and turn options toggle state icons', (
    tester,
  ) async {
    await _pumpOptionsOverlay(tester);

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameOptions.autoActionFlowRow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.autoActionFlowIcon.on')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.autoActionFlowIcon.off')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('gameOptions.autoTurnFlowRow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.autoTurnFlowIcon.off')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.autoTurnFlowIcon.on')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('gameOptions.autoActionFlowRow')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameOptions.autoActionFlowIcon.off')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.autoActionFlowIcon.on')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('gameOptions.autoTurnFlowRow')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameOptions.autoTurnFlowIcon.on')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.autoTurnFlowIcon.off')),
      findsNothing,
    );
  });

  testWidgets('cinematic camera option toggles gameplay setting', (
    tester,
  ) async {
    await _pumpOptionsOverlay(tester);

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('CINEMATIC CAMERA'), findsOneWidget);
    expect(
      find.byKey(const Key('gameOptions.cinematicCameraIcon.off')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('gameOptions.cinematicCameraRow')));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameOptionsOverlay)),
      listen: false,
    );
    expect(
      container.read(gameplaySettingsProvider).cinematicCameraEnabled,
      isTrue,
    );
    expect(
      find.byKey(const Key('gameOptions.cinematicCameraIcon.on')),
      findsOneWidget,
    );
  });

  testWidgets('enemy unit camera option toggles gameplay setting', (
    tester,
  ) async {
    await _pumpOptionsOverlay(tester);

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('FOLLOW ENEMY UNITS WITH CAMERA'), findsOneWidget);
    expect(
      find.byKey(const Key('gameOptions.followEnemyUnitCameraIcon.off')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('gameOptions.followEnemyUnitCameraRow')),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameOptionsOverlay)),
      listen: false,
    );
    expect(
      container.read(gameplaySettingsProvider).followEnemyUnitCamera,
      isTrue,
    );
    expect(
      find.byKey(const Key('gameOptions.followEnemyUnitCameraIcon.on')),
      findsOneWidget,
    );
  });

  testWidgets('question button always lists tutorial and auto turn help', (
    tester,
  ) async {
    await _pumpOptionsOverlay(tester);

    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text('Auto turn completion'), findsOneWidget);

    await tester.tap(find.text('Auto turn completion'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameOptionsOverlay)),
      listen: false,
    );
    final state = container.read(hudMinimizedPopupsProvider);
    expect(
      state.restoreRequest?.popupId,
      HudMinimizedPopupIds.autoTurnHint('save'),
    );
    expect(
      state.restoreRequest?.entry?.kind,
      HudMinimizedPopupKind.autoTurnHint,
    );
  });

  testWidgets('question button uses game save id for global help entries', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final workerEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner('save', 'selectedWorkerAction'),
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Worker: improve tile',
      subtitle: 'This tile can start an improvement.',
    );
    container.read(hudMinimizedPopupsProvider.notifier).minimize(workerEntry);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _localizedApp(
          home: Scaffold(
            body: GameOptionsOverlay(
              session: GameSession(
                mapData: _testSession().mapData,
                viewMode: MapViewMode.tile,
                saveId: 'session_only',
              ),
              gameSave: _save,
              allowGraphicMode: false,
              onViewModeChanged: (_) {},
              displaySettings: const HexDisplaySettings(),
              onToggleTerrain: () {},
              onToggleResources: () {},
              onToggleHeightBadge: () {},
              onToggleCitySites: () {},
              onToggleCityGrowth: () {},
              onToggleHexBorders: () {},
              onToggleHeightWalls: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('gameOptions.helpPopupsButton')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text('Auto turn completion'), findsOneWidget);
    expect(find.text('Worker: improve tile'), findsOneWidget);
  });

  testWidgets('map color pickers are removed from game options', (
    tester,
  ) async {
    await _pumpOptionsOverlay(
      tester,
      onHexBorderColorChanged: (_) {},
      onWallTintColorChanged: (_) {},
      onResetHexBorderColor: () {},
      onResetWallTintColor: () {},
    );

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('Border'), findsNothing);
    expect(find.text('Wall'), findsNothing);
    expect(
      find.byKey(const Key('gameOptions.mapOverlayToggle')),
      findsOneWidget,
    );
    expect(find.text('SHOW HEXES'), findsOneWidget);
    expect(find.text('SHOW HEIGHT'), findsOneWidget);
  });

  testWidgets('open panel stays inside portrait phone viewport', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpOptionsOverlay(tester, onResignMatch: () {});

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    _expectRectInside(
      size,
      tester.getRect(find.byKey(const Key('gameOptions.panelViewport'))),
    );
    _expectRectInside(
      size,
      tester.getRect(find.byKey(const Key('gameOptions.optionsButton'))),
    );
    expect(find.text('RESIGN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open panel stays inside landscape phone viewport', (
    tester,
  ) async {
    const size = Size(740, 360);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpOptionsOverlay(tester, onResignMatch: () {});

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    final panelRect = tester.getRect(
      find.byKey(const Key('gameOptions.panelViewport')),
    );
    _expectRectInside(size, panelRect);
    expect(panelRect.height, lessThanOrEqualTo(280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('closed content is constrained on short viewports', (
    tester,
  ) async {
    const size = Size(740, 360);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpOptionsOverlay(
      tester,
      closedContent: Container(width: 56, height: 600, color: Colors.red),
    );

    _expectRectInside(
      size,
      tester.getRect(
        find.byKey(const Key('gameOptions.closedContentViewport')),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('open panel stays inside tablet and desktop viewports', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in const [Size(834, 1112), Size(1366, 768)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await _pumpOptionsOverlay(tester);

      await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
      await tester.pump();

      final panelRect = tester.getRect(
        find.byKey(const Key('gameOptions.panelViewport')),
      );
      _expectRectInside(size, panelRect);
      expect(panelRect.width, lessThanOrEqualTo(292.1));
      expect(panelRect.width, greaterThanOrEqualTo(280));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('question button restores first-turn tutorial', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final entry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.firstTurnTutorial('save'),
      kind: HudMinimizedPopupKind.firstTurnCoachmarks,
      title: 'Tutorial',
      subtitle: 'First-turn guide',
      payload: const {'stepIndex': '1'},
    );
    container.read(hudMinimizedPopupsProvider.notifier).minimize(entry);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _localizedApp(
          home: Scaffold(
            body: GameOptionsOverlay(
              session: _testSession(),
              allowGraphicMode: false,
              onViewModeChanged: (_) {},
              displaySettings: const HexDisplaySettings(),
              onToggleTerrain: () {},
              onToggleResources: () {},
              onToggleHeightBadge: () {},
              onToggleCitySites: () {},
              onToggleCityGrowth: () {},
              onToggleHexBorders: () {},
              onToggleHeightWalls: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('HINTS'), findsOneWidget);
    expect(find.text('Tutorial'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('gameOptions.helpPanelViewport')))
          .width,
      greaterThan(260),
    );

    await tester.tap(find.text('Tutorial'));
    await tester.pump();

    final state = container.read(hudMinimizedPopupsProvider);
    expect(state.entries, [entry]);
    expect(state.restoreRequest?.popupId, entry.id);
  });

  testWidgets('question button shows all minimized help entries', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final modeEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner('save', 'moveTargeting'),
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Movement mode',
      subtitle: 'Choose a target hex.',
    );
    final technologyEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.technologyDiscovery(
        'save',
        'player_1.agriculture',
      ),
      kind: HudMinimizedPopupKind.technologyDiscovery,
      title: 'Technology discovered',
      subtitle: 'Agriculture - Alice',
      payload: const {'playerId': 'player_1', 'technologyId': 'agriculture'},
    );
    container.read(hudMinimizedPopupsProvider.notifier)
      ..minimize(modeEntry)
      ..minimize(technologyEntry);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _localizedApp(
          home: Scaffold(
            body: GameOptionsOverlay(
              session: _testSession(),
              allowGraphicMode: false,
              onViewModeChanged: (_) {},
              displaySettings: const HexDisplaySettings(),
              onToggleTerrain: () {},
              onToggleResources: () {},
              onToggleHeightBadge: () {},
              onToggleCitySites: () {},
              onToggleCityGrowth: () {},
              onToggleHexBorders: () {},
              onToggleHeightWalls: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('Movement mode'), findsOneWidget);
    expect(find.text('Technology discovered'), findsOneWidget);

    await tester.tap(find.text('Technology discovered'));
    await tester.pump();

    final state = container.read(hudMinimizedPopupsProvider);
    expect(state.entries, [modeEntry, technologyEntry]);
    expect(state.restoreRequest?.popupId, technologyEntry.id);
    expect(state.restoreRequest?.sequence, 1);
    expect(find.text('HINTS'), findsNothing);
  });

  testWidgets('question button shows when only mode hints exist', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final modeEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner('save', 'moveTargeting'),
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Movement mode',
      subtitle: 'Choose a target hex.',
    );
    container.read(hudMinimizedPopupsProvider.notifier).minimize(modeEntry);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _localizedApp(
          home: Scaffold(
            body: GameOptionsOverlay(
              session: _testSession(),
              allowGraphicMode: false,
              onViewModeChanged: (_) {},
              displaySettings: const HexDisplaySettings(),
              onToggleTerrain: () {},
              onToggleResources: () {},
              onToggleHeightBadge: () {},
              onToggleCitySites: () {},
              onToggleCityGrowth: () {},
              onToggleHexBorders: () {},
              onToggleHeightWalls: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('Movement mode'), findsOneWidget);
    expect(container.read(hudMinimizedPopupsProvider).entries, [modeEntry]);
  });

  testWidgets('question button labels minimized diplomatic popups', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final diplomaticEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.diplomaticMessage('save', 'message_1'),
      kind: HudMinimizedPopupKind.diplomaticMessage,
      title: 'New dispatch',
      subtitle: 'Bob - A common enemy threatens us both.',
    );
    container
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(diplomaticEntry);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _localizedApp(
          home: Scaffold(
            body: GameOptionsOverlay(
              session: _testSession(),
              allowGraphicMode: false,
              onViewModeChanged: (_) {},
              displaySettings: const HexDisplaySettings(),
              onToggleTerrain: () {},
              onToggleResources: () {},
              onToggleHeightBadge: () {},
              onToggleCitySites: () {},
              onToggleCityGrowth: () {},
              onToggleHexBorders: () {},
              onToggleHeightWalls: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('New dispatch'), findsOneWidget);
    expect(find.text('Diplomacy'), findsOneWidget);
  });
}
