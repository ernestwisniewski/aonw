import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_dialog.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/end_turn_button.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck_slot.dart';
import 'package:aonw/game/presentation/widgets/hud/layout/hud_side_menu_metrics.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notifications_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/game_hud_overlay_host.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/game_hud_overlay_panels_host.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_top_resource_slot.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_overlay.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_detail_sheet.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_dialog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGameRepository implements GameRepository {
  _FakeGameRepository({SaveSnapshot? snapshot})
    : snapshot = snapshot ?? SaveSnapshot(save: _save);

  SaveSnapshot snapshot;
  CameraState? savedCamera;
  Completer<void>? loadGate;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async {
    return 'save';
  }

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async {
    final gate = loadGate;
    if (gate != null) {
      loadGate = null;
      await gate.future;
    }
    return snapshot;
  }

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    savedCamera = camera;
    snapshot = snapshot.copyWith(save: snapshot.save.copyWith(camera: camera));
    return snapshot;
  }
}

class _FakeEventLog implements EventLog {
  final commands = <LoggedCommand>[];

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.fold<int>(0, (latest, command) {
      return command.offset > latest ? command.offset : latest;
    });
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}

class _FakeSnapshotStore implements SnapshotStore {
  final snapshots = <Snapshot>[];

  @override
  Future<Snapshot?> latest(String saveId) async {
    return snapshots.isEmpty ? null : snapshots.last;
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    snapshots.add(snapshot);
  }
}

class _RecordingGameLogger implements GameLogger {
  final warnings = <({String tag, String message, Object? error})>[];

  @override
  void info(String tag, String message) {}

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    warnings.add((tag: tag, message: message, error: error));
  }
}

class _SpyGameRenderer extends GameRenderer {
  _SpyGameRenderer({required super.mapData}) : super(onCommand: (_) async {});

  final handledEffects = <RendererEffect>[];
  final appliedStates = <GameState>[];

  @override
  Future<void> applyTransition(
    GameState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) async {
    appliedStates.add(state);
    applyState(state, currentTurn: currentTurn);
    handledEffects.addAll(effects);
  }

  @override
  Future<void> handleEffects(Iterable<RendererEffect> effects) async {
    handledEffects.addAll(effects);
  }
}

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);
const _aiPlayer = Player(
  id: 'player_1',
  name: 'AI Random',
  colorValue: 0xFF4a7fc4,
  kind: PlayerKind.ai,
  ai: AiPlayer(
    strategyId: AiStrategyId.random,
    difficulty: AiDifficulty.normal,
    persona: AiPersona.balanced,
    seed: 99,
  ),
);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 2,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

MapData _makeMap() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (int row = 0; row < 3; row++)
      for (int col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameSession _makeSession(
  MapData mapData, {
  GameMode gameMode = GameMode.hotSeat,
}) => GameSession(
  mapData: mapData,
  viewMode: MapViewMode.tile,
  saveId: 'save',
  gameMode: gameMode,
);

Future<void> _pumpHud(
  WidgetTester tester, {
  required _FakeGameRepository repository,
  VoidCallback? onClose,
  GameSave? gameSave,
  GameSession? session,
  NetworkSession? networkSession,
  bool showEntryHandoff = false,
  bool aiAutopilotEnabled = false,
  GameRenderer? renderer,
  EventLog? eventLog,
  GameLogger? logger,
  bool? autoActionFlowEnabled,
  bool? autoTurnFlowEnabled,
  ValueListenable<bool> initialCameraFocusReadyListenable =
      const AlwaysStoppedAnimation<bool>(true),
}) async {
  final mapData = _makeMap();
  final activeSession = session ?? _makeSession(mapData);
  final activeRenderer =
      renderer ??
      GameRenderer(mapData: activeSession.mapData, onCommand: (_) async {});
  final save = gameSave ?? _save;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeGameSessionProvider.overrideWithValue(activeSession),
        activeGameRendererProvider.overrideWithValue(activeRenderer),
        gamePlayerControlSaveProvider.overrideWithValue(save),
        gameRepositoryProvider.overrideWithValue(repository),
        eventLogProvider.overrideWithValue(eventLog ?? _FakeEventLog()),
        snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
        if (logger != null) gameLoggerProvider.overrideWithValue(logger),
        if (autoActionFlowEnabled != null)
          hudAutoActionFlowProvider.overrideWith(
            () => _TestHudAutoActionFlowController(autoActionFlowEnabled),
          ),
        if (autoTurnFlowEnabled != null)
          hudAutoTurnFlowProvider.overrideWith(
            () => _TestHudAutoTurnFlowController(autoTurnFlowEnabled),
          ),
        if (networkSession != null)
          networkSessionProvider.overrideWithValue(networkSession),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameHud(
            session: activeSession,
            animatingUnitIdsListenable:
                activeRenderer.animatingUnitIdsListenable,
            initialCameraFocusReadyListenable:
                initialCameraFocusReadyListenable,
            allowGraphicMode: false,
            onViewModeChanged: (_) {},
            onClose: onClose ?? () {},
            gameSave: save,
            displaySettings: const HexDisplaySettings(),
            onToggleTerrain: () {},
            onToggleResources: () {},
            onToggleHeightBadge: () {},
            onToggleCitySites: () {},
            onToggleCityGrowth: () {},
            onToggleHexBorders: () {},
            onToggleHeightWalls: () {},
            showEntryHandoff: showEntryHandoff,
            aiAutopilotEnabled: aiAutopilotEnabled,
          ),
        ),
      ),
    ),
  );
}

class _TestHudAutoActionFlowController extends HudAutoActionFlowController {
  _TestHudAutoActionFlowController(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

class _TestHudAutoTurnFlowController extends HudAutoTurnFlowController {
  _TestHudAutoTurnFlowController(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int frames = 12,
  int ticksPerFrame = 40,
  Duration pollInterval = const Duration(milliseconds: 25),
}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump();
    if (done()) return;

    await tester.runAsync(() async {
      for (var tick = 0; tick < ticksPerFrame; tick++) {
        if (done()) return;
        await Future<void>.delayed(pollInterval);
      }
    });
    if (done()) return;
  }
}

Future<void> _cancelMoveTargetingBanner(WidgetTester tester) async {
  final moveAction = find.byKey(const Key('selectionInfo.action.move'));
  if (moveAction.evaluate().isEmpty) return;
  await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openHelpEntryById(WidgetTester tester, String popupId) async {
  await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
  await tester.pump();
  await tester.tap(find.byKey(Key('gameOptions.helpPopup.$popupId')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

GameState? _readGameState(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(GameHud)),
    listen: false,
  );
  return container.read(gameStateProvider('save')).value;
}

Future<void> _disableAutoTurnFlow(WidgetTester tester) async {
  await _setAutoTurnFlow(tester, false);
}

Future<void> _enableAutoTurnFlow(WidgetTester tester) async {
  await _setAutoTurnFlow(tester, true);
}

Future<void> _setAutoTurnFlow(WidgetTester tester, bool enabled) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(GameHud)),
    listen: false,
  );
  container.read(hudAutoActionFlowProvider.notifier).setEnabled(enabled);
  container.read(hudAutoTurnFlowProvider.notifier).setEnabled(enabled);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(container.read(hudAutoActionFlowProvider), enabled);
  expect(container.read(hudAutoTurnFlowProvider), enabled);
}

void _expectRectInside(Rect rect, Rect viewport, {required String reason}) {
  expect(rect.left, greaterThanOrEqualTo(viewport.left), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(viewport.top), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.right), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.bottom), reason: reason);
}

void _expectRectContains(Rect outer, Rect inner, {required String reason}) {
  expect(inner.left, greaterThanOrEqualTo(outer.left), reason: reason);
  expect(inner.top, greaterThanOrEqualTo(outer.top), reason: reason);
  expect(inner.right, lessThanOrEqualTo(outer.right), reason: reason);
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom), reason: reason);
}

void _expectCoachmarkHaloTracks(
  WidgetTester tester,
  Finder target, {
  required String reason,
}) {
  final halo = tester.getRect(
    find.byKey(const Key('firstTurnCoachmarks.halo')),
  );
  final targetRect = tester.getRect(target);
  expect(halo.contains(targetRect.center), isTrue, reason: reason);
  expect(halo.overlaps(targetRect), isTrue, reason: reason);
}

