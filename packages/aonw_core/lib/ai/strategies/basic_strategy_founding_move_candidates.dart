part of 'basic_strategy_founding_move_planner.dart';

final class _ReachableFounderMove {
  const _ReachableFounderMove({
    required this.tile,
    required this.target,
    required this.plan,
  });

  final TileData tile;
  final HexCoordinate target;
  final UnitMovementPlan plan;

  int get movementCost => plan.totalCost;

  Set<HexCoordinate> get reservedHexes => plan.reservedHexes;

  BasicStrategyFoundingMovePlan toPlan(GameUnit unit) {
    return BasicStrategyFoundingMovePlan(
      command: MoveUnitCommand(unit.id, tile.col, tile.row),
      reservedHexes: reservedHexes,
    );
  }
}

final class _FrontierMoveCandidate
    implements Comparable<_FrontierMoveCandidate> {
  const _FrontierMoveCandidate({
    required this.move,
    required this.score,
    required this.nearestOwnCityDistance,
  });

  final _ReachableFounderMove move;
  final double score;
  final int nearestOwnCityDistance;

  BasicStrategyFoundingMovePlan toPlan(GameUnit unit) => move.toPlan(unit);

  @override
  int compareTo(_FrontierMoveCandidate other) {
    return _firstNonZero([
      other.score.compareTo(score),
      other.nearestOwnCityDistance.compareTo(nearestOwnCityDistance),
      other.move.movementCost.compareTo(move.movementCost),
      move.tile.col.compareTo(other.move.tile.col),
      move.tile.row.compareTo(other.move.tile.row),
    ]);
  }
}

final class _FounderRevealMoveCandidate
    implements Comparable<_FounderRevealMoveCandidate> {
  const _FounderRevealMoveCandidate({
    required this.move,
    required this.revealGain,
    required this.centerDistance,
  });

  final _ReachableFounderMove move;
  final int revealGain;
  final int centerDistance;

  BasicStrategyFoundingMovePlan toPlan(GameUnit unit) => move.toPlan(unit);

  @override
  int compareTo(_FounderRevealMoveCandidate other) {
    return _firstNonZero([
      other.revealGain.compareTo(revealGain),
      centerDistance.compareTo(other.centerDistance),
      move.movementCost.compareTo(other.move.movementCost),
      move.tile.col.compareTo(other.move.tile.col),
      move.tile.row.compareTo(other.move.tile.row),
    ]);
  }
}

final class _FounderRetreatCandidate
    implements Comparable<_FounderRetreatCandidate> {
  const _FounderRetreatCandidate({
    required this.move,
    required this.nearestEnemyDistance,
    required this.nearestOwnCityDistance,
    required this.escorted,
  });

  final _ReachableFounderMove move;
  final int nearestEnemyDistance;
  final int nearestOwnCityDistance;
  final bool escorted;

  BasicStrategyFoundingMovePlan toPlan(GameUnit unit) => move.toPlan(unit);

  @override
  int compareTo(_FounderRetreatCandidate other) {
    return _firstNonZero([
      (other.escorted ? 1 : 0).compareTo(escorted ? 1 : 0),
      other.nearestEnemyDistance.compareTo(nearestEnemyDistance),
      nearestOwnCityDistance.compareTo(other.nearestOwnCityDistance),
      move.tile.col.compareTo(other.move.tile.col),
      move.tile.row.compareTo(other.move.tile.row),
    ]);
  }
}

extension _FounderUnitHex on GameUnit {
  HexCoordinate get hex => HexCoordinate(col: col, row: row);
}

int _firstNonZero(Iterable<int> comparisons) {
  for (final comparison in comparisons) {
    if (comparison != 0) return comparison;
  }
  return 0;
}
