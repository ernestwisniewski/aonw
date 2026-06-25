import 'package:aonw/game/application/services/game_session_factory.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (int row = 0; row < 2; row++)
      for (int col = 0; col < 2; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);

void main() {
  group('GameSessionFactory', () {
    test('creates a game session', () {
      final map = _map();
      final session = const GameSessionFactory().create(
        mapData: map,
        saveId: 'save_1',
        imagePath: '/tmp/map.png',
        initialCamera: const CameraState(x: 1, y: 2, zoom: 3),
        gameMode: GameMode.multiplayer,
      );

      expect(session.viewMode, MapViewMode.graphic);
      expect(session.saveId, 'save_1');
      expect(session.imagePath, '/tmp/map.png');
      expect(session.mapData, same(map));
      expect(session.initialCamera?.zoom, 3);
      expect(session.gameMode, GameMode.multiplayer);
    });
  });
}
