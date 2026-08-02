import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCameraController', () {
    test('adds shake effects by default', () async {
      final camera = CameraComponent();
      GameCameraController(
        camera: camera,
        mapData: _map(),
      ).shake(intensity: 5, duration: 0.2);
      await Future<void>.delayed(Duration.zero);

      expect(
        camera.viewfinder.children.whereType<SequenceEffect>(),
        hasLength(1),
      );
    });

    test('skips shake effects when reduce motion is enabled', () async {
      final camera = CameraComponent();
      GameCameraController(
        camera: camera,
        mapData: _map(),
        reduceMotion: true,
      ).shake(intensity: 5, duration: 0.2);
      await Future<void>.delayed(Duration.zero);

      expect(camera.viewfinder.children.whereType<SequenceEffect>(), isEmpty);
    });

    test('removes active shake when reduce motion is enabled', () async {
      final camera = CameraComponent();
      final controller = GameCameraController(camera: camera, mapData: _map())
        ..shake(intensity: 5, duration: 0.2);
      await Future<void>.delayed(Duration.zero);
      controller.reduceMotion = true;

      expect(camera.viewfinder.children.whereType<SequenceEffect>(), isEmpty);
    });
  });
}

WorldMap _map() {
  return WorldMap(
    cols: 1,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
    ],
  );
}
