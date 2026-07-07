import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw/game/presentation/screens/game/game_primary_action_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'gamepad action bumpers use next-action flow for city and research panels',
    (tester) async {
      final gamepadInput = ValueNotifier<GamepadInputSnapshot>(
        GamepadInputSnapshot.empty,
      );
      final animatingUnitIds = ValueNotifier(<String>{});
      addTearDown(gamepadInput.dispose);
      addTearDown(animatingUnitIds.dispose);

      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      final save = _save();
      final session = _session();
      final repository = _FakeGameRepository(
        SaveSnapshot.fromGameState(
          save: save,
          state: const GameState(activePlayerId: 'player_1', cities: [city]),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeGameSessionProvider.overrideWithValue(session),
            gamePlayerControlSaveProvider.overrideWithValue(save),
            gameRepositoryProvider.overrideWithValue(repository),
            eventLogProvider.overrideWithValue(_FakeEventLog()),
            snapshotStoreProvider.overrideWithValue(_FakeSnapshotStore()),
            gameAudioControllerProvider.overrideWithValue(
              _RecordingAudioController(),
            ),
          ],
          child: MaterialApp(
            home: GamepadInputRouterScope(
              input: gamepadInput,
              child: GamePrimaryActionController(
                session: session,
                gameSave: save,
                animatingUnitIdsListenable: animatingUnitIds,
                gamepadInputListenable: gamepadInput,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GamePrimaryActionController)),
        listen: false,
      );
      final gameStateSubscription = container.listen(
        gameStateProvider(save.id),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(gameStateSubscription.close);
      await container.read(gameStateProvider(save.id).future);
      await tester.pump();

      expect(
        container.read(gamePlayerControlControllerProvider).activePlayerId,
        'player_1',
      );
      expect(
        TurnReducer.pendingTurnActionCount(
          container.read(gameStateProvider(save.id)).value!,
          'player_1',
          session.mapData,
        ),
        2,
      );
      expect(container.read(hudPanelControllerProvider).cityBuildings, isFalse);
      expect(container.read(hudPanelControllerProvider).technology, isFalse);

      await _pressGamepad(
        tester,
        gamepadInput,
        const GamepadInputSnapshot(focusNext: true),
      );

      expect(container.read(hudPanelControllerProvider).cityBuildings, isTrue);
      expect(container.read(hudPanelControllerProvider).technology, isFalse);
      expect(
        container.read(gameStateProvider(save.id)).value?.selection?.city?.id,
        city.id,
      );

      await _pressGamepad(
        tester,
        gamepadInput,
        const GamepadInputSnapshot(focusNext: true),
      );

      expect(container.read(hudPanelControllerProvider).cityBuildings, isFalse);
      expect(container.read(hudPanelControllerProvider).technology, isTrue);
      expect(
        container
            .read(gameStateProvider(save.id))
            .value
            ?.research
            .forPlayer('player_1')
            .activeTechnologyId,
        isNull,
      );

      await _pressGamepad(
        tester,
        gamepadInput,
        const GamepadInputSnapshot(focusPrevious: true),
      );

      expect(container.read(hudPanelControllerProvider).cityBuildings, isTrue);
      expect(container.read(hudPanelControllerProvider).technology, isFalse);
      expect(
        container.read(gameStateProvider(save.id)).value?.selection?.city?.id,
        city.id,
      );
    },
  );
}

Future<void> _pressGamepad(
  WidgetTester tester,
  ValueNotifier<GamepadInputSnapshot> input,
  GamepadInputSnapshot snapshot,
) async {
  input.value = snapshot;
  await tester.pump(const Duration(milliseconds: 16));
  input.value = GamepadInputSnapshot.empty;
  await tester.pumpAndSettle();
}

GameSave _save() {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'test',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 7, 7),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
    ],
  );
}

GameSession _session() {
  return GameSession(
    mapData: _map(),
    viewMode: MapViewMode.tile,
    saveId: 'save',
  );
}

MapData _map() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

final class _FakeGameRepository implements GameRepository {
  _FakeGameRepository(this.snapshot);

  SaveSnapshot snapshot;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    return '$mapDisplayName ${now.year}';
  }

  @override
  Future<String> create(NewGameRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<List<GameSaveIndex>> list() async {
    return [
      GameSaveIndex(
        id: snapshot.save.id,
        name: snapshot.save.name,
        mapName: snapshot.save.mapName,
        mapSource: snapshot.save.mapSource,
        turn: snapshot.save.turn,
        savedAt: snapshot.save.savedAt,
      ),
    ];
  }

  @override
  Future<SaveSnapshot> load(String saveId) async {
    if (saveId != snapshot.save.id) throw StateError('missing save');
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
    snapshot = snapshot.copyWith(
      save: snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? snapshot.save.savedAt,
      ),
    );
    return snapshot;
  }
}

final class _FakeEventLog implements EventLog {
  @override
  Future<void> append(String saveId, LoggedCommand command) async {}

  @override
  Future<int> latestOffset(String saveId) async => 0;

  @override
  Stream<LoggedCommand> readAll(String saveId) => const Stream.empty();

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) {
    return const Stream.empty();
  }
}

final class _FakeSnapshotStore implements SnapshotStore {
  @override
  Future<Snapshot?> latest(String saveId) async => null;

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {}
}

final class _RecordingAudioController extends GameAudioController {
  @override
  Future<void> play(GameSoundCue cue, {double volume = 1}) async {}

  @override
  void playAll(Iterable<GameSoundCue> cues) {}
}
