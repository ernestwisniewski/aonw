import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_game_renderer.dart';

final class PumpGameHudTest {
  const PumpGameHudTest();

  Future<void> call(
    WidgetTester tester, {
    required GameRepository repository,
    VoidCallback? onClose,
    GameSave? gameSave,
    GameSession? session,
    NetworkSession? networkSession,
    WireMatch? multiplayerMatch,
    bool showEntryHandoff = false,
    bool aiAutopilotEnabled = false,
    GameRenderer? renderer,
    EventLog? eventLog,
    GameLogger? logger,
    bool? autoActionFlowEnabled,
    bool? autoTurnFlowEnabled,
    ValueListenable<GamepadInputSnapshot>? gamepadInputListenable,
    ValueListenable<bool> initialCameraFocusReadyListenable =
        const AlwaysStoppedAnimation<bool>(true),
  }) async {
    final mapData = _makeMap();
    final activeSession = session ?? _makeSession(mapData);
    final activeRenderer =
        renderer ??
        TestGameRenderer(
          mapData: activeSession.mapData,
          applyStateOnTransition: true,
        );
    final save = gameSave ?? _defaultSave;
    final activeEventLog = eventLog ?? _FakeEventLog();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGameSessionProvider.overrideWithValue(activeSession),
          activeGameRendererProvider.overrideWithValue(activeRenderer),
          if (activeRenderer case final TestGameRenderer renderer)
            activeRendererViewModelProvider.overrideWithValue(
              TestRendererViewModel(renderer),
            ),
          gamePlayerControlSaveProvider.overrideWithValue(save),
          gameRepositoryProvider.overrideWithValue(repository),
          networkGameRepositoryProvider.overrideWithValue(repository),
          eventLogProvider.overrideWithValue(activeEventLog),
          networkEventLogProvider.overrideWithValue(activeEventLog),
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
          if (multiplayerMatch != null)
            multiplayerMatchProvider.overrideWithValue({
              multiplayerMatch.id: multiplayerMatch,
            }),
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
              gamepadInputListenable:
                  gamepadInputListenable ??
                  const AlwaysStoppedAnimation<GamepadInputSnapshot>(
                    GamepadInputSnapshot.empty,
                  ),
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
}

WireMatch terminalHudTestMatch({
  required String outcomeCondition,
  required String? winnerPlayerId,
}) => WireMatch(
  id: 'save',
  ownerUserId: 'user_1',
  name: 'Game',
  mapName: 'verdantia',
  players: const [
    WirePlayer(
      id: 'player_1',
      userId: 'user_1',
      name: 'Alice',
      colorValue: 0xFF4a7fc4,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
    ),
    WirePlayer(
      id: 'player_2',
      userId: 'user_2',
      name: 'Bob',
      colorValue: 0xFFc45050,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
    ),
  ],
  turn: 2,
  state: 'finished',
  createdAt: DateTime.utc(2026, 5, 11),
  endedAt: DateTime.utc(2026, 5, 12),
  outcomeCondition: outcomeCondition,
  winnerPlayerId: winnerPlayerId,
);

final class _FakeEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async => commands.fold<int>(
    0,
    (latest, command) => command.offset > latest ? command.offset : latest,
  );

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

final class _FakeSnapshotStore implements SnapshotStore {
  final snapshots = <Snapshot>[];

  @override
  Future<Snapshot?> latest(String saveId) async =>
      snapshots.isEmpty ? null : snapshots.last;

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    snapshots.add(snapshot);
  }
}

final class _TestHudAutoActionFlowController
    extends HudAutoActionFlowController {
  _TestHudAutoActionFlowController(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

final class _TestHudAutoTurnFlowController extends HudAutoTurnFlowController {
  _TestHudAutoTurnFlowController(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

const _defaultPlayer = Player(
  id: 'player_1',
  name: 'Alice',
  colorValue: 0xFF4a7fc4,
);

final _defaultSave = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 2,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_defaultPlayer],
);

WorldMap _makeMap() => WorldMap(
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

GameSession _makeSession(WorldMap mapData) => GameSession(
  mapData: mapData,
  viewMode: MapViewMode.tile,
  saveId: 'save',
  gameMode: GameMode.hotSeat,
);
