import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/resource/resource_definition.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// One additional resource introduced when a match world is initialized.
final class InitialResourcePlacement {
  const InitialResourcePlacement({
    required this.col,
    required this.row,
    required this.resource,
  });

  factory InitialResourcePlacement.fromJson(Map<String, dynamic> json) {
    final col = json['col'];
    final row = json['row'];
    final resource = json['resource'];
    if (col is! num || col.toInt() != col) {
      throw FormatException('Invalid initial resource column: $col');
    }
    if (row is! num || row.toInt() != row) {
      throw FormatException('Invalid initial resource row: $row');
    }
    if (resource is! String) {
      throw FormatException('Invalid initial resource type: $resource');
    }
    return InitialResourcePlacement(
      col: col.toInt(),
      row: row.toInt(),
      resource: ResourceType.fromName(resource),
    );
  }

  final int col;
  final int row;
  final ResourceType resource;

  ResourceCategory get category =>
      ResourceCatalog.definitionFor(resource).category;

  Map<String, dynamic> toJson() => {
    'col': col,
    'row': row,
    'resource': resource.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitialResourcePlacement &&
          other.col == col &&
          other.row == row &&
          other.resource == resource;

  @override
  int get hashCode => Object.hash(col, row, resource);
}

/// Persisted outcome of the deterministic match-start resource distribution.
///
/// Storing placements rather than regenerating them keeps saves and multiplayer
/// replay stable even when balancing rules change in a later release.
final class InitialResourceDistribution {
  factory InitialResourceDistribution({
    required int seed,
    required Iterable<InitialResourcePlacement> placements,
    int algorithmVersion = currentAlgorithmVersion,
  }) {
    final owned = List<InitialResourcePlacement>.unmodifiable(placements);
    final coordinates = <String>{};
    for (final placement in owned) {
      final key = '${placement.col}:${placement.row}';
      if (!coordinates.add(key)) {
        throw ArgumentError.value(
          placement,
          'placements',
          'Only one generated resource may be placed on a tile.',
        );
      }
    }
    if (algorithmVersion <= 0) {
      throw ArgumentError.value(
        algorithmVersion,
        'algorithmVersion',
        'Must be positive.',
      );
    }
    return InitialResourceDistribution._(
      seed: seed,
      algorithmVersion: algorithmVersion,
      placements: owned,
    );
  }

  const InitialResourceDistribution._({
    required this.seed,
    required this.algorithmVersion,
    required this.placements,
  });

  factory InitialResourceDistribution.fromJson(Object? source) {
    if (source == null) return empty;
    if (source is! Map<Object?, Object?>) {
      throw FormatException('Invalid initial resource distribution: $source');
    }
    final json = Map<String, dynamic>.from(source);
    final seed = json['seed'];
    final version = json['algorithmVersion'];
    final placements = json['placements'];
    if (seed is! num || seed.toInt() != seed) {
      throw FormatException('Invalid initial resource seed: $seed');
    }
    if (version is! num || version.toInt() != version) {
      throw FormatException('Invalid resource algorithm version: $version');
    }
    if (placements is! List<dynamic>) {
      throw FormatException('Invalid initial resource placements: $placements');
    }
    return InitialResourceDistribution(
      seed: seed.toInt(),
      algorithmVersion: version.toInt(),
      placements: [
        for (final placement in placements)
          InitialResourcePlacement.fromJson(
            Map<String, dynamic>.from(placement as Map<Object?, Object?>),
          ),
      ],
    );
  }

  static const int currentAlgorithmVersion = 1;
  static const empty = InitialResourceDistribution._(
    seed: 0,
    algorithmVersion: currentAlgorithmVersion,
    placements: [],
  );

  final int seed;
  final int algorithmVersion;
  final List<InitialResourcePlacement> placements;

  bool get isEmpty => placements.isEmpty;

  int countForCategory(ResourceCategory category) =>
      placements.where((placement) => placement.category == category).length;

  WorldMap applyTo(WorldMap baseMap) {
    if (placements.isEmpty) return baseMap;
    final byCoordinate = {
      for (final placement in placements)
        '${placement.col}:${placement.row}': placement,
    };
    for (final placement in placements) {
      if (baseMap.tileAt(placement.col, placement.row) == null) {
        throw StateError(
          'Initial resource placement points outside the loaded map: '
          '${placement.col},${placement.row}.',
        );
      }
    }
    return baseMap.copyWith(
      tiles: [
        for (final tile in baseMap.tiles)
          if (byCoordinate['${tile.col}:${tile.row}'] case final placement?)
            tile.copyWith(
              resources: tile.resources.contains(placement.resource)
                  ? tile.resources
                  : [...tile.resources, placement.resource],
            )
          else
            tile,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'algorithmVersion': algorithmVersion,
    'placements': [for (final placement in placements) placement.toJson()],
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InitialResourceDistribution ||
        other.seed != seed ||
        other.algorithmVersion != algorithmVersion ||
        other.placements.length != placements.length) {
      return false;
    }
    for (var index = 0; index < placements.length; index++) {
      if (placements[index] != other.placements[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(seed, algorithmVersion, Object.hashAll(placements));
}
