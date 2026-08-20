import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/game_renderer_flame_harness.dart';

void main() {
  gameRendererFlameTester.test(
    'coalesces raw mouse moves before projection and camera input',
    () => GameRenderer(mapData: _map(), onCommand: (_) async {}),
    (renderer) {
      renderer.camera.viewfinder
        ..zoom = 1
        ..position = Vector2.zero();

      renderer.handleViewportPointerDown(1, Vector2.zero());
      for (var x = 1; x <= 1000; x++) {
        renderer.handleViewportPointerMove(1, Vector2(x.toDouble(), 0));
      }

      expect(renderer.pendingViewportPointerMoveCountForTesting, 1);
      expect(renderer.camera.viewfinder.position.x, 0);

      renderer.update(0);

      expect(renderer.pendingViewportPointerMoveCountForTesting, 0);
      expect(renderer.viewportPointerMoveFlushCountForTesting, 1);
      expect(renderer.camera.viewfinder.position.x, -1000);
    },
  );
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
