import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/services/event_log_replay_service.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replays logged commands after the snapshot offset', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final service = EventLogReplayService(
      eventLog: _MemoryEventLog([
        LoggedCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 4, 16, 11),
          turn: 1,
          actorPlayerId: 'player_1',
          command: const SelectUnitCommand('ignored'),
        ),
        LoggedCommand(
          offset: 2,
          timestamp: DateTime.utc(2026, 4, 16, 12),
          turn: 1,
          actorPlayerId: 'player_1',
          command: MoveUnitCommand(commander.id, 1, 0),
        ),
      ]),
      reducer: GameStateReducer(mapData: _map()),
    );

    final replayed = await service.replaySinceSnapshot(
      saveId: 'save_1',
      state: GameState(units: [commander]),
      offset: 1,
    );

    expect(replayed.offset, 2);
    expect(replayed.state.units.single.col, 1);
  });

  test('throws when the event log has an offset gap', () async {
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final service = EventLogReplayService(
      eventLog: _MemoryEventLog([
        LoggedCommand(
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
        state: GameState(units: [commander]),
        offset: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

class _MemoryEventLog implements EventLog {
  final List<LoggedCommand> commands;

  const _MemoryEventLog(this.commands);

  @override
  Future<void> append(String saveId, LoggedCommand command) async {}

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) {
    return Stream.fromIterable(
      commands.where((command) => command.offset >= offset),
    );
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    for (final command in commands) {
      if (command.offset > latest) latest = command.offset;
    }
    return latest;
  }
}

MapData _map() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
