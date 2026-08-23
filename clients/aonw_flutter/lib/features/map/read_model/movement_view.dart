import 'map_view.dart';
import 'player_map_view.dart';

final class ReachableTileView {
  const ReachableTileView({
    required this.coordinate,
    required this.costUnits,
    required this.exhaustsMovement,
  });

  final MapHexCoordinate coordinate;
  final int costUnits;
  final bool exhaustsMovement;
}

final class ReachableView {
  ReachableView({
    required this.stamp,
    required this.unitId,
    required this.availableMovementUnits,
    required List<ReachableTileView> tiles,
  }) : tiles = List.unmodifiable(tiles),
       _tilesByCoordinate = Map.unmodifiable({
         for (final tile in tiles) tile.coordinate: tile,
       });

  final SessionStampView stamp;
  final String unitId;
  final int availableMovementUnits;
  final List<ReachableTileView> tiles;
  final Map<MapHexCoordinate, ReachableTileView> _tilesByCoordinate;

  ReachableTileView? tileAt(MapHexCoordinate coordinate) =>
      _tilesByCoordinate[coordinate];
}

final class MovementStepView {
  const MovementStepView({
    required this.coordinate,
    required this.enterCostUnits,
    required this.cumulativeCostUnits,
  });

  final MapHexCoordinate coordinate;
  final int enterCostUnits;
  final int cumulativeCostUnits;
}

final class RoutePlanView {
  RoutePlanView({
    required this.stamp,
    required this.unitId,
    required this.target,
    required this.destination,
    required this.totalCostUnits,
    required this.availableMovementUnits,
    required this.remainingMovementUnits,
    required List<MovementStepView> steps,
  }) : steps = List.unmodifiable(steps);

  final SessionStampView stamp;
  final String unitId;
  final MapHexCoordinate target;
  final MapHexCoordinate destination;
  final int totalCostUnits;
  final int availableMovementUnits;
  final int remainingMovementUnits;
  final List<MovementStepView> steps;
}

final class MoveUnitResultView {
  const MoveUnitResultView.accepted({required this.player})
    : accepted = true,
      rejectionCode = null;

  const MoveUnitResultView.rejected({required String code})
    : accepted = false,
      rejectionCode = code,
      player = null;

  final bool accepted;
  final String? rejectionCode;
  final PlayerMapView? player;
}
