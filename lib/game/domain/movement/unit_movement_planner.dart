import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

class UnitMovementPlanner {
  final MapTraversalView mapData;
  final List<GameUnit> units;
  final bool Function(MapTileView tile)? canEnterTile;

  UnitMovementPlanner({
    required this.mapData,
    required Iterable<GameUnit> units,
    this.canEnterTile,
  }) : units = List.unmodifiable(units);

  UnitMovementPlan? planMove({
    required GameUnit unit,
    required MapTileView targetTile,
    UnitMovementCapacityException? canEnterStepBeyondCapacity,
  }) {
    return UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      canEnterTile: canEnterTile,
    ).plan(
      unit: unit,
      targetTile: targetTile,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
  }
}
