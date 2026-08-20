import 'package:aonw_core/map/domain/terrain_type.dart';

/// Explicit terrain meanings consumed by distinct gameplay bounded contexts.
///
/// [movementTerrains] is the normalized movement profile (one base followed
/// by features). [displayTerrain] preserves the authored visual identity,
/// [yieldTerrain] owns the base economic yield, and [terrainTags] is the full
/// authored tag set used by combat, economy, AI, and presentation rules.
final class TileTerrainSemantics {
  factory TileTerrainSemantics({
    required Iterable<TerrainType> movementTerrains,
    required TerrainType displayTerrain,
    required TerrainType yieldTerrain,
    required Iterable<TerrainType> terrainTags,
  }) {
    final ownedMovement = List<TerrainType>.unmodifiable(movementTerrains);
    final ownedTags = List<TerrainType>.unmodifiable(terrainTags);
    _validate(
      movementTerrains: ownedMovement,
      displayTerrain: displayTerrain,
      yieldTerrain: yieldTerrain,
      terrainTags: ownedTags,
    );
    return TileTerrainSemantics._(
      movementTerrains: ownedMovement,
      displayTerrain: displayTerrain,
      yieldTerrain: yieldTerrain,
      terrainTags: ownedTags,
    );
  }

  /// Creates semantics for a generated tile whose movement profile is also
  /// its complete authored meaning.
  ///
  /// Canonical map loading never uses this factory: persisted content must
  /// supply all four meanings explicitly.
  factory TileTerrainSemantics.fromMovementProfile(
    Iterable<TerrainType> movementTerrains,
  ) {
    final ownedMovement = List<TerrainType>.unmodifiable(movementTerrains);
    if (ownedMovement.isEmpty) {
      throw const TileTerrainSemanticsException(
        'Movement terrains must not be empty',
      );
    }
    final primary = ownedMovement.first;
    return TileTerrainSemantics(
      movementTerrains: ownedMovement,
      displayTerrain: primary,
      yieldTerrain: primary,
      terrainTags: ownedMovement,
    );
  }

  /// Normalizes an explicit editor/generator terrain selection into the
  /// canonical movement profile while retaining its full authored meaning.
  ///
  /// This is an authoring boundary, not a persisted-content fallback. Loaded
  /// JSON must always provide the already-resolved four semantic fields.
  factory TileTerrainSemantics.fromAuthoredTerrainTags(
    Iterable<TerrainType> authoredTerrainTags,
  ) {
    final tags = List<TerrainType>.unmodifiable(authoredTerrainTags);
    if (tags.isEmpty) {
      throw const TileTerrainSemanticsException(
        'Authored terrain tags must not be empty',
      );
    }
    if (tags.toSet().length != tags.length) {
      throw const TileTerrainSemanticsException(
        'Authored terrain tags must be unique',
      );
    }
    final yieldTerrain = tags.cast<TerrainType?>().firstWhere(
      (terrain) => terrain != TerrainType.river,
      orElse: () => null,
    );
    if (yieldTerrain == null) {
      throw const TileTerrainSemanticsException(
        'Authored terrain tags must include a non-river yield terrain',
      );
    }

    final movementPrimary = _movementPrimaryFor(tags);
    final movementFeatures = [
      for (final feature in _terrainFeatures)
        if (tags.contains(feature)) feature,
    ];
    return TileTerrainSemantics(
      movementTerrains: [movementPrimary, ...movementFeatures],
      displayTerrain: tags.first,
      yieldTerrain: yieldTerrain,
      terrainTags: tags,
    );
  }

  const TileTerrainSemantics._({
    required this.movementTerrains,
    required this.displayTerrain,
    required this.yieldTerrain,
    required this.terrainTags,
  });

  final List<TerrainType> movementTerrains;
  final TerrainType displayTerrain;
  final TerrainType yieldTerrain;
  final List<TerrainType> terrainTags;

  static void _validate({
    required List<TerrainType> movementTerrains,
    required TerrainType displayTerrain,
    required TerrainType yieldTerrain,
    required List<TerrainType> terrainTags,
  }) {
    if (movementTerrains.isEmpty) {
      throw const TileTerrainSemanticsException(
        'Movement terrains must not be empty',
      );
    }
    if (!_primaryTerrains.contains(movementTerrains.first)) {
      throw TileTerrainSemanticsException(
        'Movement terrain ${movementTerrains.first.name} must be a primary terrain',
      );
    }
    if (movementTerrains
        .skip(1)
        .any((value) => !_terrainFeatures.contains(value))) {
      throw const TileTerrainSemanticsException(
        'Movement terrains after the primary must be terrain features',
      );
    }
    if (movementTerrains.toSet().length != movementTerrains.length) {
      throw const TileTerrainSemanticsException(
        'Movement terrains must be unique',
      );
    }
    if (terrainTags.isEmpty) {
      throw const TileTerrainSemanticsException(
        'Terrain tags must not be empty',
      );
    }
    if (terrainTags.toSet().length != terrainTags.length) {
      throw const TileTerrainSemanticsException('Terrain tags must be unique');
    }
    if (!terrainTags.contains(displayTerrain)) {
      throw const TileTerrainSemanticsException(
        'Display terrain must be present in terrain tags',
      );
    }
    if (yieldTerrain == TerrainType.river) {
      throw const TileTerrainSemanticsException(
        'River cannot own the base terrain yield',
      );
    }
    if (!terrainTags.contains(yieldTerrain)) {
      throw const TileTerrainSemanticsException(
        'Yield terrain must be present in terrain tags',
      );
    }
    if (movementTerrains
        .skip(1)
        .any((feature) => !terrainTags.contains(feature))) {
      throw const TileTerrainSemanticsException(
        'Movement features must be present in terrain tags',
      );
    }
  }
}

TerrainType _movementPrimaryFor(List<TerrainType> tags) {
  if (tags.contains(TerrainType.mountain)) return TerrainType.mountain;

  TerrainType? primary;
  for (final terrain in tags) {
    if (!_primaryTerrains.contains(terrain) ||
        terrain == TerrainType.mountain) {
      continue;
    }
    if (primary == null ||
        (_openWaterTerrains.contains(primary) &&
            !_openWaterTerrains.contains(terrain))) {
      primary = terrain;
    }
  }
  if (primary != null) return primary;
  if (tags.any(_vegetatedFeatures.contains)) return TerrainType.grassland;
  if (tags.contains(TerrainType.hills)) return TerrainType.plains;
  throw const TileTerrainSemanticsException(
    'Authored terrain tags do not resolve to a movement primary',
  );
}

final class TileTerrainSemanticsException implements Exception {
  const TileTerrainSemanticsException(this.message);

  final String message;

  @override
  String toString() => 'TileTerrainSemanticsException: $message';
}

const _primaryTerrains = {
  TerrainType.ocean,
  TerrainType.coast,
  TerrainType.lake,
  TerrainType.plains,
  TerrainType.grassland,
  TerrainType.desert,
  TerrainType.tundra,
  TerrainType.snow,
  TerrainType.mountain,
};

const _terrainFeatures = {
  TerrainType.hills,
  TerrainType.wetlands,
  TerrainType.jungle,
  TerrainType.forest,
  TerrainType.river,
};

const _openWaterTerrains = {TerrainType.ocean, TerrainType.lake};

const _vegetatedFeatures = {
  TerrainType.wetlands,
  TerrainType.jungle,
  TerrainType.forest,
};
