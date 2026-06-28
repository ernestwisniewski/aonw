import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';

final class MctsMovementCandidateCollector {
  const MctsMovementCandidateCollector();

  Iterable<GameCommand> commandsFor(GameView view) sync* {
    final units = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));
    final pathfinder = UnitMovementPathfinder(
      mapData: view.mapData,
      units: view.movementBlockingUnits,
    );

    for (final unit in units) {
      if (!unit.isReadyToAct || unit.isMerchant) continue;

      final origin = HexCoordinate(col: unit.col, row: unit.row);
      for (final neighbor in HexNeighbors.existingAround(
        origin,
        view.mapData,
      )) {
        final tile = view.mapData.tileAt(neighbor.col, neighbor.row);
        if (tile == null) continue;
        if (!view.visibility.canSeeDynamicAt(tile.col, tile.row)) continue;
        final plan = pathfinder.plan(unit: unit, targetTile: tile);
        if (plan == null || !plan.canMoveNow) continue;

        yield MoveUnitCommand(unit.id, neighbor.col, neighbor.row);
      }
    }
  }
}
