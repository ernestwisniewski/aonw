import 'package:flutter_test/flutter_test.dart';

import 'support/movement_command_boundary_guard.dart';

void main() {
  test('path constraints reject a borrowed mutable exclusion set', () {
    final violations = movementPathConstraintsShapeViolations('''
final class MovementCommandPathConstraints {
  const MovementCommandPathConstraints.none() : excludedHexes = const {};

  MovementCommandPathConstraints.excluding({
    required Iterable<HexCoordinate> excludedHexes,
  }) : excludedHexes = excludedHexes.toSet();

  final Set<HexCoordinate> excludedHexes;

  bool excludes(int col, int row) => false;
}
''');

    expect(
      violations,
      contains(
        'MovementCommandPathConstraints must own an unmodifiable exclusion '
        'copy',
      ),
    );
  });

  test('auto-explore target rejects a widened public surface', () {
    final violations = movementScoutAutoExploreTargetShapeViolations('''
final class ScoutAutoExploreTarget {
  const ScoutAutoExploreTarget({
    required this.command,
    required this.pathConstraints,
  });

  final MoveUnitCommand command;
  final MovementCommandPathConstraints pathConstraints;

  MoveUnitCommand recompute() => command;
}
''');

    expect(
      violations,
      contains('ScoutAutoExploreTarget must not widen its public API'),
    );
  });
}
