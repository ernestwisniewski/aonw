import 'package:aonw_core/game/domain/city/field_improvement_requirement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

class FieldImprovementDefinition {
  final FieldImprovementType type;
  final TileYield tileYield;
  final int buildTurns;
  final bool resourceSpecialist;
  final List<FieldImprovementRequirement> requirements;

  const FieldImprovementDefinition({
    required this.type,
    required this.tileYield,
    required this.buildTurns,
    this.resourceSpecialist = false,
    this.requirements = const [],
  });

  bool canImprove(MapTileView tile) {
    return requirements.every((requirement) => requirement.matches(tile));
  }

  FieldImprovementRequirementFailure? failureFor(MapTileView tile) {
    for (final requirement in requirements) {
      final failure = requirement.failureFor(tile);
      if (failure != null) return failure;
    }
    return null;
  }
}
