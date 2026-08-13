import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies unit and camera animation settings to the renderer', () {
    final renderer = GameRenderer(mapData: _map(), onCommand: (_) async {});
    addTearDown(renderer.disposeRenderer);

    expect(renderer.followEnemyUnitCamera, isFalse);
    renderer.followEnemyUnitCamera = true;
    expect(renderer.followEnemyUnitCamera, isTrue);

    expect(renderer.cinematicCameraEnabledForTesting, isFalse);
    renderer.cinematicCameraEnabled = true;
    expect(renderer.cinematicCameraEnabledForTesting, isTrue);

    renderer.applyMovementCameraSettings((
      focusOwnUnitMovementCamera: false,
      followOwnUnitMovementCamera: false,
      focusEnemyUnitMovementCamera: false,
      followEnemyUnitMovementCamera: false,
      cinematicCameraEnabled: false,
      unitAnimationsEnabled: false,
      cameraTransitionsEnabled: false,
    ));

    expect(renderer.followEnemyUnitCamera, isFalse);
    expect(renderer.cinematicCameraEnabledForTesting, isFalse);
  });
}

WorldMap _map() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: const [TerrainType.grassland],
      resources: const [],
      height: 0,
    ),
  ],
);
