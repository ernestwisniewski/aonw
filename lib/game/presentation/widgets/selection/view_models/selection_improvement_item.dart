import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

enum SelectionImprovementState {
  built,
  available,
  needsTechnology,
  needsCity,
  blocked,
}

class SelectionImprovementItem {
  final FieldImprovementType type;
  final String title;
  final TileYield yield;
  final int buildTurns;
  final SelectionImprovementState state;
  final String technologyRequirement;
  final String buildingRequirement;
  final String cityRequirement;

  const SelectionImprovementItem({
    required this.type,
    required this.title,
    required this.yield,
    required this.buildTurns,
    required this.state,
    required this.technologyRequirement,
    required this.buildingRequirement,
    required this.cityRequirement,
  });
}
