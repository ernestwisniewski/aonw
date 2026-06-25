import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

class UnitMovementPlanner {
  final MapData mapData;
  final List<GameUnit> units;
  final bool Function(TileData tile)? canEnterTile;

  UnitMovementPlanner({
    required this.mapData,
    required Iterable<GameUnit> units,
    this.canEnterTile,
  }) : units = List.unmodifiable(units);

  UnitMovementPlan? planMove({
    required GameUnit unit,
    required TileData targetTile,
  }) {
    return UnitMovementPathfinder(
      mapData: mapData,
      units: units,
      canEnterTile: canEnterTile,
    ).plan(unit: unit, targetTile: targetTile);
  }
}
