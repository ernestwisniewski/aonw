import 'package:aonw_core/map/domain/map_selection.dart';

/// Camera position stored alongside a game snapshot.
final class GameSnapshotCamera {
  const GameSnapshotCamera({
    required this.x,
    required this.y,
    required this.zoom,
  });

  static const zero = GameSnapshotCamera(x: 0.0, y: 0.0, zoom: 1.0);

  final double x;
  final double y;
  final double zoom;

  GameSnapshotCamera copyWith({double? x, double? y, double? zoom}) {
    return GameSnapshotCamera(
      x: x ?? this.x,
      y: y ?? this.y,
      zoom: zoom ?? this.zoom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSnapshotCamera &&
          x == other.x &&
          y == other.y &&
          zoom == other.zoom;

  @override
  int get hashCode => Object.hash(x, y, zoom);

  @override
  String toString() => 'GameSnapshotCamera(x: $x, y: $y, zoom: $zoom)';
}

final class WorldReference {
  const WorldReference({required this.name, required this.source});

  final String name;
  final MapSource source;

  WorldReference copyWith({String? name, MapSource? source}) {
    return WorldReference(
      name: name ?? this.name,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldReference && name == other.name && source == other.source;

  @override
  int get hashCode => Object.hash(name, source);

  @override
  String toString() => 'WorldReference(name: $name, source: $source)';
}

final class GameSnapshotMetadata {
  factory GameSnapshotMetadata({
    required String id,
    required int schemaVersion,
    required String name,
    required WorldReference world,
    required DateTime savedAtUtc,
    required GameSnapshotCamera camera,
  }) {
    return GameSnapshotMetadata._(
      id: id,
      schemaVersion: schemaVersion,
      name: name,
      world: WorldReference(name: world.name, source: world.source),
      savedAtUtc: savedAtUtc.toUtc(),
      camera: GameSnapshotCamera(x: camera.x, y: camera.y, zoom: camera.zoom),
    );
  }

  const GameSnapshotMetadata._({
    required this.id,
    required this.schemaVersion,
    required this.name,
    required this.world,
    required this.savedAtUtc,
    required this.camera,
  });

  final String id;
  final int schemaVersion;
  final String name;
  final WorldReference world;
  final DateTime savedAtUtc;
  final GameSnapshotCamera camera;

  GameSnapshotMetadata copyWith({
    String? id,
    int? schemaVersion,
    String? name,
    WorldReference? world,
    DateTime? savedAtUtc,
    GameSnapshotCamera? camera,
  }) {
    return GameSnapshotMetadata(
      id: id ?? this.id,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      name: name ?? this.name,
      world: world ?? this.world,
      savedAtUtc: savedAtUtc ?? this.savedAtUtc,
      camera: camera ?? this.camera,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSnapshotMetadata &&
          id == other.id &&
          schemaVersion == other.schemaVersion &&
          name == other.name &&
          world == other.world &&
          savedAtUtc == other.savedAtUtc &&
          camera == other.camera;

  @override
  int get hashCode =>
      Object.hash(id, schemaVersion, name, world, savedAtUtc, camera);

  @override
  String toString() {
    return 'GameSnapshotMetadata(id: $id, schemaVersion: $schemaVersion, '
        'name: $name, world: $world, savedAtUtc: $savedAtUtc, '
        'camera: $camera)';
  }
}
