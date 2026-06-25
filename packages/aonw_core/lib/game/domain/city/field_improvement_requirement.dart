import 'package:aonw_core/game/domain/tile_yield/tile_yield_rules.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum FieldImprovementRequirementFailureType {
  missingResource,
  invalidTerrain,
  missingRiver,
}

class FieldImprovementRequirementFailure {
  final FieldImprovementRequirementFailureType type;

  const FieldImprovementRequirementFailure(this.type);

  @override
  bool operator ==(Object other) =>
      other is FieldImprovementRequirementFailure && other.type == type;

  @override
  int get hashCode => Object.hash(FieldImprovementRequirementFailure, type);
}

sealed class FieldImprovementRequirement {
  const FieldImprovementRequirement();

  FieldImprovementRequirementFailure? failureFor(TileData tile);

  bool matches(TileData tile) => failureFor(tile) == null;
}

class RequiresAnyResource extends FieldImprovementRequirement {
  final Set<ResourceType> resources;

  const RequiresAnyResource(this.resources);

  @override
  FieldImprovementRequirementFailure? failureFor(TileData tile) {
    if (tile.resources.any(resources.contains)) return null;
    return const FieldImprovementRequirementFailure(
      FieldImprovementRequirementFailureType.missingResource,
    );
  }
}

class RequiresAnyBaseTerrain extends FieldImprovementRequirement {
  final Set<TerrainType> terrains;

  const RequiresAnyBaseTerrain(this.terrains);

  @override
  FieldImprovementRequirementFailure? failureFor(TileData tile) {
    final terrain = TileYieldRules.baseTerrainOrNull(tile);
    if (terrain != null && terrains.contains(terrain)) return null;
    return const FieldImprovementRequirementFailure(
      FieldImprovementRequirementFailureType.invalidTerrain,
    );
  }
}

class RequiresRiver extends FieldImprovementRequirement {
  const RequiresRiver();

  @override
  FieldImprovementRequirementFailure? failureFor(TileData tile) {
    if (TileYieldRules.hasRiver(tile)) return null;
    return const FieldImprovementRequirementFailure(
      FieldImprovementRequirementFailureType.missingRiver,
    );
  }
}
