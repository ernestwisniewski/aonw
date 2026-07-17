import 'package:aonw_core/game/domain/state/game_snapshot_metadata.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:test/test.dart';

void main() {
  test('GameSnapshotCamera has scalar copy and value semantics', () {
    const camera = GameSnapshotCamera(x: 1, y: 2, zoom: 3);
    const equalCamera = GameSnapshotCamera(x: 1, y: 2, zoom: 3);

    expect(camera, equalCamera);
    expect(camera.hashCode, equalCamera.hashCode);
    expect(
      camera.copyWith(y: 4),
      const GameSnapshotCamera(x: 1, y: 4, zoom: 3),
    );
    expect(
      GameSnapshotCamera.zero,
      const GameSnapshotCamera(x: 0, y: 0, zoom: 1),
    );
  });

  group('GameSnapshotMetadata', () {
    test('owns the camera and normalizes savedAtUtc', () {
      const sourceCamera = GameSnapshotCamera(x: 12.5, y: -4, zoom: 1.75);
      const sourceWorld = WorldReference(
        name: 'verdantia',
        source: MapSource.asset,
      );
      final metadata = GameSnapshotMetadata(
        id: 'save-1',
        schemaVersion: 3,
        name: 'Campaign',
        world: sourceWorld,
        savedAtUtc: DateTime.parse('2026-07-17T12:30:00+02:00'),
        camera: sourceCamera,
      );

      expect(metadata.savedAtUtc.isUtc, isTrue);
      expect(metadata.savedAtUtc.toIso8601String(), '2026-07-17T10:30:00.000Z');
      expect(metadata.camera, sourceCamera);
      expect(identical(metadata.camera, sourceCamera), isFalse);
      expect(metadata.world, sourceWorld);
      expect(identical(metadata.world, sourceWorld), isFalse);
    });

    test('has value equality and hash semantics', () {
      final first = _metadata();
      final second = _metadata();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(
        second.copyWith(world: second.world.copyWith(source: MapSource.saved)),
        isNot(first),
      );
    });

    test('copyWith owns replacements and preserves normalized values', () {
      final original = _metadata();
      const replacementCamera = GameSnapshotCamera(x: 9, y: 8, zoom: 2);
      final copied = original.copyWith(
        id: 'save-2',
        savedAtUtc: DateTime.parse('2026-07-17T18:00:00+02:00'),
        camera: replacementCamera,
      );

      expect(copied.id, 'save-2');
      expect(copied.schemaVersion, original.schemaVersion);
      expect(copied.world, original.world);
      expect(copied.savedAtUtc.toIso8601String(), '2026-07-17T16:00:00.000Z');
      expect(copied.camera, replacementCamera);
      expect(identical(copied.camera, replacementCamera), isFalse);
    });
  });
}

GameSnapshotMetadata _metadata() {
  return GameSnapshotMetadata(
    id: 'save-1',
    schemaVersion: 3,
    name: 'Campaign',
    world: const WorldReference(name: 'verdantia', source: MapSource.asset),
    savedAtUtc: DateTime.utc(2026, 7, 17, 10, 30),
    camera: const GameSnapshotCamera(x: 12.5, y: -4, zoom: 1.75),
  );
}
