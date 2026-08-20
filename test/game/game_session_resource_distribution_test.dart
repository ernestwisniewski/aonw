import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session applies persisted resources and saved game mode', () async {
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final map = WorldMap(
      mapName: 'verdantia',
      rows: 5,
      cols: 5,
      tiles: [
        for (var row = 0; row < 5; row += 1)
          for (var col = 0; col < 5; col += 1)
            WorldTile(
              col: col,
              row: row,
              terrains: const [TerrainType.plains],
              resources: const [],
              height: 0,
            ),
      ],
    );
    final save = GameSave(
      id: 'save_1',
      name: 'Game',
      mapName: selection.name,
      mapSource: selection.source,
      turn: 1,
      playerStates: const {'player_1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 8, 12),
      camera: const CameraState(x: 4, y: 5, zoom: 1.25),
      players: const [Player(id: 'player_1', name: 'Alice', colorValue: 1)],
      gameMode: GameMode.multiplayer,
    );
    final snapshot = GameSnapshotFactory.create(
      save: save,
      initialResourceDistribution: InitialResourceDistribution(
        seed: 12,
        placements: const [
          InitialResourcePlacement(col: 2, row: 2, resource: ResourceType.oil),
        ],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(selection).overrideWithValue(AsyncData(map)),
        mapImageSourceProvider(
          selection,
        ).overrideWithValue(const AsyncData(null)),
        gameSaveSnapshotProvider(
          save.id,
        ).overrideWithValue(AsyncData(snapshot)),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(
      gameSessionProvider(selection, save.id).future,
    );

    expect(session.gameMode, GameMode.multiplayer);
    expect(session.mapData.tileAt(2, 2)!.resources, [ResourceType.oil]);
  });
}
