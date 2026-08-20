import 'dart:async';

import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_game_renderer.dart';

class FakeHudRepository implements GameRepository {
  FakeHudRepository({CanonicalGameSnapshot? snapshot})
    : snapshot = _withHudTestVisibility(
        snapshot ?? GameSnapshotFactory.create(save: hudSave),
      );

  CanonicalGameSnapshot snapshot;
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
  Future<CanonicalGameSnapshot> load(String saveId) async {
    final gate = loadGate;
    if (gate != null) {
      loadGate = null;
      await gate.future;
    }
    return snapshot;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    savedCamera = camera;
    snapshot = snapshot.withGameSave(snapshot.save.copyWith(camera: camera));
    return snapshot;
  }
}

class FakeHudEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.fold<int>(0, (latest, command) {
      return command.offset > latest ? command.offset : latest;
    });
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<RecordedDomainCommand> readSince(
    String saveId, {
    int offset = 0,
  }) async* {
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}

class HudTestLogger implements GameLogger {
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

final class HudTestRenderer extends TestGameRenderer {
  HudTestRenderer({required super.mapData})
    : super(applyStateOnTransition: true);
}

const hudPlayer = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const hudPlayer2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);
const hudNetworkConnected = NetworkConnectionState(status: .connected);
const hudAi = Player(
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
final hudSave = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 2,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [hudPlayer],
);

WorldMap hudMap() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (int row = 0; row < 3; row++)
      for (int col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameSession hudSession(
  WorldMap mapData, {
  GameMode gameMode = GameMode.hotSeat,
}) => GameSession(
  mapData: mapData,
  viewMode: MapViewMode.tile,
  saveId: 'save',
  gameMode: gameMode,
);

Future<void> pumpUntil(
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

Future<void> cancelMoveTargetingBanner(WidgetTester tester) async {
  final moveAction = find.byKey(const Key('selectionInfo.action.move'));
  if (moveAction.evaluate().isEmpty) return;
  await tester.tap(find.byKey(const Key('selectionInfo.action.move')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openHelpEntryById(WidgetTester tester, String popupId) async {
  await tester.tap(find.byKey(const Key('gameOptions.helpPopupsButton')));
  await tester.pump();
  await tester.tap(find.byKey(Key('gameOptions.helpPopup.$popupId')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

GameClientState? readHudGameState(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(GameHud)),
    listen: false,
  );
  return container.read(gameStateProvider('save')).value;
}

Future<void> disableAutoTurnFlow(WidgetTester tester) async {
  await setAutoTurnFlow(tester, false);
}

Future<void> enableAutoTurnFlow(WidgetTester tester) async {
  await setAutoTurnFlow(tester, true);
}

Future<void> setAutoTurnFlow(WidgetTester tester, bool enabled) async {
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

void expectRectInside(Rect rect, Rect viewport, {required String reason}) {
  expect(rect.left, greaterThanOrEqualTo(viewport.left), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(viewport.top), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.right), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.bottom), reason: reason);
}

void expectRectContains(Rect outer, Rect inner, {required String reason}) {
  expect(inner.left, greaterThanOrEqualTo(outer.left), reason: reason);
  expect(inner.top, greaterThanOrEqualTo(outer.top), reason: reason);
  expect(inner.right, lessThanOrEqualTo(outer.right), reason: reason);
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom), reason: reason);
}

void expectCoachmarkHaloTracks(
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

Future<void> pressGamepad(
  WidgetTester tester,
  ValueNotifier<GamepadInputSnapshot> input,
  GamepadInputSnapshot snapshot,
) async {
  input.value = snapshot;
  await tester.pump(const Duration(milliseconds: 16));
  input.value = GamepadInputSnapshot.empty;
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 120));
}

CanonicalGameSnapshot _withHudTestVisibility(CanonicalGameSnapshot snapshot) {
  if (snapshot.fogOfWar != FogOfWarState.empty) return snapshot;
  final playerIds = snapshot.domain.participants
      .map((player) => player.id)
      .where((playerId) => playerId.isNotEmpty);
  return snapshot.copyWith(
    domain: snapshot.domain.copyWith(
      fogOfWar: FogOfWarState(
        players: {
          for (final playerId in playerIds)
            playerId: PlayerFogOfWar(
              playerId: playerId,
              visibleHexes: {
                for (var row = 0; row < 3; row++)
                  for (var col = 0; col < 3; col++)
                    HexCoordinate(col: col, row: row),
              },
            ),
        },
      ),
    ),
  );
}
