import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical read model rejects lifecycle players outside roster', () {
    final save = _save(
      name: 'Sparse campaign',
      turn: 3,
      playerStates: const {
        'p1': PlayerTurnState.active,
        'legacy_only': PlayerTurnState.finished,
      },
    );
    expect(() => _timeline(save), throwsArgumentError);
  });

  test('canonical read model preserves ordinary roster and first turn', () {
    final timeline = _timeline(_save());

    expect(timeline.metadata.name, 'Campaign');
    expect(timeline.participants.map((player) => player.id), ['p1']);
    expect(timeline.playerIds, ['p1']);
    expect(timeline.firstTurn, 1);
    expect(timeline.lastTurn, 1);
  });

  test('initial camera is adapted losslessly from canonical metadata', () {
    const camera = CameraState(x: 12.5, y: -4.25, zoom: 1.75);
    final timeline = _timeline(_save(camera: camera));

    expect(timeline.metadata.camera.x, camera.x);
    expect(timeline.metadata.camera.y, camera.y);
    expect(timeline.metadata.camera.zoom, camera.zoom);
    expect(timeline.initialCamera, camera);
  });

  test('last turn follows the resulting replay step snapshot', () {
    final initialSave = _save();
    final initialSnapshot = GameSnapshotFactory.create(save: initialSave);
    final timeline = ReplayTimeline(
      saveId: initialSave.id,
      initialSnapshot: initialSnapshot,
      initialState: GameClientState(),
      steps: [
        ReplayStep(
          index: 1,
          loggedCommand: RecordedDomainCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 12, 1),
            turn: 1,
            command: const EndTurnCommand('p1'),
          ),
          snapshot: GameSnapshotFactory.fromClientState(
            save: initialSave.copyWith(turn: 2),
            state: GameClientState(),
            eventLogOffset: 1,
          ),
          previousState: GameClientState(),
          state: GameClientState(),
          events: const [],
          uiEffects: const [],
        ),
      ],
    );

    expect(timeline.firstTurn, 1);
    expect(timeline.lastTurn, 2);
  });
}

ReplayTimeline _timeline(GameSave save) {
  final snapshot = GameSnapshotFactory.create(save: save);
  return ReplayTimeline(
    saveId: save.id,
    initialSnapshot: snapshot,
    initialState: GameClientState(),
    steps: const [],
  );
}

GameSave _save({
  String name = 'Campaign',
  int turn = 1,
  CameraState camera = CameraState.zero,
  Map<String, PlayerTurnState> playerStates = const {
    'p1': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save_1',
    name: name,
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 4, 24, 12),
    camera: camera,
    players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
  );
}
