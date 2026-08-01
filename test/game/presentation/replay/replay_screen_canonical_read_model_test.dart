import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/replay/replay_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw/game/presentation/screens/replay/replay_screen.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('replay UI reads canonical metadata, roster, and event steps', (
    tester,
  ) async {
    await _pumpReplay(tester, _timeline());

    expect(find.text('Canonical campaign'), findsOneWidget);
    expect(find.text('Perspective'), findsOneWidget);
    await tester.tap(find.text('All players'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Alice'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Next step'));
    await tester.pump();
    expect(find.textContaining('ended'), findsOneWidget);

    await _pumpReplay(
      tester,
      _timeline(camera: const CameraState(x: 8, y: 9, zoom: 1.5)),
    );
    expect(find.text('Canonical campaign'), findsOneWidget);
  });

  testWidgets('replay UI formats canonical activity entries', (tester) async {
    await _pumpReplay(tester, _timeline(withActivity: true));

    expect(find.text('Canonical campaign'), findsOneWidget);
    await tester.tap(find.byTooltip('Next step'));
    await tester.pump();
    expect(find.textContaining('ended'), findsOneWidget);
  });
}

Future<void> _pumpReplay(WidgetTester tester, ReplayTimeline timeline) async {
  const selection = MapSelection(name: 'verdantia', source: MapSource.asset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeMapProvider(selection).overrideWithValue(AsyncData(_mapData)),
        mapImagePathProvider(
          selection,
        ).overrideWithValue(const AsyncData(null)),
        savedCameraProvider(
          _save.id,
        ).overrideWithValue(AsyncData(_save.camera)),
        gameSaveProvider(_save.id).overrideWithValue(AsyncData(_save)),
        replayTimelineProvider(
          const ReplayTimelineRequest(selection: selection, saveId: 'save_1'),
        ).overrideWithValue(AsyncData(timeline)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplayScreen(saveId: 'save_1'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

ReplayTimeline _timeline({
  bool withActivity = false,
  CameraState camera = const CameraState(x: 4, y: 5, zoom: 1.25),
}) {
  const event = TurnEndedEvent(playerId: 'player_1');
  final loggedCommand = RecordedDomainCommand(
    offset: 1,
    timestamp: DateTime.utc(2026, 7, 28, 12),
    turn: 1,
    command: const EndTurnCommand('player_1'),
    actorPlayerId: 'player_1',
    activity: withActivity
        ? const [
            LoggedActivityEntry(
              eventIndex: 0,
              playerId: 'player_1',
              event: event,
              context: GameActivityContext.empty,
            ),
          ]
        : const [],
  );
  final snapshot = SaveSnapshot(save: _save.copyWith(camera: camera));
  return ReplayTimeline(
    saveId: _save.id,
    initialSnapshot: snapshot,
    initialState: const GameState(activePlayerId: 'player_1'),
    steps: [
      ReplayStep(
        index: 1,
        loggedCommand: loggedCommand,
        snapshot: snapshot,
        previousState: const GameState(activePlayerId: 'player_1'),
        state: const GameState(activePlayerId: 'player_1'),
        events: const [event],
        uiEffects: const [],
      ),
    ],
  );
}

final _mapData = MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);

final _save = GameSave(
  id: 'save_1',
  name: 'Canonical campaign',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 7, 28, 12),
  camera: const CameraState(x: 4, y: 5, zoom: 1.25),
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
  ],
);
