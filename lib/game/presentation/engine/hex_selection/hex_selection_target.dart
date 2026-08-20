import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class HexSelectionTarget {
  const HexSelectionTarget({required this.label, required this.icon});

  final String label;
  final GameIconData icon;

  String get key;
}

final class TerrainHexSelectionTarget extends HexSelectionTarget {
  const TerrainHexSelectionTarget({required this.tile, required super.label})
    : super(icon: GameIcons.terrain);

  final WorldTile tile;

  @override
  String get key => 'terrain:${tile.col}:${tile.row}';
}

final class UnitHexSelectionTarget extends HexSelectionTarget {
  const UnitHexSelectionTarget({
    required this.unit,
    required super.label,
    required super.icon,
  });

  final GameUnit unit;

  @override
  String get key => 'unit:${unit.id}';
}

final class CityHexSelectionTarget extends HexSelectionTarget {
  const CityHexSelectionTarget({required this.city, required super.label})
    : super(icon: GameIcons.cityFilled);

  final GameCity city;

  @override
  String get key => 'city:${city.id}';
}

final class FieldImprovementHexSelectionTarget extends HexSelectionTarget {
  const FieldImprovementHexSelectionTarget({
    required this.improvement,
    required super.label,
  }) : super(icon: GameIcons.improvement);

  final FieldImprovement improvement;

  @override
  String get key => 'improvement:${improvement.hex.col}:${improvement.hex.row}';
}

final class ArtifactHexSelectionTarget extends HexSelectionTarget {
  const ArtifactHexSelectionTarget({
    required this.artifact,
    required super.label,
    required super.icon,
  });

  final WorldArtifact artifact;

  @override
  String get key => 'artifact:${artifact.id}';
}

final class ObjectiveHexSelectionTarget extends HexSelectionTarget {
  const ObjectiveHexSelectionTarget({
    required this.progress,
    required super.label,
    required super.icon,
  });

  final MapObjectiveProgress progress;

  @override
  String get key => 'objective:${progress.definition.id}';
}
