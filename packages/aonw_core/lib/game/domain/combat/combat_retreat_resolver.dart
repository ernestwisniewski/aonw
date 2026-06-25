import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_data.dart';

typedef CombatRetreatTileLookup = TileData? Function(int col, int row);

abstract final class CombatRetreatResolver {
  static HexCoordinate? destination({
    required GameUnit attacker,
    required GameUnit defender,
    required Iterable<GameUnit> units,
    required CombatRetreatTileLookup tileAt,
  }) {
    final candidates = <HexCoordinate>[];
    for (final neighbor in HexGridTopology.neighbors(
      col: defender.col,
      row: defender.row,
    )) {
      final tile = tileAt(neighbor.col, neighbor.row);
      if (tile == null) continue;
      if (UnitMovementCostRules.costToEnterTile(
        tile,
        unitType: defender.type,
      ).blocked) {
        continue;
      }
      if (_isOccupied(
        col: neighbor.col,
        row: neighbor.row,
        units: units,
        ignoredUnitId: defender.id,
      )) {
        continue;
      }
      candidates.add(HexCoordinate(col: neighbor.col, row: neighbor.row));
    }

    if (candidates.isEmpty) return null;

    final attackerHex = HexCoordinate(col: attacker.col, row: attacker.row);
    candidates.sort((left, right) {
      final distance = HexDistance.between(
        right,
        attackerHex,
      ).compareTo(HexDistance.between(left, attackerHex));
      if (distance != 0) return distance;
      final col = left.col.compareTo(right.col);
      if (col != 0) return col;
      return left.row.compareTo(right.row);
    });
    return candidates.first;
  }

  static bool _isOccupied({
    required int col,
    required int row,
    required Iterable<GameUnit> units,
    required String ignoredUnitId,
  }) {
    for (final unit in units) {
      if (unit.id == ignoredUnitId) continue;
      if (unit.occupies(col, row)) return true;
    }
    return false;
  }
}
