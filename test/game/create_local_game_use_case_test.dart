import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/use_cases/create_local_game_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingGameRepository implements GameRepository {
  NewGameRequest? createdRequest;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) =>
      '$mapDisplayName @ ${now.toIso8601String()}';

  @override
  Future<String> create(NewGameRequest request) async {
    createdRequest = request;
    return 'save_1';
  }

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => throw UnimplementedError();

  @override
  Future<void> save(SaveSnapshot snapshot) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async => throw UnimplementedError();
}

final class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026, 7, 14, 12);
}

void main() {
  const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
  const players = [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF3D5FA8),
    Player(id: 'player_2', name: 'Bob', colorValue: 0xFFB83A3A),
  ];

  test('creates only a valid local game and owns request defaults', () async {
    final repository = _RecordingGameRepository();
    final useCase = CreateLocalGameUseCase(
      repository: repository,
      clock: const _FixedClock(),
    );

    final saveId = await useCase.execute(
      name: '  ',
      selection: selection,
      mapData: _map(valid: true),
      gameMode: GameMode.hotSeat,
      matchRules: MatchRules.standard,
      players: players,
      startPositionSeed: 17,
    );

    expect(saveId, 'save_1');
    expect(
      repository.createdRequest?.name,
      'Verdantia @ 2026-07-14T12:00:00.000Z',
    );
    expect(repository.createdRequest?.mapName, selection.name);
    expect(repository.createdRequest?.mapSource, selection.source);
    expect(repository.createdRequest?.startPositionSeed, 17);
  });

  test('rejects an invalid map before persistence', () async {
    final repository = _RecordingGameRepository();
    final useCase = CreateLocalGameUseCase(
      repository: repository,
      clock: const _FixedClock(),
    );

    try {
      await useCase.execute(
        selection: selection,
        mapData: _map(valid: false),
        gameMode: GameMode.hotSeat,
        matchRules: MatchRules.standard,
        players: players,
      );
      fail('Expected the invalid map to be rejected.');
    } on InvalidLocalGameMapException catch (error) {
      expect(error.validation.errors, isNotEmpty);
      expect(error.toString(), contains('InvalidLocalGameMapException'));
    }

    expect(repository.createdRequest, isNull);
  });
}

MapData _map({required bool valid}) => MapData(
  cols: 20,
  rows: 20,
  mapName: 'verdantia',
  tiles: [
    for (var row = 0; row < 20; row++)
      for (var col = 0; col < 20; col++)
        TileData(
          col: col,
          row: row,
          terrains: [valid ? TerrainType.grassland : TerrainType.ocean],
          resources: valid
              ? const [ResourceType.wheat, ResourceType.iron, ResourceType.gold]
              : const [],
          height: 0,
        ),
  ],
);
