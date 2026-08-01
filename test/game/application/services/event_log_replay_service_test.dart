import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/event_log_replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replays logged commands after the snapshot offset', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final service = EventLogReplayService(
      eventLog: _MemoryEventLog([
        RecordedDomainCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 4, 16, 11),
          turn: 1,
          actorPlayerId: 'player_1',
          command: null,
        ),
        RecordedDomainCommand(
          offset: 2,
          timestamp: DateTime.utc(2026, 4, 16, 12),
          turn: 1,
          actorPlayerId: 'player_1',
          command: MoveUnitCommand(commander.id, 1, 0),
        ),
      ]),
      reducer: GameStateReducer(mapData: _map()),
    );

    final state = GameClientState(units: [commander]);
    final replayed = await service.replaySinceSnapshot(
      saveId: 'save_1',
      snapshot: _snapshot(state, offset: 1),
      state: state,
    );

    expect(replayed.offset, 2);
    expect(replayed.state.units.single.col, 1);
    expect(replayed.state.moveCommandActive, isFalse);
  });

  test('throws when the event log has an offset gap', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final service = EventLogReplayService(
      eventLog: _MemoryEventLog([
        RecordedDomainCommand(
          offset: 3,
          timestamp: DateTime.utc(2026, 4, 16, 12),
          turn: 1,
          actorPlayerId: 'player_1',
          command: MoveUnitCommand(commander.id, 1, 0),
        ),
      ]),
      reducer: GameStateReducer(mapData: _map()),
    );

    await expectLater(
      service.replaySinceSnapshot(
        saveId: 'save_1',
        snapshot: _snapshot(GameClientState(units: [commander]), offset: 1),
        state: GameClientState(units: [commander]),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('fails closed when the next entry has no replayable command', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final service = EventLogReplayService(
      eventLog: _MemoryEventLog([
        RecordedDomainCommand(
          offset: 2,
          timestamp: DateTime.utc(2026, 4, 16, 12),
          turn: 1,
          actorPlayerId: 'player_2',
          command: null,
        ),
      ]),
      reducer: GameStateReducer(mapData: _map()),
    );

    await expectLater(
      service.replaySinceSnapshot(
        saveId: 'save_1',
        snapshot: _snapshot(GameClientState(units: [commander]), offset: 1),
        state: GameClientState(units: [commander]),
      ),
      throwsA(
        isA<AuthoritativeSnapshotRequiredException>().having(
          (error) => error.reason,
          'reason',
          AuthoritativeSnapshotRequiredReason.redactedCommand,
        ),
      ),
    );
  });

  test('fails closed when a legacy entry has no game turn', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final service = EventLogReplayService(
      eventLog: _MemoryEventLog([
        RecordedDomainCommand(
          offset: 2,
          timestamp: DateTime.utc(2026, 4, 16, 12),
          turn: null,
          actorPlayerId: 'player_1',
          command: MoveUnitCommand(commander.id, 1, 0),
        ),
      ]),
      reducer: GameStateReducer(mapData: _map()),
    );

    await expectLater(
      service.replaySinceSnapshot(
        saveId: 'save_1',
        snapshot: _snapshot(GameClientState(units: [commander]), offset: 1),
        state: GameClientState(units: [commander]),
      ),
      throwsA(
        isA<AuthoritativeSnapshotRequiredException>().having(
          (error) => error.reason,
          'reason',
          AuthoritativeSnapshotRequiredReason.missingGameTurn,
        ),
      ),
    );
  });
}

CanonicalGameSnapshot _snapshot(GameClientState state, {required int offset}) {
  return GameSnapshotFactory.fromClientState(
    save: GameSave(
      id: 'save_1',
      name: 'Replay',
      mapName: 'test',
      turn: 1,
      playerStates: const {'player_1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 4, 16),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF3D5FA8),
      ],
    ),
    state: state,
    eventLogOffset: offset,
  );
}

class _MemoryEventLog implements EventLog {
  final List<RecordedDomainCommand> commands;

  const _MemoryEventLog(this.commands);

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {}

  @override
  Stream<RecordedDomainCommand> readSince(String saveId, {int offset = 0}) {
    return Stream.fromIterable(
      commands.where((command) => command.offset >= offset),
    );
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    for (final command in commands) {
      if (command.offset > latest) latest = command.offset;
    }
    return latest;
  }
}

WorldMap _map() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
