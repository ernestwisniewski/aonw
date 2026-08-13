import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/infrastructure/persistence/initial_game_snapshot_factory.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new local game persists its deterministic resource distribution', () {
    final mapData = _map();
    const players = [
      Player(id: 'player_1', name: 'One', colorValue: 1),
      Player(id: 'player_2', name: 'Two', colorValue: 2),
    ];
    final request = NewGameRequest(
      name: 'Local',
      mapName: 'test',
      mapSource: MapSource.asset,
      players: players,
      mapData: mapData,
    );

    final first = createInitialGameSnapshot(
      id: 'save_1',
      now: DateTime.utc(2026, 8, 12),
      request: request,
      startPositionSeed: 73,
    );
    final repeated = createInitialGameSnapshot(
      id: 'save_2',
      now: DateTime.utc(2026, 8, 12),
      request: request,
      startPositionSeed: 73,
    );

    expect(
      first.snapshot.domain.initialResourceDistribution.placements,
      isNotEmpty,
    );
    expect(
      repeated.snapshot.domain.initialResourceDistribution,
      first.snapshot.domain.initialResourceDistribution,
    );
    expect(
      first.snapshot.domain.initialResourceDistribution.applyTo(mapData),
      isNot(same(mapData)),
    );
  });
}

WorldMap _map() => WorldMap(
  cols: 10,
  rows: 8,
  tiles: [
    for (var row = 0; row < 8; row++)
      for (var col = 0; col < 10; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
