import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MovementCommandPathConstraints', () {
    test('none is canonical and immutable', () {
      const first = MovementCommandPathConstraints.none();
      const second = MovementCommandPathConstraints.none();

      expect(identical(first, second), isTrue);
      expect(first.excludedHexes, isEmpty);
      expect(
        () => first.excludedHexes.add(const HexCoordinate(col: 1, row: 0)),
        throwsUnsupportedError,
      );
    });

    test('owns an immutable copy of excluded hexes', () {
      final source = {const HexCoordinate(col: 3, row: 0)};
      final constraints = MovementCommandPathConstraints.excluding(
        excludedHexes: source,
      );

      source.add(const HexCoordinate(col: 4, row: 0));

      expect(constraints.excludes(3, 0), isTrue);
      expect(constraints.excludes(4, 0), isFalse);
      expect(
        () =>
            constraints.excludedHexes.add(const HexCoordinate(col: 5, row: 0)),
        throwsUnsupportedError,
      );
    });

    test('auto-explore replan keeps the selected route reservation', () {
      final fixture = _reservationFixture();
      final target = const ScoutAutoExplorePlanner().targetFor(
        unit: fixture.secondScout,
        mapData: fixture.map,
        units: fixture.state.units,
        fogOfWar: fixture.state.fogOfWar,
      );

      expect(target, isNotNull);
      expect((target!.command.targetCol, target.command.targetRow), (5, 0));
      expect(target.pathConstraints.excludes(3, 0), isTrue);

      final result = const MovementCommandResolver().resolve(
        state: fixture.state,
        command: target.command,
        actorPlayerId: _playerId,
        mapData: fixture.map,
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
        pathConstraints: target.pathConstraints,
      );

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      expect(
        _coordinates(result.execution!.steps),
        isNot(contains(const (3, 0))),
      );
      expect(
        _coordinates(result.execution!.steps),
        containsAll(const [(3, 1), (4, 1)]),
      );
    });

    test('no constraints preserves the existing unrestricted route', () {
      final fixture = _reservationFixture();
      final target = const ScoutAutoExplorePlanner().targetFor(
        unit: fixture.secondScout,
        mapData: fixture.map,
        units: fixture.state.units,
        fogOfWar: fixture.state.fogOfWar,
      )!;

      final result = const MovementCommandResolver().resolve(
        state: fixture.state,
        command: target.command,
        actorPlayerId: _playerId,
        mapData: fixture.map,
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
      );

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      expect(_coordinates(result.execution!.steps), contains(const (3, 0)));
    });

    test('hidden-target approach keeps the same exclusions', () {
      final fixture = _reservationFixture();
      final hiddenBlocker = GameUnit(
        id: 'hidden_blocker',
        ownerPlayerId: _opponentId,
        type: GameUnitType.warrior,
        name: 'hidden_blocker',
        col: 5,
        row: 0,
      );
      final state = MovementCommandState(
        units: [...fixture.state.units, hiddenBlocker],
        cities: fixture.state.cities,
        fogOfWar: fixture.state.fogOfWar,
        diplomacy: fixture.state.diplomacy,
        playerIds: const [_playerId, _opponentId],
      );

      final result = const MovementCommandResolver().resolve(
        state: state,
        command: const MoveUnitCommand('second_scout', 5, 0),
        actorPlayerId: _playerId,
        mapData: fixture.map,
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
        pathConstraints: MovementCommandPathConstraints.excluding(
          excludedHexes: const [HexCoordinate(col: 3, row: 0)],
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.execution, isNotNull);
      expect(
        _coordinates(result.execution!.steps),
        isNot(contains(const (3, 0))),
      );
      final moved = result.units.firstWhere(
        (unit) => unit.id == fixture.secondScout.id,
      );
      expect((moved.col, moved.row), isNot(const (5, 0)));
    });
  });
}

const _playerId = 'player_1';
const _opponentId = 'player_2';

({WorldMap map, GameUnit secondScout, MovementCommandState state})
_reservationFixture() {
  final map = _grassMap(cols: 6, rows: 2);
  final firstScout = _scout(id: 'first_scout', col: 2, row: 0)
      .copyWithPosture(UnitPosture.autoExploring)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 3,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
            UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
          ],
        ),
      );
  final secondScout = _scout(
    id: 'second_scout',
    col: 0,
    row: 1,
    movementPoints: 5,
  );
  final knownHexes = {
    for (var col = 0; col < 5; col++)
      for (var row = 0; row < 2; row++) HexCoordinate(col: col, row: row),
  };
  final fogOfWar = FogOfWarState(
    players: {
      _playerId: PlayerFogOfWar(
        playerId: _playerId,
        discoveredHexes: knownHexes,
        visibleHexes: knownHexes,
      ),
    },
  );
  return (
    map: map,
    secondScout: secondScout,
    state: MovementCommandState(
      units: [firstScout, secondScout],
      cities: const [],
      fogOfWar: fogOfWar,
      diplomacy: DiplomacyState.empty,
      playerIds: const [_playerId],
    ),
  );
}

WorldMap _grassMap({required int cols, required int rows}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

GameUnit _scout({
  required String id,
  required int col,
  required int row,
  int? movementPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.scout,
    name: id,
    col: col,
    row: row,
    movementPoints: movementPoints,
  );
}

List<(int, int)> _coordinates(Iterable<UnitMovementStep> steps) => [
  for (final step in steps) (step.col, step.row),
];
