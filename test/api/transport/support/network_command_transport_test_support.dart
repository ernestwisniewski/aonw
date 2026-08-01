part of '../network_command_transport_test.dart';

class _SentCommand {
  final String saveId;
  final AuthToken token;
  final int afterOffset;
  final WireCommand wire;
  final String clientMessageId;

  const _SentCommand({
    required this.saveId,
    required this.token,
    required this.afterOffset,
    required this.wire,
    required this.clientMessageId,
  });
}

typedef _ScriptedCommandHandler =
    WireCommandAck Function(_ScriptedSentCommand command);

class _ScriptedSentCommand extends _SentCommand {
  final int call;

  const _ScriptedSentCommand({
    required this.call,
    required super.saveId,
    required super.token,
    required super.afterOffset,
    required super.wire,
    required super.clientMessageId,
  });
}

class _ScriptedCommandDispatcher implements WireCommandDispatcher {
  final _ScriptedCommandHandler handler;
  final sentCommands = <_ScriptedSentCommand>[];

  _ScriptedCommandDispatcher(this.handler);

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    final command = _ScriptedSentCommand(
      call: sentCommands.length + 1,
      saveId: saveId,
      token: token,
      afterOffset: afterOffset,
      wire: wire,
      clientMessageId: clientMessageId,
    );
    sentCommands.add(command);
    return handler(command);
  }
}

class _SnapshotRepository implements GameRepository {
  SaveSnapshot snapshot;

  _SnapshotRepository(this.snapshot);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final updated = snapshot.copyWith(
      save: snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? snapshot.save.savedAt,
      ),
    );
    snapshot = updated;
    return updated;
  }
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
}

MapData _map() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);
