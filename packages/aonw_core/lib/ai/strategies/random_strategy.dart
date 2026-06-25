import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class RandomStrategy implements AiStrategy {
  const RandomStrategy({
    this.excludedUnitIds = const {},
    this.reservedHexes = const {},
  });

  final Set<String> excludedUnitIds;
  final Set<HexCoordinate> reservedHexes;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    var rng = context.rng;
    final commands = <GameCommand>[];
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final knownUnits = view.movementBlockingUnits;
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: knownUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row),
    );
    final units = [
      for (final unit in view.ownUnits)
        if (!excludedUnitIds.contains(unit.id)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      if (unit.movementPoints <= 0 ||
          unit.isWorking ||
          unit.queuedPath != null) {
        continue;
      }

      final candidates = _candidateMoves(
        unit: unit,
        view: view,
        mapData: context.mapData,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (candidates.isEmpty) continue;

      final draw = rng.nextInt(candidates.length);
      rng = draw.rng;
      final target = candidates[draw.value];
      commands.add(MoveUnitCommand(unit.id, target.col, target.row));
      occupied
        ..remove(_key(unit.col, unit.row))
        ..add(_key(target.col, target.row));
    }

    return AiTurnPlan(
      commands: commands,
      debug: AiDebugInfo(
        strategyId: 'random',
        notes: ['planned ${commands.length} movement commands'],
      ),
    );
  }

  List<TileData> _candidateMoves({
    required GameUnit unit,
    required GameView view,
    required MapData mapData,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final candidates = <TileData>[];
    for (final hex in HexNeighbors.existingAround(
      HexCoordinate(col: unit.col, row: unit.row),
      mapData,
    )) {
      if (occupied.contains(_key(hex.col, hex.row))) continue;
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null ||
          !view.visibility.canSeeDynamicAt(tile.col, tile.row)) {
        continue;
      }

      final plan = pathfinder.plan(unit: unit, targetTile: tile);
      if (plan == null || plan.totalCost > unit.movementPoints) continue;
      candidates.add(tile);
    }
    candidates.sort((a, b) {
      final col = a.col.compareTo(b.col);
      if (col != 0) return col;
      return a.row.compareTo(b.row);
    });
    return candidates;
  }

  static String _key(int col, int row) => '$col:$row';
}
