import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';

/// Immutable route restrictions selected before movement command resolution.
///
/// Keeping these restrictions next to the command lets a higher-level planner
/// and the authoritative movement resolver agree on the exact traversable
/// graph without sharing a pathfinder instance.
final class MovementCommandPathConstraints {
  const MovementCommandPathConstraints.none() : excludedHexes = const {};

  MovementCommandPathConstraints.excluding({
    required Iterable<HexCoordinate> excludedHexes,
  }) : excludedHexes = Set<HexCoordinate>.unmodifiable(excludedHexes);

  final Set<HexCoordinate> excludedHexes;

  bool excludes(int col, int row) {
    return excludedHexes.isNotEmpty &&
        excludedHexes.contains(HexCoordinate(col: col, row: row));
  }
}