void _expectWarmPanelSurface(
  WidgetTester tester,
  Key key, {
  required String reason,
}) {
  final surface = tester.widget<DecoratedBox>(find.byKey(key));
  final decoration = surface.decoration;
  expect(decoration, isA<BoxDecoration>(), reason: reason);
  final box = decoration as BoxDecoration;
  expect(box.gradient, isA<LinearGradient>(), reason: reason);
  expect(box.color, isNull, reason: reason);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hotseat entry shows handoff before turn start preparation', (
    tester,
  ) async {
    await _pumpHud(
      tester,
      repository: _FakeGameRepository(),
      showEntryHandoff: true,
    );
    for (var i = 0; i < 5 && find.text('ALICE').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('hotseat entry skips handoff for AI players', (tester) async {
    final save = _save.copyWith(players: const [_aiPlayer]);

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(snapshot: SaveSnapshot(save: save)),
      gameSave: save,
      showEntryHandoff: true,
    );

    expect(find.text('AI RANDOM'), findsNothing);
    expect(find.text('CONTINUE'), findsNothing);
  });

  testWidgets('hotseat autopilot ends AI turn and requests human handoff', (
    tester,
  ) async {
    final save = _save.copyWith(
      players: const [_aiPlayer, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      aiAutopilotEnabled: true,
    );
    await _pumpUntil(tester, () {
      return repository.snapshot.save.playerStates['player_1'] ==
          PlayerTurnState.finished;
    });
    await tester.pump();
    for (var i = 0; i < 5 && find.text('BOB').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      repository.snapshot.save.playerStates['player_1'],
      PlayerTurnState.finished,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.activePlayerId, 'player_1');

    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, isNot('player_2'));
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await _pumpUntil(
      tester,
      () =>
          container.read(gameStateProvider('save')).value?.activePlayerId ==
          'player_2',
      frames: 8,
    );

    final confirmedControl = container.read(
      gamePlayerControlControllerProvider,
    );
    expect(confirmedControl.activePlayerId, 'player_2');
    expect(confirmedControl.canAct, isTrue);

    final confirmedState = container.read(gameStateProvider('save')).value;
    expect(confirmedState?.activePlayerId, 'player_2');
    expect(confirmedState?.activePlayerCanAct, isTrue);
    expect(find.text('BOB'), findsNothing);
  });

  testWidgets(
    'manual hotseat end turn waits for handoff confirmation before renderer presentation',
    (tester) async {
      final save = _save.copyWith(
        players: const [_player, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            activePlayerId: 'player_1',
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
          ),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
      );
      await tester.pump();
      renderer.appliedStates.clear();
      renderer.handledEffects.clear();

      await tester.tap(find.byType(EndTurnButton));
      await _pumpUntil(
        tester,
        () => find.text('BOB').evaluate().isNotEmpty,
        frames: 8,
      );

      expect(find.text('BOB'), findsOneWidget);
      expect(renderer.appliedStates, isEmpty);
      expect(renderer.handledEffects, isEmpty);

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(
        tester,
        () => _readGameState(tester)?.activePlayerId == 'player_2',
        frames: 8,
      );

      expect(renderer.appliedStates, isNotEmpty);
      expect(_readGameState(tester)?.activePlayerId, 'player_2');
    },
  );

  testWidgets(
    'auto hotseat end turn waits for handoff confirmation before renderer presentation',
    (tester) async {
      final save = _save.copyWith(
        players: const [_player, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            activePlayerId: 'player_1',
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
          ),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
      );
      await tester.pump();
      renderer.appliedStates.clear();
      renderer.handledEffects.clear();

      await _enableAutoTurnFlow(tester);
      await _pumpUntil(
        tester,
        () => find.text('BOB').evaluate().isNotEmpty,
        frames: 8,
      );

      expect(find.text('BOB'), findsOneWidget);
      expect(renderer.appliedStates, isEmpty);
      expect(renderer.handledEffects, isEmpty);

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(
        tester,
        () => _readGameState(tester)?.activePlayerId == 'player_2',
        frames: 8,
      );

      expect(renderer.appliedStates, isNotEmpty);
      expect(_readGameState(tester)?.activePlayerId, 'player_2');
    },
  );

  testWidgets(
    'hotseat autopilot chains multiple AI players without exposing AI fog',
    (tester) async {
      const ai2 = Player(
        id: 'player_2',
        name: 'AI Bob',
        colorValue: 0xFFc45050,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 2,
        ),
      );
      const ai3 = Player(
        id: 'player_3',
        name: 'AI Cora',
        colorValue: 0xFF70a45d,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 3,
        ),
      );
      const ai4 = Player(
        id: 'player_4',
        name: 'AI Dale',
        colorValue: 0xFFb8854f,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 4,
        ),
      );
      final save = _save.copyWith(
        players: const [_player, ai2, ai3, ai4],
        playerStates: const {
          'player_1': PlayerTurnState.finished,
          'player_2': PlayerTurnState.active,
          'player_3': PlayerTurnState.active,
          'player_4': PlayerTurnState.active,
        },
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: const GameState(
            activePlayerId: 'player_1',
            activePlayerCanAct: false,
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
        aiAutopilotEnabled: true,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      expect(
        container.read(gamePlayerControlControllerProvider).activePlayerId,
        'player_1',
      );
      expect(
        container.read(gamePlayerControlControllerProvider).canAct,
        isFalse,
      );
      expect(
        container.read(gameStateProvider('save')).value?.activePlayerId,
        'player_1',
      );
      expect(
        container.read(gameStateProvider('save')).value?.activePlayerCanAct,
        isFalse,
      );

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump();
        await tester.runAsync(() async {
          for (var tick = 0; tick < 40; tick++) {
            final handoff = container.read(gameHandoffProvider);
            if (repository.snapshot.save.turn > save.turn &&
                handoff?.playerId == 'player_1') {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        });
        final handoff = container.read(gameHandoffProvider);
        if (repository.snapshot.save.turn > save.turn &&
            handoff?.playerId == 'player_1') {
          break;
        }
      }
      await tester.pump();

      expect(repository.snapshot.save.playerStates, const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
        'player_3': PlayerTurnState.active,
        'player_4': PlayerTurnState.active,
      });
      expect(repository.snapshot.save.turn, save.turn + 1);
      expect(container.read(gameHandoffProvider)?.playerId, 'player_1');
      await _pumpUntil(
        tester,
        () => find.text('ALICE').evaluate().isNotEmpty,
        frames: 8,
      );
      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      var chainedControl = container.read(gamePlayerControlControllerProvider);
      expect(chainedControl.activePlayerId, 'player_1');
      expect(chainedControl.canAct, isFalse);

      var chainedState = container.read(gameStateProvider('save')).value;
      expect(chainedState?.activePlayerId, 'player_1');
      expect(chainedState?.activePlayerCanAct, isFalse);
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        isNot(contains(anyOf('player_2', 'player_3', 'player_4'))),
      );

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(tester, () {
        final state = container.read(gameStateProvider('save')).value;
        final control = container.read(gamePlayerControlControllerProvider);
        return (state?.activePlayerCanAct ?? false) && control.canAct;
      }, frames: 8);

      chainedControl = container.read(gamePlayerControlControllerProvider);
      expect(chainedControl.activePlayerId, 'player_1');
      expect(chainedControl.canAct, isTrue);

      chainedState = container.read(gameStateProvider('save')).value;
      expect(chainedState?.activePlayerId, 'player_1');
      expect(chainedState?.activePlayerCanAct, isTrue);
      expect(find.text('ALICE'), findsNothing);
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        isNot(contains(anyOf('player_2', 'player_3', 'player_4'))),
      );
    },
  );

  testWidgets(
    'local multiplayer AI chain keeps camera and perspective on the human',
    (tester) async {
      const ai2 = Player(
        id: 'player_2',
        name: 'AI Bob',
        colorValue: 0xFFc45050,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 2,
        ),
      );
      const ai3 = Player(
        id: 'player_3',
        name: 'AI Cora',
        colorValue: 0xFF70a45d,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 3,
        ),
      );
      const ai4 = Player(
        id: 'player_4',
        name: 'AI Dale',
        colorValue: 0xFFb8854f,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 4,
        ),
      );
      final save = _save.copyWith(
        gameMode: GameMode.multiplayer,
        players: const [_player, ai2, ai3, ai4],
        playerStates: const {
          'player_1': PlayerTurnState.finished,
          'player_2': PlayerTurnState.active,
          'player_3': PlayerTurnState.active,
          'player_4': PlayerTurnState.active,
        },
      );
      final queuedUnit =
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0)
              .copyWith(movementPoints: 0)
              .copyWithQueuedPath(
                QueuedMovePath(
                  targetCol: 1,
                  targetRow: 0,
                  steps: const [
                    UnitMovementStep(
                      col: 0,
                      row: 0,
                      enterCost: 0,
                      cumulativeCost: 0,
                    ),
                    UnitMovementStep(
                      col: 1,
                      row: 0,
                      enterCost: 1,
                      cumulativeCost: 1,
                    ),
                  ],
                ),
              );
      final aiUnit2 = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 2,
      ).copyWith(movementPoints: 0);
      final aiUnit3 = GameUnit.startingCommander(
        ownerPlayerId: 'player_3',
        col: 0,
        row: 2,
      ).copyWith(movementPoints: 0);
      final aiUnit4 = GameUnit.startingCommander(
        ownerPlayerId: 'player_4',
        col: 2,
        row: 0,
      ).copyWith(movementPoints: 0);
      final renderer = _SpyGameRenderer(mapData: _makeMap());
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            units: [queuedUnit, aiUnit2, aiUnit3, aiUnit4],
            activePlayerId: 'player_1',
            activePlayerCanAct: false,
            submittedPlayerIds: const {'player_1'},
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
        renderer: renderer,
        aiAutopilotEnabled: true,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump();
        await tester.runAsync(() async {
          for (var tick = 0; tick < 40; tick++) {
            final state = container.read(gameStateProvider('save')).value;
            if (repository.snapshot.save.turn > save.turn &&
                state?.activePlayerId == 'player_1' &&
                (state?.activePlayerCanAct ?? false)) {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        });
        final state = container.read(gameStateProvider('save')).value;
        if (repository.snapshot.save.turn > save.turn &&
            state?.activePlayerId == 'player_1' &&
            (state?.activePlayerCanAct ?? false)) {
          break;
        }
      }
      await tester.pump();

      expect(repository.snapshot.save.turn, save.turn + 1);
      expect(repository.snapshot.save.playerStates, const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
        'player_3': PlayerTurnState.active,
        'player_4': PlayerTurnState.active,
      });
      final control = container.read(gamePlayerControlControllerProvider);
      expect(control.activePlayerId, 'player_1');
      expect(control.canAct, isTrue);
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_1');
      expect(state?.activePlayerCanAct, isTrue);
      expect(
        state?.units.singleWhere((unit) => unit.id == queuedUnit.id).col,
        1,
      );
      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>().map(
          (effect) => effect.unitId,
        ),
        contains(queuedUnit.id),
      );
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        isNot(contains(anyOf('player_2', 'player_3', 'player_4'))),
      );
    },
  );

  testWidgets('local multiplayer AI can submit before the human ends turn', (
    tester,
  ) async {
    final aiPlayer = _player2.copyWith(
      name: 'AI Bob',
      kind: PlayerKind.ai,
      ai: const AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 42,
      ),
    );
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: [_player, aiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: const GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await _pumpUntil(tester, () {
      return repository.snapshot.save.playerStates['player_2'] ==
          PlayerTurnState.finished;
    });
    await tester.pump();

    expect(repository.snapshot.save.turn, save.turn);
    expect(repository.snapshot.save.playerStates, const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.finished,
    });
    final control = container.read(gamePlayerControlControllerProvider);
    expect(control.activePlayerId, 'player_1');
    expect(control.canAct, isTrue);
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
  });

  testWidgets(
    'local multiplayer AI animates visible movement without exposing AI perspective',
    (tester) async {
      final aiPlayer = _player2.copyWith(
        name: 'AI Bob',
        kind: PlayerKind.ai,
        ai: const AiPlayer(
          strategyId: AiStrategyId.random,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 7,
        ),
      );
      final save = _save.copyWith(
        gameMode: GameMode.multiplayer,
        players: [_player, aiPlayer],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final humanUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 0);
      final aiUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 1,
        row: 1,
      ).copyWith(movementPoints: 2);
      final renderer = _SpyGameRenderer(mapData: _makeMap());
      final logger = _RecordingGameLogger();
      final eventLog = _FakeEventLog();
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [humanUnit, aiUnit],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    for (var row = 0; row < 3; row++)
                      for (var col = 0; col < 3; col++)
                        HexCoordinate(col: col, row: row),
                  },
                ),
              },
            ),
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
        renderer: renderer,
        eventLog: eventLog,
        logger: logger,
        aiAutopilotEnabled: true,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container.read(gameStateProvider('save').future);
      await tester.pump();

      await _pumpUntil(tester, () {
        return renderer.handledEffects.whereType<AnimateUnitMoveEffect>().any(
          (effect) => effect.unitId == aiUnit.id,
        );
      }, frames: 10);
      await tester.pump(const Duration(milliseconds: 250));
      await _pumpUntil(tester, () {
        return repository.snapshot.save.playerStates['player_2'] ==
            PlayerTurnState.finished;
      }, frames: 10);
      await tester.pump();

      expect(
        logger.warnings,
        isEmpty,
        reason: logger.warnings
            .map(
              (warning) =>
                  '${warning.tag}: ${warning.message}: ${warning.error}',
            )
            .join('\n'),
      );
      expect(
        eventLog.commands.map((command) => command.command.runtimeType),
        contains(SubmitTurnCommand),
      );
      expect(repository.snapshot.save.turn, save.turn);
      expect(
        repository.snapshot.save.playerStates['player_2'],
        PlayerTurnState.finished,
      );
      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>().map(
          (effect) => effect.unitId,
        ),
        contains(aiUnit.id),
      );
      expect(
        renderer.appliedStates.map((state) => state.activePlayerId),
        everyElement('player_1'),
      );
      expect(
        renderer.appliedStates.map((state) => state.activePlayerCanAct),
        everyElement(isTrue),
      );
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_1');
      expect(state?.activePlayerCanAct, isTrue);
    },
  );

  testWidgets('single-player AI handback focuses the human ready unit', (
    tester,
  ) async {
    final aiPlayer = _player2.copyWith(
      name: 'AI Bob',
      kind: PlayerKind.ai,
      ai: const AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 42,
      ),
    );
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: [_player, aiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final commander = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: 0,
      row: 0,
    ).copyWith(movementPoints: 0);
    final aiCommander = GameUnit.startingCommander(
      ownerPlayerId: 'player_2',
      col: 2,
      row: 2,
    ).copyWith(movementPoints: 0);
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          units: [commander, aiCommander],
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          submittedPlayerIds: const {'player_1'},
        ),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      renderer: renderer,
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await _pumpUntil(tester, () {
      final state = container.read(gameStateProvider('save')).value;
      return repository.snapshot.save.turn > save.turn &&
          state?.selectedUnitId == commander.id;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = container.read(gameStateProvider('save')).value;
    expect(repository.snapshot.save.turn, save.turn + 1);
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
    expect(state?.selectedUnitId, commander.id);
    expect(state?.moveCommandActive, isTrue);
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().any(
        (effect) => effect.col == commander.col && effect.row == commander.row,
      ),
      isTrue,
    );
  });

  testWidgets('AI handback focuses the human map start when research is next', (
    tester,
  ) async {
    final aiPlayer = _player2.copyWith(
      name: 'AI Bob',
      kind: PlayerKind.ai,
      ai: const AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.balanced,
        seed: 42,
      ),
    );
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: [_player, aiPlayer],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final aiCommander = GameUnit.startingCommander(
      ownerPlayerId: 'player_2',
      col: 2,
      row: 2,
    ).copyWith(movementPoints: 0);
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 0, row: 0),
      controlledHexes: const [CityHex(col: 0, row: 0)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          units: [aiCommander],
          cities: [city],
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          submittedPlayerIds: const {'player_1'},
        ),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      renderer: renderer,
      aiAutopilotEnabled: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    await tester.pump();

    await _pumpUntil(tester, () {
      final state = container.read(gameStateProvider('save')).value;
      return repository.snapshot.save.turn > save.turn &&
          state?.pendingAction is PendingResearchSelection &&
          (state?.activePlayerCanAct ?? false);
    });
    await tester.pump();

    final state = container.read(gameStateProvider('save')).value;
    expect(repository.snapshot.save.turn, save.turn + 1);
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
    expect(state?.pendingAction, isA<PendingResearchSelection>());
    final smoothEffects = renderer.handledEffects
        .whereType<SmoothCameraEffect>()
        .toList(growable: false);
    expect(smoothEffects, isNotEmpty);
    expect(smoothEffects.last.col, city.center.col);
    expect(smoothEffects.last.row, city.center.row);
  });

  testWidgets(
    'hotseat handoff stays visible while confirmation prepares turn',
    (tester) async {
      final repository = _FakeGameRepository();
      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      container
          .read(gameHandoffProvider.notifier)
          .setPending(
            const HandoffData(
              playerId: 'player_1',
              playerName: 'Alice',
              playerColorValue: 0xFF4a7fc4,
              turnNumber: 1,
            ),
          );
      await tester.pump();
      for (var i = 0; i < 5 && find.text('ALICE').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('ALICE'), findsOneWidget);

      final gate = Completer<void>();
      repository.loadGate = gate;

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(gate.isCompleted, isFalse);

      gate.complete();
      await _pumpUntil(
        tester,
        () => find.text('ALICE').evaluate().isEmpty,
        frames: 8,
      );
      expect(find.text('ALICE'), findsNothing);
    },
  );

  testWidgets('hotseat handoff prepares turn start after player confirms', (
    tester,
  ) async {
    final save = _save.copyWith(
      turn: 3,
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final otherUnit = GameUnit.produced(
      id: 'warrior_2',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 2,
      row: 2,
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(units: [unit, otherUnit], activePlayerId: 'player_2'),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      renderer: renderer,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container.read(gameStateProvider('save').future);
    final gate = Completer<void>();
    repository.loadGate = gate;
    container
        .read(gameHandoffProvider.notifier)
        .setPending(
          const HandoffData(
            playerId: 'player_1',
            playerName: 'Alice',
            playerColorValue: 0xFF4a7fc4,
            turnNumber: 3,
            freshTurn: true,
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(gameHandoffProvider)?.playerId, 'player_1');
    expect(find.text('ALICE'), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      isNull,
    );

    expect(gate.isCompleted, isFalse);

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    expect(find.text('ALICE'), findsOneWidget);
    expect(gate.isCompleted, isFalse);

    gate.complete();
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        final state = container.read(gameStateProvider('save')).value;
        if (state?.selectedUnitId == 'warrior_1') break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pump();

    expect(find.text('ALICE'), findsNothing);
    final preparedState = container.read(gameStateProvider('save')).value;
    expect(preparedState?.activePlayerId, 'player_1');
    expect(preparedState?.activePlayerCanAct, isTrue);
    expect(preparedState?.selectedUnitId, 'warrior_1');
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().any(
        (effect) => effect.col == unit.col && effect.row == unit.row,
      ),
      isTrue,
    );
    final smoothCameraEffectCount = renderer.handledEffects
        .whereType<SmoothCameraEffect>()
        .length;

    final state = container.read(gameStateProvider('save')).value;
    expect(state?.activePlayerId, 'player_1');
    expect(state?.activePlayerCanAct, isTrue);
    expect(state?.selectedUnitId, 'warrior_1');
    expect(state?.moveCommandActive, isTrue);
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().length,
      smoothCameraEffectCount,
    );
  });

  testWidgets(
    'hotseat handoff to third human in four-player game waits for confirm before camera focus',
    (tester) async {
      const player3 = Player(
        id: 'player_3',
        name: 'Cora',
        colorValue: 0xFF70a45d,
      );
      const player4 = Player(
        id: 'player_4',
        name: 'Dale',
        colorValue: 0xFFb8854f,
      );
      final save = _save.copyWith(
        turn: 5,
        players: const [_player, _player2, player3, player4],
        playerStates: const {
          'player_1': PlayerTurnState.finished,
          'player_2': PlayerTurnState.finished,
          'player_3': PlayerTurnState.active,
          'player_4': PlayerTurnState.active,
        },
      );
      final previousUnit = GameUnit.produced(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 0,
        row: 2,
      );
      final thirdPlayerUnit = GameUnit.produced(
        id: 'warrior_3',
        ownerPlayerId: 'player_3',
        type: GameUnitType.warrior,
        col: 2,
        row: 1,
      );
      final fourthPlayerUnit = GameUnit.produced(
        id: 'warrior_4',
        ownerPlayerId: 'player_4',
        type: GameUnitType.warrior,
        col: 1,
        row: 2,
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            units: [previousUnit, thirdPlayerUnit, fourthPlayerUnit],
            activePlayerId: 'player_2',
            activePlayerCanAct: false,
          ),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        renderer: renderer,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container.read(gameStateProvider('save').future);

      container
          .read(gameHandoffProvider.notifier)
          .setPending(
            const HandoffData(
              playerId: 'player_3',
              playerName: 'Cora',
              playerColorValue: 0xFF70a45d,
              turnNumber: 5,
            ),
          );
      await tester.pump();

      expect(find.text('CORA'), findsOneWidget);
      expect(renderer.handledEffects.whereType<SmoothCameraEffect>(), isEmpty);

      await tester.tap(find.text('CONTINUE'));
      await _pumpUntil(
        tester,
        () =>
            container.read(gameStateProvider('save')).value?.selectedUnitId ==
            thirdPlayerUnit.id,
        frames: 12,
      );

      expect(find.text('CORA'), findsNothing);
      final state = container.read(gameStateProvider('save')).value;
      expect(state?.activePlayerId, 'player_3');
      expect(state?.activePlayerCanAct, isTrue);
      expect(state?.selectedUnitId, thirdPlayerUnit.id);
      expect(
        renderer.handledEffects.whereType<SmoothCameraEffect>().any(
          (effect) =>
              effect.col == thirdPlayerUnit.col &&
              effect.row == thirdPlayerUnit.row,
        ),
        isTrue,
      );
    },
  );

  testWidgets('hotseat start focuses the next actionable object', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(cities: [city], activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(tester, repository: repository, showEntryHandoff: true);
    await tester.pump();

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selection?.city?.id, 'city_1');
  });

  testWidgets('hotseat start prioritizes a movable unit over stale selection', (
    tester,
  ) async {
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          units: [unit],
          cities: const [city],
          activePlayerId: 'player_1',
          interaction: GameInteractionState(
            selection: GameSelection.city(
              city,
              cityYield: TileYield.zero,
              playerColor: 0xFF4a7fc4,
            ),
          ),
        ),
      ),
    );

    await _pumpHud(tester, repository: repository, showEntryHandoff: true);
    await tester.pump();

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_1');
    expect(state?.moveCommandActive, isTrue);
  });

  testWidgets('hotseat start does not focus a city with queued production', (
    tester,
  ) async {
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          cities: [city],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        ),
      ),
    );

    await _pumpHud(tester, repository: repository, showEntryHandoff: true);
    await tester.pump();

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selection?.city, isNull);
    expect(state?.pendingAction, isNull);
  });

  testWidgets('army detail is inactive on initial render', (tester) async {
    await _pumpHud(tester, repository: _FakeGameRepository());

    // The army detail sheet should only appear after the Army action is tapped.
    expect(find.text('Warriors'), findsNothing);
  });

  testWidgets('map inspection shows tile details without game selection', (
    tester,
  ) async {
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(_makeMap().tileAt(1, 1)!);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const Key('selectionInfo.detail.description')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudActionDeck.context.terrain')),
      findsOneWidget,
    );
    expect(find.byType(SelectionActionChip), findsNothing);
    expect(find.byType(SelectionCommandChip), findsNothing);
    expect(container.read(gameStateProvider('save')).value?.selection, isNull);

    container.read(mapInspectionControllerProvider.notifier).clear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const Key('selectionInfo.detail.description')),
      findsNothing,
    );
    expect(container.read(mapInspectionControllerProvider).active, isFalse);
  });

  testWidgets('anchored map inspection shows compact hex menu', (tester) async {
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(_makeMap().tileAt(1, 1)!, anchor: const Offset(180, 120));
    await tester.pump();

    expect(
      find.byKey(const Key('hudMapInspectionMenu.positioned')),
      findsOneWidget,
    );
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Possible improvements'), findsOneWidget);
    expect(
      find.byKey(const Key('hudMapInspectionMenu.improvement.farm')),
      findsOneWidget,
    );
    final lockedTechnology = tester.widget<Text>(
      find.byKey(const Key('hudMapInspectionMenu.improvement.farm.technology')),
    );
    expect(lockedTechnology.data, '(Agriculture)');
    expect(lockedTechnology.style?.color, GameUiTheme.danger);
    expect(find.byType(SelectionDetailSheet), findsNothing);

    await tester.tap(find.byKey(const Key('hudMapInspectionMenu.close')));
    await tester.pump();

    expect(container.read(mapInspectionControllerProvider).active, isFalse);
    expect(
      find.byKey(const Key('hudMapInspectionMenu.positioned')),
      findsNothing,
    );
  });

  testWidgets('anchored map inspection shows map objective details', (
    tester,
  ) async {
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    const objective = MapObjectiveProgress(
      definition: MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 1, row: 1),
        requiredHoldTurns: 3,
        victoryPoints: 2,
        goldPerTurn: 1,
      ),
      controllingPlayerId: 'player_1',
      holdTurns: 2,
    );
    container
        .read(mapInspectionControllerProvider.notifier)
        .inspectObjective(objective, anchor: const Offset(180, 120));
    await tester.pump();

    expect(find.text('Map objective'), findsWidgets);
    expect(find.text('Strategic pass'), findsWidgets);
    expect(find.text('Holding 2/3'), findsOneWidget);
    expect(find.text('+2 VP'), findsOneWidget);
    expect(find.text('+1 gold/turn'), findsOneWidget);
    expect(find.text('Terrain'), findsNothing);
  });

  testWidgets(
    'objective inspection keeps a dedicated popup over selected hex',
    (tester) async {
      final map = _makeMap();
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(
            activePlayerId: 'player_1',
            interaction: GameInteractionState(
              selection: GameSelection.tile(map.tileAt(1, 1)!),
            ),
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await _disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      const objective = MapObjectiveProgress(
        definition: MapObjectiveDefinition(
          id: 'pass_1',
          type: MapObjectiveType.strategicPass,
          hex: CityHex(col: 1, row: 1),
          requiredHoldTurns: 3,
          victoryPoints: 2,
        ),
        controllingPlayerId: 'player_1',
        holdTurns: 2,
      );
      container
          .read(mapInspectionControllerProvider.notifier)
          .inspectObjective(objective, anchor: const Offset(180, 120));
      await tester.pump();

      expect(
        find.byKey(const Key('hudMapInspectionMenu.objectivePopover')),
        findsOneWidget,
      );
      expect(find.text('Strategic pass'), findsWidgets);
      expect(find.text('Holding 2/3'), findsOneWidget);
      expect(find.text('Terrain'), findsNothing);
      expect(find.text('Possible improvements'), findsNothing);
    },
  );

  testWidgets(
    'anchored map inspection marks unlocked improvement technology green',
    (tester) async {
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(
            activePlayerId: 'player_1',
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  unlockedTechnologyIds: {TechnologyId.agriculture},
                ),
              },
            ),
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await _disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      container
          .read(mapInspectionControllerProvider.notifier)
          .inspectTile(
            _makeMap().tileAt(1, 1)!,
            anchor: const Offset(180, 120),
          );
      await tester.pump();

      final unlockedTechnology = tester.widget<Text>(
        find.byKey(
          const Key('hudMapInspectionMenu.improvement.farm.technology'),
        ),
      );
      expect(unlockedTechnology.data, '(Agriculture)');
      expect(unlockedTechnology.style?.color, GameUiTheme.success);
    },
  );

  testWidgets(
    'top resource strip shows turn, resources and domination status',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: const GameState(
            activePlayerId: 'player_1',
            cities: [city],
            playerGold: {'player_1': 17},
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final goldFinder = find.byKey(const Key('gameHud.resource.gold'));
      final scienceFinder = find.byKey(const Key('gameHud.resource.science'));
      final resourcesFinder = find.byKey(
        const Key('gameHud.resource.resources'),
      );
      final identityFinder = find.byKey(const Key('gameHud.resource.identity'));
      final turnFinder = find.byKey(const Key('gameHud.resource.turn'));
      final victoryFinder = find.byKey(const Key('gameHud.victoryStatus'));

      expect(identityFinder, findsNothing);
      expect(goldFinder, findsOneWidget);
      expect(scienceFinder, findsOneWidget);
      expect(resourcesFinder, findsOneWidget);
      expect(turnFinder, findsOneWidget);
      expect(victoryFinder, findsOneWidget);
      expect(find.text('Alice · T2'), findsNothing);
      expect(find.text('T2'), findsOneWidget);
      expect(find.textContaining('DOM'), findsOneWidget);
      expect(
        find.descendant(of: goldFinder, matching: find.text('17')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scienceFinder, matching: find.text('+2')),
        findsOneWidget,
      );

      final hudWidth = tester.getSize(find.byType(GameHud)).width;
      final goldRect = tester.getRect(goldFinder);
      final scienceRect = tester.getRect(scienceFinder);
      final resourcesRect = tester.getRect(resourcesFinder);
      final turnRect = tester.getRect(turnFinder);
      final victoryRect = tester.getRect(victoryFinder);

      expect(goldRect.top, lessThan(50));
      expect(scienceRect.top, lessThan(50));
      expect(resourcesRect.top, lessThan(50));
      expect(turnRect.top, lessThan(50));
      expect(victoryRect.top, lessThan(50));
      expect(scienceRect.left, greaterThan(goldRect.right));
      expect(resourcesRect.left, greaterThan(scienceRect.right));
      expect(turnRect.left, greaterThan(resourcesRect.right));
      expect(victoryRect.left, greaterThan(turnRect.right));
      expect((scienceRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect((resourcesRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect((turnRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect((victoryRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
      expect(victoryRect.right, lessThan(hudWidth - 8));
    },
  );

  testWidgets('top resource strip shows score cap and current leader', (
    tester,
  ) async {
    final turnLimit = GameLengthConfig.standard60.turnLimit!;
    final save = _save.copyWith(
      turn: turnLimit - 5,
      matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [city],
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 2,
              row: 2,
            ),
          ],
        ),
      ),
    );

    await _pumpHud(tester, repository: repository, gameSave: save);
    await tester.pump();

    final victoryFinder = find.byKey(const Key('gameHud.victoryStatus'));

    expect(victoryFinder, findsOneWidget);
    expect(
      find.descendant(
        of: victoryFinder,
        matching: find.textContaining('SCORE 5T'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: victoryFinder,
        matching: find.textContaining('ALICE'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('globalHud.action.objectives')),
        matching: find.text('PTS'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message?.contains('lead defense') ?? false),
      ),
      findsWidgets,
    );
  });

  testWidgets(
    'score pressure links the score badge, objectives overview and action marker',
    (tester) async {
      final turnLimit = GameLengthConfig.standard60.turnLimit!;
      final save = _save.copyWith(
        turn: turnLimit - 5,
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        players: const [_player, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      const activeCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      const leaderCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Rywal',
        center: CityHex(col: 2, row: 2),
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            activePlayerId: 'player_1',
            cities: const [activeCity, leaderCity],
            units: [
              GameUnit.produced(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                col: 0,
                row: 0,
              ),
              GameUnit.produced(
                id: 'warrior_2',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                col: 2,
                row: 2,
              ),
              GameUnit.produced(
                id: 'warrior_3',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                col: 2,
                row: 1,
              ),
            ],
          ),
        ),
      );

      await _pumpHud(tester, repository: repository, gameSave: save);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('globalHud.action.objectives')),
          matching: find.text('PTS'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('globalHud.action.objectives')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('OBJECTIVES'), findsOneWidget);
      expect(find.text('SCORE PRESSURE'), findsOneWidget);
      expect(find.text('Top priority: Catch the score leader'), findsOneWidget);
      expect(find.textContaining('Score gap'), findsWidgets);
    },
  );

  testWidgets('outcome overlay shows conquest victory and returns to menu', (
    tester,
  ) async {
    var closed = false;
    final save = _save.copyWith(
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          activePlayerId: 'player_1',
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      onClose: () => closed = true,
    );
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('VICTORY'), findsOneWidget);
    expect(find.text('CONQUEST'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);

    await tester.tap(find.byKey(const Key('gameHud.outcome.returnToMenu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(closed, isTrue);
    expect(repository.savedCamera, isNotNull);
  });

  testWidgets('outcome overlay shows defeat for the active losing player', (
    tester,
  ) async {
    final save = _save.copyWith(
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          activePlayerId: 'player_2',
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      ),
    );

    await _pumpHud(tester, repository: repository, gameSave: save);
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('DEFEAT'), findsOneWidget);
    expect(find.text('CONQUEST'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);
  });

  testWidgets('outcome overlay shows score draw rows', (tester) async {
    final turnLimit = GameLengthConfig.standard60.turnLimit!;
    final save = _save.copyWith(
      turn: turnLimit,
      matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          activePlayerId: 'player_1',
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
          ],
        ),
      ),
    );

    await _pumpHud(tester, repository: repository, gameSave: save);
    await tester.pump();

    expect(find.byKey(const Key('gameHud.outcomeOverlay')), findsOneWidget);
    expect(find.text('DRAW'), findsOneWidget);
    expect(find.text('SCORE DRAW'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('15'), findsNWidgets(2));
  });

  testWidgets('first turn first game walks through unit-led coachmarks', (
    tester,
  ) async {
    final firstTurnSave = _save.copyWith(
      turn: 1,
      gameMode: GameMode.multiplayer,
    );
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      name: GameUnitType.settler.defaultNameToken,
      col: 1,
      row: 1,
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: firstTurnSave,
        state: GameState(
          activePlayerId: 'player_1',
          units: [settler],
          interaction: GameInteractionState(
            selection: GameSelection.unit(settler),
            moveCommandActive: true,
          ),
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: firstTurnSave,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('firstTurnCoachmarks.minimize')),
      findsOneWidget,
    );
    expect(find.text('Step 1: read the selection'), findsOneWidget);
    expect(find.text('Step 1/8'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byKey(const Key('hudActionDeck.surface')),
      reason: 'Opening coachmark should track the selected-unit deck.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    final minimizedCoachmarks = container
        .read(hudMinimizedPopupsProvider)
        .entriesForSave(firstTurnSave.id)
        .where(
          (entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks,
        )
        .toList(growable: false);
    expect(minimizedCoachmarks, hasLength(1));
    expect(
      minimizedCoachmarks.single.id,
      HudMinimizedPopupIds.firstTurnTutorial(firstTurnSave.id),
    );
    expect(minimizedCoachmarks.single.title, 'Tutorial');
    expect(minimizedCoachmarks.single.subtitle, 'First-turn guide');
    expect(find.text('Step 2: check your empire'), findsOneWidget);
    expect(find.text('Step 2/8'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byKey(const Key('gameHud.resource.singleRow')),
      reason: 'Resource coachmark should track the visible top resource row.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    final updatedMinimizedCoachmarks = container
        .read(hudMinimizedPopupsProvider)
        .entriesForSave(firstTurnSave.id)
        .where(
          (entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks,
        )
        .toList(growable: false);
    expect(updatedMinimizedCoachmarks, hasLength(1));
    expect(updatedMinimizedCoachmarks.single.payload['stepIndex'], '1');
    expect(find.text('Step 3: learn the left menu'), findsOneWidget);
    expect(find.text('Step 3/8'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byKey(const Key('gameOptions.optionsButton')),
      reason: 'Side menu coachmark should track the left menu rail.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    final actionMinimizedCoachmarks = container
        .read(hudMinimizedPopupsProvider)
        .entriesForSave(firstTurnSave.id)
        .where(
          (entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks,
        )
        .toList(growable: false);
    expect(actionMinimizedCoachmarks, hasLength(1));
    expect(actionMinimizedCoachmarks.single.payload['stepIndex'], '2');
    expect(find.text('Step 4: give the right order'), findsOneWidget);
    expect(find.text('Step 4/8'), findsOneWidget);
    final actionTarget =
        find
            .byKey(const Key('hudActionDeck.line.actions'))
            .evaluate()
            .isNotEmpty
        ? find.byKey(const Key('hudActionDeck.line.actions'))
        : find.byKey(const Key('hudActionDeck.surface'));
    _expectCoachmarkHaloTracks(
      tester,
      actionTarget,
      reason: 'Settler action coachmark should track the visible bottom deck.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    final researchMinimizedCoachmarks = container
        .read(hudMinimizedPopupsProvider)
        .entriesForSave(firstTurnSave.id)
        .where(
          (entry) => entry.kind == HudMinimizedPopupKind.firstTurnCoachmarks,
        )
        .toList(growable: false);
    expect(researchMinimizedCoachmarks, hasLength(1));
    expect(researchMinimizedCoachmarks.single.payload['stepIndex'], '3');
    expect(find.text('Step 5: choose research'), findsOneWidget);
    expect(find.text('Step 5/8'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byKey(const Key('globalHud.action.research')),
      reason: 'Research coachmark should track the bottom research action.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Step 6: set up the city'), findsOneWidget);
    expect(find.text('Step 6/8'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byKey(const Key('hudActionDeck.surface')),
      reason: 'City setup coachmark should return to the bottom deck.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Step 7: clear the action queue'), findsOneWidget);
    expect(find.text('Step 7/8'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byType(EndTurnButton),
      reason: 'Action queue coachmark should track the action button.',
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Step 8: end the turn and repeat'), findsOneWidget);
    expect(find.text('Step 8/8'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    _expectCoachmarkHaloTracks(
      tester,
      find.byType(EndTurnButton),
      reason: 'End-turn coachmark should track the centered action button.',
    );

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
    expect(find.text('Do not show again'), findsNothing);

    final tutorialPopupId = HudMinimizedPopupIds.firstTurnTutorial(
      firstTurnSave.id,
    );
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(tutorialPopupId),
      isTrue,
    );
    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();
    await tester.tap(find.text('Tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
    expect(find.text('Step 1: read the selection'), findsOneWidget);
    expect(find.text('Step 1/8'), findsOneWidget);
  });

  testWidgets('skipped first turn coachmarks stay in question menu', (
    tester,
  ) async {
    final firstTurnSave = _save.copyWith(
      turn: 1,
      gameMode: GameMode.multiplayer,
    );
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      name: GameUnitType.settler.defaultNameToken,
      col: 1,
      row: 1,
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: firstTurnSave,
        state: GameState(
          activePlayerId: 'player_1',
          units: [settler],
          interaction: GameInteractionState(
            selection: GameSelection.unit(settler),
            moveCommandActive: true,
          ),
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: firstTurnSave,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );

    await tester.tap(find.text('Skip'));
    await tester.pump();

    final tutorialPopupId = HudMinimizedPopupIds.firstTurnTutorial(
      firstTurnSave.id,
    );
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(tutorialPopupId),
      isTrue,
    );
    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text('Auto turn completion'), findsOneWidget);
    await tester.tap(find.text('Tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
  });

  testWidgets('first turn coachmarks require first-turn ready HUD state', (
    tester,
  ) async {
    final firstTurnSave = _save.copyWith(
      turn: 1,
      playerStates: const {'player_1': PlayerTurnState.finished},
    );
    await _pumpHud(
      tester,
      repository: _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: firstTurnSave,
          state: const GameState(activePlayerId: ''),
        ),
      ),
      gameSave: firstTurnSave,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final readyFirstTurnSave = firstTurnSave.copyWith(
      playerStates: const {'player_1': PlayerTurnState.active},
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: readyFirstTurnSave,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: readyFirstTurnSave,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);
  });

  testWidgets('first turn coachmarks wait for the initial camera focus', (
    tester,
  ) async {
    final firstTurnSave = _save.copyWith(
      turn: 1,
      gameMode: GameMode.multiplayer,
      players: const [_player],
    );
    final settler = GameUnit.produced(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      col: 1,
      row: 1,
    );
    final focusReady = ValueNotifier(false);
    addTearDown(focusReady.dispose);
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: firstTurnSave,
        state: GameState(
          activePlayerId: 'player_1',
          units: [settler],
          interaction: GameInteractionState(
            selection: GameSelection.unit(settler),
            moveCommandActive: true,
          ),
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: firstTurnSave,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      initialCameraFocusReadyListenable: focusReady,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('firstTurnCoachmarks.overlay')), findsNothing);

    focusReady.value = true;
    await tester.pump();

    expect(
      find.byKey(const Key('firstTurnCoachmarks.overlay')),
      findsOneWidget,
    );
  });

  testWidgets('top right resource pill opens controlled resources popup', (
    tester,
  ) async {
    final mapData = MapData(
      cols: 3,
      rows: 3,
      tiles: [
        for (var row = 0; row < 3; row++)
          for (var col = 0; col < 3; col++)
            TileData(
              col: col,
              row: row,
              terrains: const [TerrainType.grassland],
              resources: switch ((col, row)) {
                (1, 1) => const [ResourceType.iron],
                (2, 1) => const [ResourceType.wheat],
                _ => const [],
              },
              height: 0,
            ),
      ],
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 2, row: 1)],
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(cities: [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      session: _makeSession(mapData),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gameHud.resource.resources')));
    await tester.pump();

    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Controlled deposits'), findsOneWidget);
    expect(find.text('iron'), findsWidgets);
    expect(find.text('wheat'), findsWidgets);
  });

  testWidgets('top right gold pill shows net economy after unit upkeep', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      buildings: {CityBuildingType.merchantHall},
    );
    final units = [
      GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: GameUnitType.settler.defaultNameToken,
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      ),
      GameUnit(
        id: 'archer_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: GameUnitType.archer.defaultNameToken,
        col: 0,
        row: 2,
      ),
      GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      ),
      GameUnit(
        id: 'worker_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 2,
        row: 0,
      ),
    ];
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [city],
          units: units,
          playerGold: const {'player_1': 17},
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    final goldFinder = find.byKey(const Key('gameHud.resource.gold'));

    expect(
      find.descendant(of: goldFinder, matching: find.text('17')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: goldFinder, matching: find.text('▲ +1')),
      findsOneWidget,
    );
  });

  testWidgets('resource pills open source breakdown popups', (tester) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      buildings: {CityBuildingType.merchantHall},
    );
    final units = [
      GameUnit(
        id: 'settler_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: GameUnitType.settler.defaultNameToken,
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      ),
      GameUnit(
        id: 'archer_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: GameUnitType.archer.defaultNameToken,
        col: 0,
        row: 2,
      ),
      GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      ),
      GameUnit(
        id: 'worker_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 2,
        row: 0,
      ),
    ];
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [city],
          units: units,
          playerGold: const {'player_1': 17},
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gameHud.resource.gold')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.gold')),
      findsOneWidget,
    );
    expect(find.text('City income'), findsOneWidget);
    expect(find.text('Upkeep'), findsOneWidget);
    expect(find.text('City'), findsWidgets);

    await tester.tap(find.byKey(const Key('gameHud.resource.science')));
    await tester.pump();

    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.gold')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.science')),
      findsOneWidget,
    );
    expect(find.text('Science / turn'), findsOneWidget);
    expect(find.text('Active research'), findsOneWidget);
  });

  testWidgets('resource breakdown sheet stays above action deck on portrait', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(
          activePlayerId: 'player_1',
          playerGold: {'player_1': 17},
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gameHud.resource.gold')));
    await tester.pump();

    final sheet = tester.getRect(
      find.byKey(const Key('gameHud.resourceBreakdownSheet.gold')),
    );
    final deck = tester.getRect(find.byKey(const Key('hudActionDeck.surface')));
    expect(sheet.overlaps(deck), isTrue);

    final overlayStack = tester
        .widgetList<Stack>(find.byType(Stack))
        .firstWhere(
          (stack) =>
              stack.children.any((child) => child is HudActionDeckSlot) &&
              stack.children.any((child) => child is HudTopResourceSlot),
        );
    final actionDeckIndex = overlayStack.children.indexWhere(
      (child) => child is HudActionDeckSlot,
    );
    final resourceIndex = overlayStack.children.indexWhere(
      (child) => child is HudTopResourceSlot,
    );

    expect(resourceIndex, greaterThan(actionDeckIndex));
  });

  testWidgets('options panel does not expose a manual save button', (
    tester,
  ) async {
    await _pumpHud(tester, repository: _FakeGameRepository());

    final optionsButton = find.byKey(const Key('gameOptions.optionsButton'));
    final optionsRect = tester.getRect(optionsButton);
    final optionsCenter = optionsRect.center;
    expect(optionsCenter.dx, lessThan(80));
    expect(optionsRect.top, greaterThanOrEqualTo(0));

    await tester.tap(optionsButton);
    await tester.pump();

    expect(find.text('OPTIONS'), findsOneWidget);
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('SAVE'), findsNothing);
    expect(find.text('MULTIPLAYER'), findsNothing);
  });

  testWidgets('multiplayer options expose resign action', (tester) async {
    final save = _save.copyWith(gameMode: GameMode.multiplayer);
    await _pumpHud(
      tester,
      repository: _FakeGameRepository(),
      gameSave: save,
      networkSession: NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('jwt-token'),
        matchId: 'save',
        connectionState: const NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();

    expect(find.text('RESIGN'), findsOneWidget);
  });

  testWidgets('multiplayer shows player rail on the right side', (
    tester,
  ) async {
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.finished,
      },
    );

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(snapshot: SaveSnapshot(save: save)),
      gameSave: save,
      session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
    );
    await tester.pump();

    final railFinder = find.byKey(const Key('multiplayerAvatarsRail'));
    expect(railFinder, findsOneWidget);
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_1.active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayerAvatarTile.player_2.submitted')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.closedContentViewport')),
      findsNothing,
    );

    final railRect = tester.getRect(railFinder);
    final hudWidth = tester.getSize(find.byType(GameHud)).width;
    final menuRect = tester.getRect(find.text('MENU'));
    final optionsRect = tester.getRect(
      find.byKey(const Key('gameOptions.optionsButton')),
    );
    expect(railRect.right, greaterThan(hudWidth - 24));
    expect(railRect.left, greaterThan(menuRect.right));
    expect(railRect.top, greaterThan(menuRect.bottom));
    expect(railRect.top, HudSideMenuMetrics.topOffset);
    expect(optionsRect.top, railRect.top);
  });

  testWidgets(
    'multiplayer does not open player status sheet after submitting turn',
    (tester) async {
      final save = _save.copyWith(
        gameMode: GameMode.multiplayer,
        players: const [_player, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: save,
          state: GameState(
            activePlayerId: 'player_1',
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        gameSave: save,
        session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await _pumpUntil(
        tester,
        () => container.read(gameStateProvider('save')).value != null,
        frames: 8,
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();

      expect(
        repository.snapshot.save.playerStates['player_1'],
        PlayerTurnState.finished,
      );
      expect(
        find.byKey(const Key('multiplayerAvatarsRail.sheet')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('multiplayerStatusStats.panel')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('multiplayerAvatarTile.player_2.waiting')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'multiplayer portrait keeps compact player rail higher on right',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      final save = _save.copyWith(
        gameMode: GameMode.multiplayer,
        players: const [_player, _player2],
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
        },
      );

      await _pumpHud(
        tester,
        repository: _FakeGameRepository(snapshot: SaveSnapshot(save: save)),
        gameSave: save,
        session: _makeSession(_makeMap(), gameMode: GameMode.multiplayer),
      );
      await tester.pump();

      final railFinder = find.byKey(const Key('multiplayerAvatarsRail'));
      expect(railFinder, findsOneWidget);
      expect(
        find.byKey(const Key('multiplayerCompactAvatarTile.player_1.active')),
        findsOneWidget,
      );

      final railRect = tester.getRect(railFinder);
      final optionsRect = tester.getRect(
        find.byKey(const Key('gameOptions.optionsButton')),
      );
      final hudWidth = tester.getSize(find.byType(GameHud)).width;
      expect(railRect.top, HudSideMenuMetrics.compactTopOffset);
      expect(optionsRect.top, railRect.top);
      expect(railRect.right, greaterThan(hudWidth - 12));
    },
  );

  testWidgets('hotseat keeps avatars in the options closed content', (
    tester,
  ) async {
    final save = _save.copyWith(
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(snapshot: SaveSnapshot(save: save)),
      gameSave: save,
    );
    await tester.pump();

    expect(find.byKey(const Key('multiplayerAvatarsRail')), findsNothing);
    expect(
      find.byKey(const Key('gameOptions.closedContentViewport')),
      findsOneWidget,
    );
  });

  testWidgets('multiplayer HUD keeps the network session player in control', (
    tester,
  ) async {
    final save = _save.copyWith(
      gameMode: GameMode.multiplayer,
      players: const [_player, _player2],
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: save,
        state: GameState(
          playerColors: const {'player_1': 0xFF4a7fc4, 'player_2': 0xFFc45050},
          playerGold: const {'player_2': 0},
          units: [
            GameUnit.produced(
              id: 'settler_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.settler,
              col: 1,
              row: 1,
            ),
          ],
          fogOfWar: FogOfWarState(
            players: {
              'player_2': PlayerFogOfWar(
                playerId: 'player_2',
                visibleHexes: {const HexCoordinate(col: 1, row: 1)},
              ),
            },
          ),
        ),
      ),
    );
    final mapData = _makeMap();

    await _pumpHud(
      tester,
      repository: repository,
      gameSave: save,
      session: _makeSession(mapData, gameMode: GameMode.multiplayer),
      networkSession: NetworkSession(
        userId: 'user-2',
        playerId: 'player_2',
        token: AuthToken('token'),
        matchId: save.id,
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await _pumpUntil(
      tester,
      () =>
          container.read(gamePlayerControlControllerProvider).activePlayerId ==
          'player_2',
    );

    expect(
      container.read(gamePlayerControlControllerProvider).activePlayerId,
      'player_2',
    );
    expect(
      container.read(gameStateProvider(save.id)).value?.activePlayerId,
      'player_2',
    );

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(TechnologyTreePanel), findsOneWidget);
    container
        .read(hudCommandDispatcherProvider)
        .closeTechnologyPanel(
          activePlayerId: 'player_2',
          state: container.read(gameStateProvider(save.id)).value,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('settler_2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final selectedState = container.read(gameStateProvider(save.id)).value;
    expect(selectedState, isNotNull);
    expect(selectedState!.selectedUnitId, 'settler_2');
    expect(selectedState.canControlUnit(selectedState.selectedUnit!), isTrue);
    expect(find.byKey(const Key('selectionInfo.action.move')), findsOneWidget);
    container.read(hudCommandDispatcherProvider).startCityFounding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      container.read(gameStateProvider(save.id)).value?.cityFoundingDraft,
      isNotNull,
    );

    container.read(hudCommandDispatcherProvider).cancelCityFounding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      container.read(gameStateProvider(save.id)).value?.cityFoundingDraft,
      isNull,
    );

    await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      container.read(gameStateProvider(save.id)).value?.moveCommandActive,
      isTrue,
    );
  });

  testWidgets('deck global research action opens technology tree popup', (
    tester,
  ) async {
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );
    final empireFinder = find.byKey(const Key('globalHud.action.empire'));
    final empireRect = tester.getRect(empireFinder);
    final objectivesRect = tester.getRect(
      find.byKey(const Key('globalHud.action.objectives')),
    );

    expect(researchRect.left, lessThan(80));
    expect(objectivesRect.bottom, lessThan(researchRect.top));
    expect(researchRect.bottom, lessThan(empireRect.top));
    expect(empireRect.left, closeTo(researchRect.left, 0.1));

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
  });

  testWidgets('global objectives action opens objectives panel', (
    tester,
  ) async {
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    expect(find.text('OBJECTIVES'), findsNothing);

    await tester.tap(find.byKey(const Key('globalHud.action.objectives')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('OBJECTIVES'), findsOneWidget);
    expect(
      find.byKey(const Key('gameOptions.objectivesPanelViewport')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('gameOptions.objectivesPanelViewport')))
          .width,
      greaterThan(260),
    );
    expect(find.text('Choose research'), findsOneWidget);
    expect(find.text('Found your first city'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('globalHud.action.objectives')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('gameObjectives.close')), findsNothing);

    await tester.tap(find.byKey(const Key('globalHud.action.objectives')));
    await tester.pump();

    expect(find.text('OBJECTIVES'), findsNothing);
  });

  testWidgets('global action popup stays above the left menu', (tester) async {
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TechnologyTreePanel), findsOneWidget);
    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );

    await tester.tapAt(researchRect.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TechnologyTreePanel), findsOneWidget);
    expect(find.byType(EmpireOverviewPanel), findsNothing);
  });

  testWidgets(
    'left menu keeps objectives and activity log between options and help',
    (tester) async {
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: const GameState(activePlayerId: 'player_1'),
        ),
      );
      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      final gameState = container.read(gameStateProvider('save')).value!;
      container
          .read(hudMinimizedPopupsProvider.notifier)
          .minimize(
            HudMinimizedPopupEntry(
              id: HudMinimizedPopupIds.firstTurnTutorial('save'),
              kind: HudMinimizedPopupKind.firstTurnCoachmarks,
              title: 'Tutorial',
              subtitle: 'First-turn guide',
            ),
          );
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.agriculture,
        ),
      ], gameState);
      await tester.pump();

      final optionsRect = tester.getRect(
        find.byKey(const Key('gameOptions.optionsButton')),
      );
      final objectivesRect = tester.getRect(
        find.byKey(const Key('globalHud.action.objectives')),
      );
      final activityLogRect = tester.getRect(
        find.byKey(const Key('globalHud.action.activityLog')),
      );
      final helpRect = tester.getRect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
      );
      final researchRect = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final empireRect = tester.getRect(
        find.byKey(const Key('globalHud.action.empire')),
      );

      expect(optionsRect.top, lessThan(helpRect.top));
      expect(helpRect.top, lessThan(objectivesRect.top));
      expect(objectivesRect.top, lessThan(activityLogRect.top));
      expect(activityLogRect.top, lessThan(researchRect.top));
      expect(researchRect.top, lessThan(empireRect.top));
      expect(objectivesRect.center.dx, closeTo(activityLogRect.center.dx, 0.1));
    },
  );

  testWidgets('portrait phone keeps deck and side global actions anchored', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );
    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();

    final deckRect = tester.getRect(find.byType(HudActionDeck));
    final researchRect = tester.getRect(
      find.byKey(const Key('globalHud.action.research')),
    );
    final objectivesRect = tester.getRect(
      find.byKey(const Key('globalHud.action.objectives')),
    );
    final empireRect = tester.getRect(
      find.byKey(const Key('globalHud.action.empire')),
    );

    expect(researchRect.left, lessThan(80));
    expect(objectivesRect.bottom, lessThan(researchRect.top));
    expect(researchRect.bottom, lessThan(empireRect.top));
    expect(empireRect.left, closeTo(researchRect.left, 0.1));

    await tester.tap(find.byKey(const Key('globalHud.action.research')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final panelRect = tester.getRect(find.byType(TechnologyTreePanel));
    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    expect(panelRect.bottom, lessThanOrEqualTo(deckRect.top - 2));
  });

  testWidgets('screenshot QA viewports keep baseline HUD anchors stable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City 4',
      center: const CityHex(col: 1, row: 1),
      population: 17,
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final state = GameState(
      activePlayerId: 'player_1',
      cities: [city],
      playerGold: const {'player_1': 4496},
      interaction: GameInteractionState(
        selection: GameSelection.city(
          city,
          cityYield: const TileYield(
            food: 10,
            production: 35,
            gold: 0,
            defense: 0,
          ),
          playerColor: _player.colorValue,
        ),
      ),
    );
    const scenarios = [
      (name: 'compact portrait', size: Size(678, 1442)),
      (name: 'tablet portrait', size: Size(840, 1436)),
      (name: 'desktop wide', size: Size(2592, 1438)),
    ];

    for (final scenario in scenarios) {
      tester.view.physicalSize = scenario.size;
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(save: _save, state: state),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      final viewport = Offset.zero & scenario.size;
      final resourceStrip = tester.getRect(
        find.byKey(const Key('gameHud.resource.strip')),
      );
      final deck = tester.getRect(
        find.byKey(const Key('hudActionDeck.surface')),
      );
      final research = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final objectives = tester.getRect(
        find.byKey(const Key('globalHud.action.objectives')),
      );
      final empire = tester.getRect(
        find.byKey(const Key('globalHud.action.empire')),
      );

      _expectRectInside(
        resourceStrip,
        viewport,
        reason: '${scenario.name} resource strip',
      );
      _expectRectInside(deck, viewport, reason: '${scenario.name} deck');
      _expectRectInside(
        research,
        viewport,
        reason: '${scenario.name} research',
      );
      _expectRectInside(
        objectives,
        viewport,
        reason: '${scenario.name} objectives',
      );
      _expectRectInside(empire, viewport, reason: '${scenario.name} empire');
      expect(
        research.left,
        lessThan(80),
        reason: '${scenario.name} research in left menu',
      );
      expect(
        empire.left,
        lessThan(80),
        reason: '${scenario.name} empire in left menu',
      );
      expect(
        objectives.bottom,
        lessThan(research.top),
        reason: '${scenario.name} objectives in left menu',
      );
      expect(
        research.bottom,
        lessThan(empire.top),
        reason: '${scenario.name} research before empire',
      );
      expect(
        resourceStrip.bottom,
        lessThan(deck.top),
        reason: '${scenario.name} top strip above deck',
      );
      if (scenario.size.width >= 900) {
        expect(
          deck.width,
          lessThanOrEqualTo(HudActionDeck.wideMaxWidth + 1),
          reason: '${scenario.name} desktop deck max width',
        );
      }
      expect(
        find.byKey(const Key('gameHud.resource.identityRow')),
        findsNothing,
        reason: '${scenario.name} identity row removed',
      );
      expect(
        find.byKey(const Key('gameHud.resource.singleRow')),
        findsOneWidget,
        reason: '${scenario.name} single top row',
      );
    }
  });

  testWidgets('screenshot QA portrait technology panel clears action deck', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(activePlayerId: 'player_1'),
      ),
    );
    for (final size in const [Size(678, 1442), Size(840, 1436)]) {
      tester.view.physicalSize = size;

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();

      final deck = tester.getRect(
        find.byKey(const Key('hudActionDeck.surface')),
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final viewport = Offset.zero & size;
      final panel = tester.getRect(find.byType(TechnologyTreePanel));

      _expectRectInside(panel, viewport, reason: 'technology panel $size');
      expect(
        panel.bottom,
        lessThanOrEqualTo(deck.top - 2),
        reason: 'technology panel clears deck at $size',
      );
      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    }
  });

  testWidgets('screenshot QA portrait panels use warm mobile sheets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
      movementPoints: 0,
    );
    final activeResearch = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.mining,
        ),
      },
    );

    Future<void> verifyPanel({
      required Size size,
      required String name,
      required _FakeGameRepository repository,
      required Future<void> Function() openPanel,
      required Type panelType,
      required Key surfaceKey,
    }) async {
      tester.view.physicalSize = size;
      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final deck = tester.getRect(
        find.byKey(const Key('hudActionDeck.surface')),
      );

      await openPanel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final viewport = Offset.zero & size;
      final panel = tester.getRect(find.byType(panelType));
      final surface = tester.getRect(find.byKey(surfaceKey));
      final mobileSheet = tester.getRect(
        find.byKey(const Key('hudOverlayPanelSlot.mobileSheet')),
      );

      _expectRectInside(panel, viewport, reason: '$name panel in viewport');
      _expectRectInside(surface, viewport, reason: '$name surface in viewport');
      _expectRectContains(
        panel.inflate(1),
        surface,
        reason: '$name surface follows panel',
      );
      expect(
        panel.bottom,
        lessThanOrEqualTo(deck.top - 2),
        reason: '$name clears action deck',
      );
      expect(
        mobileSheet.width,
        greaterThanOrEqualTo(size.width - 32),
        reason: '$name uses near-full-width mobile sheet',
      );
      _expectWarmPanelSurface(tester, surfaceKey, reason: name);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    for (final size in const [
      Size(390, 844),
      Size(678, 1442),
      Size(840, 1436),
    ]) {
      await verifyPanel(
        size: size,
        name: 'technology $size',
        repository: _FakeGameRepository(
          snapshot: SaveSnapshot.fromGameState(
            save: _save,
            state: const GameState(activePlayerId: 'player_1'),
          ),
        ),
        openPanel: () =>
            tester.tap(find.byKey(const Key('globalHud.action.research'))),
        panelType: TechnologyTreePanel,
        surfaceKey: const Key('technologyTreePanel.surface'),
      );

      await verifyPanel(
        size: size,
        name: 'empire $size',
        repository: _FakeGameRepository(
          snapshot: SaveSnapshot.fromGameState(
            save: _save,
            state: GameState(
              activePlayerId: 'player_1',
              units: [warrior],
              cities: [
                city.copyWith(
                  productionQueue: CityProductionQueue.building(
                    buildingType: CityBuildingType.granary,
                    investedProduction: 0,
                  ),
                ),
              ],
              research: activeResearch,
            ),
          ),
        ),
        openPanel: () =>
            tester.tap(find.byKey(const Key('globalHud.action.empire'))),
        panelType: EmpireOverviewPanel,
        surfaceKey: const Key('empireOverviewPanel.surface'),
      );

      await verifyPanel(
        size: size,
        name: 'production $size',
        repository: _FakeGameRepository(
          snapshot: SaveSnapshot.fromGameState(
            save: _save,
            state: GameState(
              activePlayerId: 'player_1',
              cities: const [city],
              research: activeResearch,
              interaction: GameInteractionState(
                selection: GameSelection.city(
                  city,
                  cityYield: const TileYield(
                    food: 10,
                    production: 35,
                    gold: 0,
                    defense: 0,
                  ),
                  playerColor: _player.colorValue,
                ),
              ),
            ),
          ),
        ),
        openPanel: () => tester.tap(find.byType(EndTurnButton)),
        panelType: CityProductionPanel,
        surfaceKey: const Key('cityProductionPanel.surface'),
      );
    }
  });

  testWidgets(
    'portrait phone anchors action icons above the selection infobar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(activePlayerId: 'player_1', units: [warrior]),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SelectUnitCommand('warrior_1'));
      await tester.pump(const Duration(milliseconds: 240));

      final deckRect = tester.getRect(find.byType(HudActionDeck));
      final contextRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.context')),
      );
      final actionLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.actions')),
      );
      final commandLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.commands')),
      );
      final selectionSurfaceRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.selectionSurface')),
      );
      final actionRects = [
        for (
          var i = 0;
          i < tester.widgetList(find.byType(SelectionCommandChip)).length;
          i++
        )
          tester.getRect(find.byType(SelectionCommandChip).at(i)),
      ];
      final researchRect = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final actionsLeft = actionRects
          .map((rect) => rect.left)
          .reduce((a, b) => a < b ? a : b);
      final actionsRight = actionRects
          .map((rect) => rect.right)
          .reduce((a, b) => a > b ? a : b);
      final actionsCenter = (actionsLeft + actionsRight) / 2;

      expect(find.byType(SelectionActionBar), findsNothing);
      expect(find.byType(SelectionActionChip), findsNothing);
      expect(actionLineRect.top, greaterThanOrEqualTo(deckRect.top));
      expect(actionLineRect.bottom, lessThan(selectionSurfaceRect.top));
      expect(selectionSurfaceRect.contains(contextRect.center), isTrue);
      expect(commandLineRect.top, greaterThan(selectionSurfaceRect.bottom));
      expect(researchRect.left, lessThan(80));
      expect((actionsCenter - deckRect.center.dx).abs(), lessThanOrEqualTo(36));
    },
  );

  testWidgets(
    'landscape phone keeps action icons above compact bottom infobar',
    (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(activePlayerId: 'player_1', units: [warrior]),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await _disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SelectUnitCommand('warrior_1'));
      await tester.pump(const Duration(milliseconds: 240));

      final deckRect = tester.getRect(find.byType(HudActionDeck));
      final contextRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.context')),
      );
      final actionLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.actions')),
      );
      final commandLineRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.line.commands')),
      );
      final compactSurfaceRect = tester.getRect(
        find.byKey(const Key('hudActionDeck.compactSurface')),
      );
      final researchRect = tester.getRect(
        find.byKey(const Key('globalHud.action.research')),
      );
      final optionsRect = tester.getRect(
        find.byKey(const Key('gameOptions.optionsButton')),
      );
      final actionRects = [
        for (
          var i = 0;
          i < tester.widgetList(find.byType(SelectionCommandChip)).length;
          i++
        )
          tester.getRect(find.byType(SelectionCommandChip).at(i)),
      ];
      final actionsLeft = actionRects
          .map((rect) => rect.left)
          .reduce((a, b) => a < b ? a : b);
      final actionsRight = actionRects
          .map((rect) => rect.right)
          .reduce((a, b) => a > b ? a : b);
      final actionsCenter = (actionsLeft + actionsRight) / 2;

      expect(find.byType(SelectionActionBar), findsNothing);
      expect(find.byType(SelectionActionChip), findsNothing);
      expect(actionLineRect.top, greaterThanOrEqualTo(deckRect.top));
      expect(actionLineRect.bottom, lessThanOrEqualTo(compactSurfaceRect.top));
      expect(commandLineRect.left, greaterThan(contextRect.left));
      expect(
        (commandLineRect.center.dy - contextRect.center.dy).abs(),
        lessThanOrEqualTo(1),
      );
      expect(compactSurfaceRect.contains(contextRect.center), isTrue);
      expect(compactSurfaceRect.contains(commandLineRect.center), isTrue);
      expect(deckRect.height, lessThan(140));
      expect(
        compactSurfaceRect.left,
        greaterThanOrEqualTo(optionsRect.right + 8),
      );
      expect(researchRect.left, lessThan(80));
      expect((actionsCenter - deckRect.center.dx).abs(), lessThanOrEqualTo(36));
      expect(find.byType(EndTurnButton), findsOneWidget);
    },
  );

  testWidgets('tablet opens selection details as a modal sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 0,
      row: 1,
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(activePlayerId: 'player_1', units: [warrior]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('warrior_1'));
    await tester.pump(const Duration(milliseconds: 240));

    await tester.tap(find.byKey(const Key('hudActionDeck.context.terrain')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final detailRect = tester.getRect(
      find.byKey(const Key('selectionInfo.detailSheet.surface')),
    );
    final deckRect = tester.getRect(find.byType(HudActionDeck));

    expect(find.byType(SelectionActionBar), findsNothing);
    expect(detailRect.width, greaterThan(600));
    expect(detailRect.bottom, greaterThan(deckRect.top));
  });

  testWidgets('deck global empire action opens non-modal empire panel', (
    tester,
  ) async {
    final warriorA = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior A',
      col: 0,
      row: 1,
    );
    final warriorB = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior B',
      col: 1,
      row: 1,
    );
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: 'Worker',
      col: 2,
      row: 1,
    );
    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 2,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    const enemyCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Antium',
      center: CityHex(col: 2, row: 2),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          units: [warriorA, warriorB, worker, enemy],
          cities: const [city, enemyCity],
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('globalHud.action.empire')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EmpireOverviewPanel), findsOneWidget);
    expect(find.byType(EmpireOverviewDialog), findsNothing);
    expect(find.text('EMPIRE'), findsOneWidget);
    expect(find.text('Warrior'), findsWidgets);
    expect(find.text('2 units - 2 with movement'), findsOneWidget);
    expect(find.text('Worker'), findsWidgets);
    expect(find.text('Cities'), findsOneWidget);
    expect(find.text('Roma'), findsWidgets);
    expect(find.text('Enemy'), findsNothing);
    expect(find.text('Antium'), findsNothing);
  });

  testWidgets('empire panel can focus a unit or city from the map', (
    tester,
  ) async {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior A',
      col: 0,
      row: 1,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [warrior], cities: const [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    await tester.tap(find.byKey(const Key('globalHud.action.empire')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('empire.unit.warrior_1')));
    await tester.tap(find.byKey(const Key('empire.unit.warrior_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    var state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_1');
    expect(find.text('EMPIRE'), findsNothing);

    await tester.tap(find.byKey(const Key('globalHud.action.empire')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('empire.city.city_1')));
    await tester.tap(find.byKey(const Key('empire.city.city_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    state = container.read(gameStateProvider('save')).value;
    expect(state?.selection?.city?.id, 'city_1');
    expect(find.text('EMPIRE'), findsNothing);
  });

  testWidgets(
    'event notifications show concrete events and skip routine noise',
    (tester) async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker One',
        col: 2,
        row: 1,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Enemy One',
        col: 2,
        row: 2,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Roma',
        center: CityHex(col: 1, row: 1),
      );
      final state = GameState(
        cities: const [city],
        units: [worker, enemy],
        activePlayerId: 'player_1',
      );

      await _pumpHud(
        tester,
        repository: _FakeGameRepository(),
        autoActionFlowEnabled: false,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
        CityBuiltBuildingEvent(
          cityId: 'city_1',
          buildingType: CityBuildingType.granary,
        ),
        CityProducedUnitEvent(
          cityId: 'city_1',
          unitType: GameUnitType.worker,
          producedUnitId: 'worker_2',
        ),
        CityClaimedHexEvent(cityId: 'city_1', col: 2, row: 2),
        UnitMovedEvent(
          unitId: 'worker_1',
          fromCol: 1,
          fromRow: 1,
          toCol: 2,
          toRow: 1,
        ),
        TurnEndedEvent(playerId: 'player_1'),
        WorkerCompletedJobEvent(unitId: 'worker_1'),
        ResearchPointsGainedEvent(playerId: 'player_1', points: 7),
        TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.agriculture,
        ),
      ], state);
      await tester.pump();

      expect(find.text('City founded'), findsOneWidget);
      expect(find.text('Construction complete'), findsOneWidget);
      expect(find.text('Unit trained'), findsOneWidget);
      expect(find.text('+3 more ↓'), findsOneWidget);
      expect(find.text('City borders'), findsNothing);
      expect(find.text('Unit movement'), findsNothing);
      expect(find.text('Turn ended'), findsNothing);
      expect(find.text('Work complete'), findsNothing);
      expect(find.text('Science'), findsNothing);
      expect(find.text('Technology discovered'), findsNothing);

      container.read(gameEventNotificationsProvider.notifier).clear();
      await tester.pump();
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        CityClaimedHexEvent(cityId: 'city_1', col: 2, row: 2),
        WorkerCompletedJobEvent(unitId: 'worker_1'),
        TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.agriculture,
        ),
      ], state);
      await tester.pump();

      expect(find.text('City borders'), findsOneWidget);
      expect(find.text('Work complete'), findsOneWidget);
      expect(find.text('Technology discovered'), findsWidgets);
      expect(find.textContaining('more'), findsNothing);

      container.read(gameEventNotificationsProvider.notifier).clear();
      await tester.pump();
      container.read(gameEventNotificationsProvider.notifier).addAll([
        const UnitAttackedEvent(
          attackerUnitId: 'worker_1',
          attackerOwnerPlayerId: 'player_1',
          defenderUnitId: 'enemy_1',
          defenderOwnerPlayerId: 'player_2',
        ),
        CombatResolvedEvent(
          attackerUnitId: 'worker_1',
          defenderUnitId: 'enemy_1',
          outcome: CombatOutcome(
            attackerUnitId: 'worker_1',
            defenderUnitId: 'enemy_1',
            attackerHpAfter: 1,
            defenderHpAfter: 0,
            attackerKilled: false,
            defenderKilled: true,
            steps: [
              const ModifierAppliedStep(
                TerrainModifier(
                  label: 'terrain.forest.defense',
                  target: CombatStatTarget.defense,
                  delta: 1,
                ),
              ),
              const RollStep(seed: 42, value: -1),
              AttackStep(
                damage: 3,
                active: const [
                  TerrainModifier(
                    label: 'terrain.forest.defense',
                    target: CombatStatTarget.defense,
                    delta: 1,
                  ),
                ],
              ),
              RetaliationStep(damage: 1),
            ],
          ),
        ),
        const UnitKilledEvent(unitId: 'worker_1', ownerPlayerId: 'player_1'),
        const UnitRetreatedEvent(
          unitId: 'worker_1',
          ownerPlayerId: 'player_1',
          fromCol: 2,
          fromRow: 1,
          toCol: 1,
          toRow: 1,
        ),
        const CityCapturedEvent(
          cityId: 'city_1',
          previousOwnerPlayerId: 'player_2',
          newOwnerPlayerId: 'player_1',
        ),
      ], state);
      await tester.pump();

      expect(find.text('Attack'), findsNothing);
      expect(find.text('Combat'), findsOneWidget);
      expect(
        find.textContaining('Enemy One: -3 HP -> defeated'),
        findsOneWidget,
      );
      expect(find.textContaining('Worker One: -1 HP -> 1 HP'), findsOneWidget);
      expect(find.text('Defender defeated'), findsNothing);
      expect(find.text('Terrain forest defense +1'), findsNothing);
      expect(find.text('Roll -1'), findsNothing);
      expect(find.text('Attack: -3 HP'), findsNothing);
      expect(find.text('Retaliation: -1 HP'), findsNothing);
      expect(find.text('Unit defeated'), findsOneWidget);
      expect(find.text('Retreat'), findsOneWidget);
      expect(find.text('+1 more ↓'), findsOneWidget);
      expect(find.text('City captured'), findsNothing);

      container.read(gameEventNotificationsProvider.notifier).clear();
      await tester.pump();
      container.read(gameEventNotificationsProvider.notifier).addAll(const [
        CityCapturedEvent(
          cityId: 'city_1',
          previousOwnerPlayerId: 'player_2',
          newOwnerPlayerId: 'player_1',
        ),
      ], state);
      await tester.pump();

      expect(find.text('City captured'), findsOneWidget);
    },
  );

  testWidgets('notification overflow opens the activity log panel', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    const state = GameState(cities: [city], activePlayerId: 'player_1');

    await _pumpHud(tester, repository: _FakeGameRepository());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
      CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      CityProducedUnitEvent(
        cityId: 'city_1',
        unitType: GameUnitType.worker,
        producedUnitId: 'worker_2',
      ),
      CityClaimedHexEvent(cityId: 'city_1', col: 2, row: 2),
    ], state);
    await tester.pump();

    expect(find.text('+1 more ↓'), findsOneWidget);
    expect(find.text('City borders'), findsNothing);

    await tester.tap(find.text('+1 more ↓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityLogPanel), findsOneWidget);
    _expectWarmPanelSurface(
      tester,
      const Key('activityLogPanel.surface'),
      reason: 'activity log panel surface',
    );
    expect(find.text('ACTIVITY LOG'), findsOneWidget);
    expect(find.text('City borders'), findsOneWidget);
  });

  testWidgets('event notifications are painted above HUD controls', (
    tester,
  ) async {
    await _pumpHud(tester, repository: _FakeGameRepository());

    final stack = tester.widget<Stack>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Stack &&
            widget.children.any((child) => child is GameOptionsOverlay) &&
            widget.children.any(
              (child) => child is GameEventNotificationsOverlay,
            ),
      ),
    );
    final optionsIndex = stack.children.indexWhere(
      (child) => child is GameOptionsOverlay,
    );
    final hudIndex = stack.children.indexWhere(
      (child) => child is GameHudOverlayHost,
    );
    final notificationsIndex = stack.children.indexWhere(
      (child) => child is GameEventNotificationsOverlay,
    );

    expect(notificationsIndex, greaterThan(optionsIndex));
    expect(notificationsIndex, greaterThan(hudIndex));
  });

  testWidgets('large HUD panels are painted above side controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpHud(tester, repository: _FakeGameRepository());

    final stack = tester.widget<Stack>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Stack &&
            widget.children.any((child) => child is GameOptionsOverlay) &&
            widget.children.any((child) => child is GameHudOverlayPanelsHost),
      ),
    );
    final optionsIndex = stack.children.indexWhere(
      (child) => child is GameOptionsOverlay,
    );
    final hudIndex = stack.children.indexWhere(
      (child) => child is GameHudOverlayHost,
    );
    final panelsIndex = stack.children.indexWhere(
      (child) => child is GameHudOverlayPanelsHost,
    );

    expect(panelsIndex, greaterThan(optionsIndex));
    expect(panelsIndex, greaterThan(hudIndex));
  });

  testWidgets('event notifications only show the active players own events', (
    tester,
  ) async {
    const ownCity = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    const otherCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Enemy City',
      center: CityHex(col: 2, row: 2),
    );
    final hotseatSave = GameSave(
      id: 'save',
      name: 'Game',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 1,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 4, 16),
      camera: CameraState.zero,
      players: const [_player, _player2],
    );
    const state = GameState(
      cities: [ownCity, otherCity],
      activePlayerId: 'player_1',
    );

    await _pumpHud(
      tester,
      repository: _FakeGameRepository(),
      gameSave: hotseatSave,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      CityBuiltBuildingEvent(
        cityId: 'city_2',
        buildingType: CityBuildingType.barracks,
      ),
      ResearchPointsGainedEvent(playerId: 'player_2', points: 9),
    ], state);
    await tester.pump();

    expect(find.text('Construction complete'), findsOneWidget);
    expect(find.textContaining('Roma'), findsOneWidget);
    expect(find.textContaining('Enemy City'), findsNothing);
    expect(find.text('Science'), findsNothing);
  });

  testWidgets('event notifications fade away one by one automatically', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    const state = GameState(cities: [city], activePlayerId: 'player_1');

    await _pumpHud(tester, repository: _FakeGameRepository());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      CityBuiltBuildingEvent(
        cityId: 'city_1',
        buildingType: CityBuildingType.granary,
      ),
      TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
    ], state);
    await tester.pump();

    expect(find.text('Construction complete'), findsOneWidget);
    expect(find.text('Technology discovered'), findsWidgets);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Construction complete'), findsNothing);
    expect(find.text('Technology discovered'), findsWidgets);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Technology discovered'), findsWidgets);
  });

  testWidgets('tapping combat notification focuses a surviving participant', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 1,
      movementPoints: 0,
    );
    final activeResearch = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.mining,
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          units: [attacker],
          activePlayerId: 'player_1',
          research: activeResearch,
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final postCombatState = container.read(gameStateProvider('save')).value!;

    container.read(gameEventNotificationsProvider.notifier).addAll([
      CombatResolvedEvent(
        attackerUnitId: 'warrior_1',
        defenderUnitId: 'enemy_1',
        outcome: CombatOutcome(
          attackerUnitId: 'warrior_1',
          defenderUnitId: 'enemy_1',
          attackerHpAfter: 3,
          defenderHpAfter: 0,
          attackerKilled: false,
          defenderKilled: true,
          steps: [AttackStep(damage: 3)],
        ),
      ),
    ], postCombatState);
    await tester.pump();

    expect(container.read(gameEventNotificationsProvider), hasLength(1));
    expect(find.text('Combat'), findsOneWidget);

    await tester.tap(find.text('Combat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_1');
    expect(container.read(gameEventNotificationsProvider), isEmpty);
    expect(find.text('Combat'), findsNothing);
  });

  testWidgets('activity log keeps combat details after notification fades', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 2,
      row: 1,
    );
    final activeResearch = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.mining,
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          units: [attacker],
          activePlayerId: 'player_1',
          research: activeResearch,
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    final postCombatState = container.read(gameStateProvider('save')).value!;

    container.read(gameEventNotificationsProvider.notifier).addAll([
      CombatResolvedEvent(
        attackerUnitId: 'warrior_1',
        defenderUnitId: 'enemy_1',
        outcome: CombatOutcome(
          attackerUnitId: 'warrior_1',
          defenderUnitId: 'enemy_1',
          attackerHpAfter: 3,
          defenderHpAfter: 0,
          attackerKilled: false,
          defenderKilled: true,
          steps: [const RollStep(seed: 77, value: 1), AttackStep(damage: 3)],
        ),
      ),
    ], postCombatState);
    await tester.pump();

    expect(find.text('Combat'), findsWidgets);
    expect(
      find.byKey(const Key('globalHud.action.activityLog')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Combat'), findsNothing);

    container
        .read(hudCommandDispatcherProvider)
        .openActivityLogPanel(
          activePlayerId: 'player_1',
          state: container.read(gameStateProvider('save')).value,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityLogPanel), findsOneWidget);
    expect(find.byType(ActivityLogDialog), findsNothing);
    expect(find.text('ACTIVITY LOG'), findsOneWidget);
    expect(find.text('Combat'), findsWidgets);
    expect(find.text('Roll 1'), findsOneWidget);
    expect(find.text('Attack: -3 HP'), findsOneWidget);
  });

  testWidgets(
    'worker improve action selects and confirms from the bottom sheet',
    (tester) async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(units: [worker], cities: [city], research: research),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SelectUnitCommand('worker_1'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('selectionInfo.action.improve')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('selectionInfo.action.work')), findsNothing);
      expect(find.text('Work fields'), findsNothing);

      await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingWorkerActionSelection>(),
      );
      expect(find.byType(SelectionDetailSheet), findsOneWidget);
      expect(find.text('Tile improvement'), findsOneWidget);
      expect(find.text('Choose improvement'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('selectionInfo.workerBuild.confirm')),
        findsOneWidget,
      );
      expect(find.text('Work fields'), findsNothing);

      await tester.tap(
        find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final selectedAction =
          container.read(gameStateProvider('save')).value?.pendingAction
              as PendingWorkerActionSelection?;
      expect(selectedAction?.improvementType, FieldImprovementType.farm);
      expect(find.text('Selected: Farm'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('selectionInfo.workerBuild.confirm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final updatedWorker = container
          .read(gameStateProvider('save'))
          .value
          ?.units
          .singleWhere((unit) => unit.id == 'worker_1');
      expect(
        updatedWorker?.workerJob?.improvementType,
        FieldImprovementType.farm,
      );
    },
  );

  testWidgets('portrait worker improve action opens selection sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          activePlayerId: 'player_1',
          units: [worker],
          cities: const [city],
          research: research,
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('worker_1'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingWorkerActionSelection>(),
    );
    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(find.text('Tile improvement'), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.option.farm')),
      findsOneWidget,
    );
    expect(find.text('Work fields'), findsNothing);
    expect(
      find.byKey(const Key('selectionInfo.action.cancel')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selectionInfo.action.work')), findsNothing);
  });

  testWidgets('worker work toolbar action is not exposed for ready fields', (
    tester,
  ) async {
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    const farm = FieldImprovement(
      hex: CityHex(col: 1, row: 0),
      type: FieldImprovementType.farm,
      builtByCityId: 'city_1',
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          activePlayerId: 'player_1',
          units: [worker],
          cities: const [city],
          fieldImprovements: const [farm],
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('worker_1'));
    await tester.pump(const Duration(milliseconds: 500));

    final selectedWorker = container
        .read(gameStateProvider('save'))
        .value
        ?.units
        .singleWhere((unit) => unit.id == 'worker_1');
    expect(selectedWorker?.workerAssignment, isNull);
    expect(
      find.byKey(const Key('selectionInfo.action.improve')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('selectionInfo.action.work')), findsNothing);
    expect(find.text('Field ready to work'), findsNothing);
    expect(find.text('Work fields'), findsNothing);
  });

  testWidgets('worker build popup cancel clears pending selection', (
    tester,
  ) async {
    final worker = GameUnit(
      id: 'worker_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: GameUnitType.worker.defaultNameToken,
      col: 1,
      row: 0,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.agriculture},
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [worker], cities: [city], research: research),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('worker_1'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingWorkerActionSelection>(),
    );
    expect(find.byType(SelectionDetailSheet), findsOneWidget);
    expect(
      find.byKey(const Key('selectionInfo.workerBuild.cancel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('selectionInfo.workerBuild.cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isNull,
    );
    expect(find.byKey(const Key('hudModeBanner.workerAction')), findsNothing);
  });

  testWidgets(
    'selected worker action hint restores from help and starts improvement',
    (tester) async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(
            activePlayerId: 'player_1',
            units: [worker],
            cities: const [city],
            research: research,
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SelectUnitCommand('worker_1'));
      await tester.pump(const Duration(milliseconds: 500));
      await _cancelMoveTargetingBanner(tester);

      final popupId = HudMinimizedPopupIds.modeBanner(
        'save',
        'selectedWorkerAction',
      );
      expect(
        find.byKey(const Key('hudModeBanner.selectedWorkerAction')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
        findsOneWidget,
      );

      await _openHelpEntryById(tester, popupId);

      expect(
        find.byKey(const Key('hudModeBanner.selectedWorkerAction')),
        findsOneWidget,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        false,
      );

      await tester.tap(find.byKey(const Key('selectionInfo.action.improve')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingWorkerActionSelection>(),
      );
      expect(find.byKey(const Key('hudModeBanner.workerAction')), findsNothing);
    },
  );

  testWidgets(
    'blocked worker hint explains that the field is already improved',
    (tester) async {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      const farm = FieldImprovement(
        hex: CityHex(col: 1, row: 0),
        type: FieldImprovementType.farm,
        builtByCityId: 'city_1',
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(
            activePlayerId: 'player_1',
            units: [worker],
            cities: const [city],
            fieldImprovements: const [farm],
          ),
        ),
      );

      await _pumpHud(tester, repository: repository);
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SelectUnitCommand('worker_1'));
      await tester.pump(const Duration(milliseconds: 500));
      await _cancelMoveTargetingBanner(tester);

      expect(
        find.byKey(const Key('hudModeBanner.selectedWorkerMoveToWork')),
        findsNothing,
      );

      await _openHelpEntryById(
        tester,
        HudMinimizedPopupIds.modeBanner('save', 'selectedWorkerMoveToWork'),
      );

      expect(find.text('Worker: find a tile'), findsOneWidget);
      expect(
        find.textContaining('This tile already has an improvement.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.moveCommandActive,
        isTrue,
      );
    },
  );

  testWidgets('blocked settler hint starts movement toward a better site', (
    tester,
  ) async {
    final settler = GameUnit(
      id: 'settler_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.settler,
      name: GameUnitType.settler.defaultNameToken,
      col: 1,
      row: 1,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          activePlayerId: 'player_1',
          units: [settler],
          cities: const [city],
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('settler_1'));
    await tester.pump(const Duration(milliseconds: 500));
    await _cancelMoveTargetingBanner(tester);

    expect(
      find.byKey(const Key('hudModeBanner.selectedSettlerMoveToCitySite')),
      findsNothing,
    );

    await _openHelpEntryById(
      tester,
      HudMinimizedPopupIds.modeBanner('save', 'selectedSettlerMoveToCitySite'),
    );

    expect(find.text('Settler: find a site'), findsOneWidget);
    expect(find.textContaining('Move the settler'), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.moveCommandActive,
      isTrue,
    );
  });

  testWidgets('skip action can be cancelled to restore movement', (
    tester,
  ) async {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
      movementPoints: 2,
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [warrior]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('warrior_1'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    var state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.movementPoints, 0);
    expect(state.pendingAction, isA<PendingUnitTurnSkip>());
    expect(find.byKey(const Key('selectionInfo.action.skip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('selectionInfo.action.skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.movementPoints, 2);
    expect(state.pendingAction, isNull);
    expect(find.byKey(const Key('selectionInfo.action.skip')), findsOneWidget);
  });

  testWidgets('heal action can be cancelled', (tester) async {
    final warrior = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
      movementPoints: 2,
    ).copyWithHitPoints(7);
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [warrior]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectUnitCommand('warrior_1'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('selectionInfo.action.heal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    var state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.movementPoints, 0);
    expect(state.units.single.posture, UnitPosture.fortified);
    expect(state.pendingAction, isNull);
    expect(
      find.byKey(const Key('selectionInfo.action.stopHealing')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('selectionInfo.action.stopHealing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    state = container.read(gameStateProvider('save')).value!;
    expect(state.units.single.posture, UnitPosture.active);
    expect(state.moveCommandActive, isTrue);
    expect(find.byKey(const Key('selectionInfo.action.move')), findsOneWidget);
  });

  testWidgets('attack target opens prediction popup before confirming combat', (
    tester,
  ) async {
    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 2,
    );
    final defender = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 1,
      row: 0,
      movementPoints: 2,
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          activePlayerId: 'player_1',
          units: [attacker, defender],
          fogOfWar: FogOfWarState(
            players: {
              'player_1': PlayerFogOfWar(
                playerId: 'player_1',
                visibleHexes: {
                  const HexCoordinate(col: 0, row: 0),
                  const HexCoordinate(col: 1, row: 0),
                },
              ),
            },
          ),
          interaction: GameInteractionState(
            selection: GameSelection.unit(attacker),
          ),
        ),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const StartAttackTargetingCommand('warrior_1'));
    await tester.pump();
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const TileTappedCommand(1, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    var state = container.read(gameStateProvider('save')).value!;
    final pending = state.pendingAction as PendingAttackTargeting;
    expect(pending.defenderCol, 1);
    expect(pending.defenderRow, 0);
    expect(find.byKey(const Key('hudCombatConfirm.surface')), findsOneWidget);
    expect(find.text('Confirm attack'), findsAtLeastNWidgets(1));
    expect(find.text('Why this forecast?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hudCombatConfirm.confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    state = container.read(gameStateProvider('save')).value!;
    expect(state.pendingAction, isNull);
    expect(
      state.units.singleWhere((unit) => unit.id == 'warrior_1').movementPoints,
      0,
    );
    expect(find.byKey(const Key('hudCombatConfirm.surface')), findsNothing);
  });

  testWidgets('action button opens non-modal city production panel', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: const GameState(cities: [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CityProductionPanel), findsOneWidget);
    expect(find.byType(CityProductionDialog), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CityProductionPanel),
        matching: find.byKey(const Key('cityProductionHeader.cityName')),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('PRODUCTION'), findsWidgets);
    expect(find.text('Granary'), findsOneWidget);
    final productionScroll = find
        .descendant(
          of: find.byType(CityProductionPanel),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Wealth'),
      220,
      scrollable: productionScroll,
    );
    expect(find.text('CITY PROJECTS'), findsOneWidget);
    expect(find.text('Wealth'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Research'),
      120,
      scrollable: productionScroll,
    );
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('BUILDING'), findsNothing);
    expect(find.text('UNIT'), findsNothing);
  });

  testWidgets(
    'action button opens technology tree after the last map action resolves',
    (tester) async {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 1,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 1, row: 1),
        controlledHexes: const [CityHex(col: 1, row: 1)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(units: [unit], cities: [city]),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        unit.id,
      );
      expect(find.text('TECHNOLOGY TREE'), findsNothing);

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(SkipUnitTurnCommand(unit.id));
      await _pumpUntil(
        tester,
        () =>
            container
                .read(gameStateProvider('save'))
                .value!
                .units
                .singleWhere((candidate) => candidate.id == unit.id)
                .movementPoints ==
            0,
        frames: 20,
      );

      expect(find.text('TECHNOLOGY TREE'), findsNothing);

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(TechnologyTreePanel),
          matching: find.byTooltip('Close'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TECHNOLOGY TREE'), findsNothing);
      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isNull,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const TileTappedCommand(0, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('TECHNOLOGY TREE'), findsNothing);
      expect(
        container.read(gameStateProvider('save')).value?.selection?.tile,
        isNotNull,
      );

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    },
  );

  testWidgets('next action button focuses unit before missing research', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [unit], cities: [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectTileCommand(2, 2));
    await tester.pump();

    expect(find.text('ACTION'), findsOneWidget);
    expect(find.text('Next step: Warrior'), findsNothing);
    expect(find.text('Next step: choose research'), findsNothing);

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );
    expect(find.text('TECHNOLOGY TREE'), findsNothing);

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
  });

  testWidgets('Auto action is enabled and auto turn is disabled by default', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [unit], cities: [city]),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(tester, repository: repository, renderer: renderer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(find.text('ACTION'), findsOneWidget);
    expect(container.read(hudAutoActionFlowProvider), isTrue);
    expect(container.read(hudAutoTurnFlowProvider), isFalse);
    expect(find.byKey(const Key('endTurnButton.autoCheck')), findsNothing);
    expect(find.byKey(const Key('endTurnButton.autoChevron')), findsNothing);
    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );
  });

  testWidgets('Auto turn hint opens from help without action buttons', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [unit], cities: [city]),
      ),
    );

    await _pumpHud(
      tester,
      repository: repository,
      autoActionFlowEnabled: false,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    expect(find.byKey(const Key('hudAutoTurnHint')), findsNothing);
    expect(container.read(hudAutoTurnFlowProvider), isFalse);

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();
    await tester.tap(find.text('Auto turn completion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Auto turn completion'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.byKey(const Key('hudAutoTurnHint.toggle')), findsNothing);
    expect(container.read(hudAutoTurnFlowProvider), isFalse);

    final hintRect = tester.getRect(find.byKey(const Key('hudAutoTurnHint')));
    final optionsRect = tester.getRect(
      find.byKey(const Key('gameOptions.optionsButton')),
    );
    expect(hintRect.left, greaterThan(optionsRect.right));

    await tester.tap(find.byKey(const Key('hudAutoTurnHint.minimize')));
    await tester.pump();

    final popupId = HudMinimizedPopupIds.autoTurnHint('save');
    expect(find.byKey(const Key('hudAutoTurnHint')), findsNothing);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
      isTrue,
    );
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton.attentionGlow')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('gameOptions.helpPopupsButton')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton.attentionGlow')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
    await tester.pump();
    await tester.tap(find.byKey(Key('gameOptions.helpPopup.$popupId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('hudAutoTurnHint')), findsOneWidget);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
      isFalse,
    );
    expect(
      find.byKey(const Key('gameOptions.helpPopupsButton')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('gameOptions.helpPopupsButton')),
        matching: find.text('1'),
      ),
      findsNothing,
    );
    expect(container.read(hudAutoTurnFlowProvider), isFalse);
  });

  testWidgets(
    'Enabled Auto opens research action without dismissing the prompt',
    (tester) async {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 0,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 1, row: 1),
        controlledHexes: const [CityHex(col: 1, row: 1)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(units: [unit], cities: [city]),
        ),
      );

      await _pumpHud(tester, repository: repository);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await _pumpUntil(
        tester,
        () =>
            find.text('TECHNOLOGY TREE').evaluate().isNotEmpty &&
            container.read(gameStateProvider('save')).value?.pendingAction
                is PendingResearchSelection,
        frames: 8,
      );

      expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isA<PendingResearchSelection>(),
      );
      final researchActionKey = hudResearchActionKey(
        save: repository.snapshot.save,
        activePlayerId: 'player_1',
      );
      expect(researchActionKey, isNotNull);
      expect(
        container.read(hudResearchAutoPromptControllerProvider),
        isNot(contains(researchActionKey)),
      );
    },
  );

  testWidgets(
    'Enabled Auto continues after the selected unit spends movement',
    (tester) async {
      final map = _makeMap();
      final firstUnit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 1,
      );
      final nextUnit = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 2,
        row: 1,
        movementPoints: 1,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [CityHex(col: 2, row: 2)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(
            units: [firstUnit, nextUnit],
            cities: [city],
            research: research,
            interaction: GameInteractionState(
              selection: GameSelection.unit(
                firstUnit,
                tile: map.tileAt(firstUnit.col, firstUnit.row),
              ),
            ),
          ),
        ),
      );

      await _pumpHud(tester, repository: repository);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SelectUnitCommand('warrior_1'));
      await tester.pump();

      expect(container.read(hudAutoTurnFlowProvider), isTrue);
      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_1',
      );
      await tester.pump();

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const MoveUnitCommand('warrior_1', 1, 1));

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (container.read(gameStateProvider('save')).value?.selectedUnitId ==
            'warrior_2') {
          break;
        }
      }

      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_2',
      );
    },
  );

  testWidgets(
    'Enabled Auto lets the player inspect a city while a unit can move',
    (tester) async {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 1,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [CityHex(col: 2, row: 2)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(units: [unit], cities: [city], research: research),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        renderer: renderer,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _enableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_1',
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const CityTappedCommand('city_1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final state = container.read(gameStateProvider('save')).value;
      expect(state?.selection?.city?.id, 'city_1');
      expect(state?.selectedUnitId, isNull);
      expect(state?.units.single.movementPoints, 1);

      renderer.handledEffects.clear();

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final focusedState = container.read(gameStateProvider('save')).value;
      expect(focusedState?.selectedUnitId, 'warrior_1');
      expect(
        renderer.handledEffects.whereType<SmoothCameraEffect>().any(
          (effect) => effect.col == unit.col && effect.row == unit.row,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'action button advances from open city production panel to remaining unit',
    (tester) async {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 1,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 2, row: 2)],
        productionQueue: null,
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(units: [unit], cities: [city], research: research),
        ),
      );
      final renderer = _SpyGameRenderer(mapData: _makeMap());

      await _pumpHud(
        tester,
        repository: repository,
        renderer: renderer,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _disableAutoTurnFlow(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const CityTappedCommand('city_1'));
      await tester.pump();
      container
          .read(hudCommandDispatcherProvider)
          .openCityProductionPanel(
            state: container.read(gameStateProvider('save')).value,
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CityProductionPanel), findsOneWidget);
      expect(
        container.read(gameStateProvider('save')).value?.selection?.city?.id,
        'city_1',
      );

      renderer.handledEffects.clear();

      await tester.tap(find.byType(EndTurnButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final focusedState = container.read(gameStateProvider('save')).value;
      expect(find.byType(CityProductionPanel), findsNothing);
      expect(focusedState?.selectedUnitId, 'warrior_1');
      expect(focusedState?.moveCommandActive, isTrue);
      expect(
        renderer.handledEffects.whereType<SmoothCameraEffect>().any(
          (effect) => effect.col == unit.col && effect.row == unit.row,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Auto action mode stops before ending turn when auto turn is disabled',
    (tester) async {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 1, row: 1),
        controlledHexes: const [CityHex(col: 1, row: 1)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: GameState(units: [unit], cities: [city], research: research),
        ),
      );

      await _pumpHud(tester, repository: repository);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      expect(container.read(hudAutoActionFlowProvider), isTrue);
      expect(container.read(hudAutoTurnFlowProvider), isFalse);
      expect(
        container.read(gameStateProvider('save')).value?.selectedUnitId,
        'warrior_1',
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const SkipUnitTurnCommand('warrior_1'));
      await tester.pump();
      await tester.runAsync(() async {
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();

      expect(repository.snapshot.save.turn, _save.turn);
      expect(
        container.read(gameStateProvider('save')).value?.submittedPlayerIds,
        isEmpty,
      );
    },
  );

  testWidgets('Auto action mode ends the turn after the last action resolves', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [unit], cities: [city], research: research),
      ),
    );

    await _pumpHud(tester, repository: repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _enableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    await tester.tap(find.text('ACTION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SkipUnitTurnCommand('warrior_1'));
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        if (repository.snapshot.save.turn > _save.turn) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(repository.snapshot.save.turn, _save.turn + 1);
  });

  testWidgets('next action button cycles between movable units', (
    tester,
  ) async {
    final firstUnit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
    );
    final secondUnit = GameUnit(
      id: 'warrior_2',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 2,
      row: 1,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(
          activeTechnologyId: TechnologyId.agriculture,
        ),
      },
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(
          units: [firstUnit, secondUnit],
          cities: [city],
          research: research,
        ),
      ),
    );
    final renderer = _SpyGameRenderer(mapData: _makeMap());

    await _pumpHud(
      tester,
      repository: repository,
      renderer: renderer,
      autoActionFlowEnabled: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _disableAutoTurnFlow(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );
    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const SelectTileCommand(2, 2));
    await tester.pump();

    expect(
      find.byKey(const Key('endTurnButton.actionProgress')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('endTurnButton.actionProgress')))
          .data,
      '1/2',
    );

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      container.read(gameStateProvider('save')).value?.selectedUnitId,
      'warrior_1',
    );
    expect(
      container.read(gameStateProvider('save')).value?.moveCommandActive,
      isTrue,
    );
    renderer.handledEffects.clear();

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsNothing);
    final state = container.read(gameStateProvider('save')).value;
    expect(state?.selectedUnitId, 'warrior_2');
    expect(state?.moveCommandActive, isTrue);
    expect(state?.pendingAction, isNull);
    expect(
      renderer.handledEffects.whereType<SmoothCameraEffect>().any(
        (effect) =>
            effect.col == secondUnit.col && effect.row == secondUnit.row,
      ),
      isTrue,
    );
  });

  testWidgets('closing action-opened technology tree restores map selection', (
    tester,
  ) async {
    final unit = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 1,
      movementPoints: 0,
    );
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 1)],
      productionQueue: CityProductionQueue.building(
        buildingType: CityBuildingType.granary,
        investedProduction: 0,
      ),
    );
    final repository = _FakeGameRepository(
      snapshot: SaveSnapshot.fromGameState(
        save: _save,
        state: GameState(units: [unit], cities: [city]),
      ),
    );

    await _pumpHud(tester, repository: repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHud)),
      listen: false,
    );

    await tester.tap(find.byType(EndTurnButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsOneWidget);
    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isA<PendingResearchSelection>(),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(TechnologyTreePanel),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TECHNOLOGY TREE'), findsNothing);
    expect(
      container.read(gameStateProvider('save')).value?.pendingAction,
      isNull,
    );

    await container
        .read(gameCommandControllerProvider.notifier)
        .dispatch(const TileTappedCommand(0, 1));
    await tester.pump();

    expect(
      container.read(gameStateProvider('save')).value?.selection?.unit?.id,
      'warrior_1',
    );
  });

  testWidgets(
    'question menu keeps minimized mode banners visible after context changes',
    (tester) async {
      const pendingResearch = PendingResearchSelection(
        ownerPlayerId: 'player_1',
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: _save,
          state: const GameState(
            activePlayerId: 'player_1',
            interaction: GameInteractionState(pendingAction: pendingResearch),
          ),
        ),
      );

      await _pumpHud(
        tester,
        repository: repository,
        autoActionFlowEnabled: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );
      final popupId = HudMinimizedPopupIds.modeBanner(
        'save',
        'researchSelection',
      );
      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsNothing,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();
      await tester.tap(find.text('Choose research'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsOneWidget,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('hudModeBanner.minimize')));
      await tester.pump();

      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsNothing,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isTrue,
      );

      await container
          .read(gameCommandControllerProvider.notifier)
          .dispatch(const CancelResearchSelectionCommand('player_1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isNull,
      );
      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsNothing,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isTrue,
      );

      expect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();

      expect(find.text('Choose research'), findsOneWidget);

      await tester.tap(find.text('Choose research'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(gameStateProvider('save')).value?.pendingAction,
        isNull,
      );
      expect(
        find.byKey(const Key('hudModeBanner.researchSelection')),
        findsOneWidget,
      );
      expect(
        container.read(hudMinimizedPopupsProvider).hasEntry(popupId),
        isTrue,
      );
    },
  );

  testWidgets(
    'question menu opens tutorial and auto turn after player finished',
    (tester) async {
      final finishedSave = _save.copyWith(
        playerStates: const {'player_1': PlayerTurnState.finished},
      );
      final repository = _FakeGameRepository(
        snapshot: SaveSnapshot.fromGameState(
          save: finishedSave,
          state: const GameState(activePlayerId: 'player_1'),
        ),
      );

      await _pumpHud(tester, repository: repository, gameSave: finishedSave);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameHud)),
        listen: false,
      );

      expect(
        find.byKey(const Key('gameOptions.helpPopupsButton')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();

      expect(find.text('Tutorial'), findsOneWidget);
      expect(find.text('Auto turn completion'), findsOneWidget);

      await tester.tap(find.text('Tutorial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('firstTurnCoachmarks.overlay')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('firstTurnCoachmarks.minimize')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
      await tester.pump();
      await tester.tap(find.text('Auto turn completion'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('hudAutoTurnHint')), findsOneWidget);
      expect(find.byKey(const Key('hudAutoTurnHint.toggle')), findsNothing);
      expect(container.read(hudAutoTurnFlowProvider), isFalse);
    },
  );

  testWidgets('close button autosaves camera before leaving', (tester) async {
    final repository = _FakeGameRepository();
    var closed = false;

    await _pumpHud(
      tester,
      repository: repository,
      onClose: () => closed = true,
    );

    await tester.tap(find.text('✕'));
    await tester.pump();

    expect(repository.savedCamera, isNotNull);
    expect(closed, isTrue);
  });
}
