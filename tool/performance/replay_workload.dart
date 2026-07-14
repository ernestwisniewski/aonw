import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

import 'measurement.dart';

const replayWorkloadScales = [100, 1000, 10000];

Future<PerformanceCaseResult> runReplayWorkload({
  Iterable<int> scales = replayWorkloadScales,
  int timingSamples = 21,
}) async {
  if (timingSamples < 1) {
    throw ArgumentError.value(timingSamples, 'timingSamples', 'Must be >= 1.');
  }
  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    if (scale < 1) {
      throw ArgumentError.value(scale, 'scales', 'Must contain only >= 1.');
    }
    final result = await _runScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }
  return PerformanceCaseResult(
    'replay',
    {'sizes': stable},
    {'sizes': observations},
  );
}

Future<_ReplayScaleResult> _runScale(int events, int timingSamples) async {
  final snapshot = _initialSnapshot(events);
  final commands = _commands(events);
  final eventLog = _MemoryEventLog(commands);
  final service = ReplayService(
    replayStore: _MemoryReplayStore(snapshot),
    eventLog: eventLog,
    commandResolver: LocalCommandResolver(
      reducer: GameStateReducer(mapData: _map()),
    ),
  );
  eventLog.resetYieldedCommands();
  await service.buildTimeline(snapshot.save.id);
  _requireYieldedCommands(eventLog, events);

  final timings = <Duration>[];
  late ReplayTimeline timeline;
  String? expectedStateDigest;
  for (var sample = 0; sample < timingSamples; sample++) {
    eventLog.resetYieldedCommands();
    final measured = await measureAsync(
      () => service.buildTimeline(snapshot.save.id),
    );
    timings.add(measured.elapsed);
    timeline = measured.value;
    _requireYieldedCommands(eventLog, events);
    final stateDigest = _stateDigest(timeline.steps.last);
    if (expectedStateDigest != null && stateDigest != expectedStateDigest) {
      throw StateError('Replay produced a non-deterministic final state.');
    }
    expectedStateDigest = stateDigest;
  }
  final finalStep = timeline.steps.last;
  if (timeline.steps.length != events || finalStep.offset != events) {
    throw StateError('Replay did not apply all $events prepared commands.');
  }
  return _ReplayScaleResult(
    stable: {
      'events': events,
      'commandsYielded': eventLog.commandsYielded,
      'commandDigest': stableDigest(
        commands.map((command) => command.toJson()).toList(growable: false),
      ),
      'commandKinds': _commandKindCounts(events),
      'steps': timeline.steps.length,
      'finalOffset': finalStep.offset,
      'stateDigest': expectedStateDigest,
    },
    observations: {'buildTimeline': timingObservation(timings)},
  );
}

SaveSnapshot _initialSnapshot(int events) => SaveSnapshot(
  save: GameSave(
    id: 'replay_performance_$events',
    name: 'Replay performance $events',
    mapName: 'synthetic',
    mapSource: MapSource.saved,
    turn: 1,
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
      'player_3': PlayerTurnState.active,
      'player_4': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF3D5FA8),
      Player(id: 'player_2', name: 'Player 2', colorValue: 0xFFB83A3A),
      Player(id: 'player_3', name: 'Player 3', colorValue: 0xFF6D4A8C),
      Player(id: 'player_4', name: 'Player 4', colorValue: 0xFFC8741F),
    ],
  ),
  playerColors: const {
    'player_1': 0xFF3D5FA8,
    'player_2': 0xFFB83A3A,
    'player_3': 0xFF6D4A8C,
    'player_4': 0xFFC8741F,
  },
  units: [
    for (var player = 1; player <= 4; player++)
      GameUnit.produced(
        id: 'unit_$player',
        ownerPlayerId: 'player_$player',
        type: GameUnitType.warrior,
        col: (player - 1) % 2,
        row: (player - 1) ~/ 2,
      ),
  ],
);

List<LoggedCommand> _commands(int count) => [
  for (var offset = 1; offset <= count; offset++)
    LoggedCommand(
      offset: offset,
      timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: offset)),
      turn: 1,
      actorPlayerId: _playerId(offset),
      commandTick: offset,
      command: _command(offset),
    ),
];

String _playerId(int offset) => 'player_${((offset - 1) % 4) + 1}';

GameCommand _command(int offset) {
  final playerId = _playerId(offset);
  return switch (offset % 4) {
    0 => SetActivePlayerCommand(playerId, canAct: offset.isEven),
    1 => SelectTechnologyCommand(playerId, TechnologyId.agriculture),
    2 => ResetUnitMovementCommand(playerId: playerId),
    _ => SkipUnitTurnCommand('unit_${((offset - 1) % 4) + 1}'),
  };
}

Map<String, int> _commandKindCounts(int events) {
  final counts = {
    'resetUnitMovement': 0,
    'selectTechnology': 0,
    'setActivePlayer': 0,
    'skipUnitTurn': 0,
  };
  for (var offset = 1; offset <= events; offset++) {
    final name = switch (offset % 4) {
      0 => 'setActivePlayer',
      1 => 'selectTechnology',
      2 => 'resetUnitMovement',
      _ => 'skipUnitTurn',
    };
    counts[name] = counts[name]! + 1;
  }
  return counts;
}

String _stateDigest(ReplayStep step) => stableDigest({
  'persistent': step.state.toPersistentState().toJson(),
  'activePlayerId': step.state.activePlayerId,
  'activePlayerCanAct': step.state.activePlayerCanAct,
});

void _requireYieldedCommands(_MemoryEventLog eventLog, int expected) {
  if (eventLog.commandsYielded != expected) {
    throw StateError(
      'Replay event log yielded ${eventLog.commandsYielded} of $expected commands.',
    );
  }
}

MapData _map() => MapData(
  cols: 2,
  rows: 2,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 0,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);

class _MemoryReplayStore implements ReplayStore {
  _MemoryReplayStore(this.snapshot);

  final SaveSnapshot snapshot;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async =>
      saveId == snapshot.save.id ? snapshot : null;

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    throw UnsupportedError('The replay performance fixture is immutable.');
  }
}

class _MemoryEventLog implements EventLog {
  _MemoryEventLog(this.commands);

  final List<LoggedCommand> commands;
  int commandsYielded = 0;

  void resetYieldedCommands() => commandsYielded = 0;

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    throw UnsupportedError('The replay performance fixture is immutable.');
  }

  @override
  Future<int> latestOffset(String saveId) async =>
      commands.isEmpty ? 0 : commands.last.offset;

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    for (final command in commands) {
      if (command.offset >= offset) {
        commandsYielded++;
        yield command;
      }
    }
  }
}

class _ReplayScaleResult {
  const _ReplayScaleResult({required this.stable, required this.observations});

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;
}
