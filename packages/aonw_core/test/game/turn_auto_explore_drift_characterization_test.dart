import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:test/test.dart';

part 'support/turn_auto_explore_continuation_characterization.dart';

void main() {
  group('turn auto-explore drift characterization', () {
    test('legacy enters a known foreign city regardless of diplomacy', () {
      final scout = _autoExploringScout(movementPoints: 1);
      const foreignCity = GameCity(
        id: 'foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final fog = _fog(discovered: _lineHexes(2), visible: _lineHexes(2));
      final map = _map(cols: 3);
      final peace = _runLegacyAndKernel(
        units: [scout],
        cities: const [foreignCity],
        fogOfWar: fog,
        mapData: map,
      );
      final war = _runLegacyAndKernel(
        units: [scout],
        cities: const [foreignCity],
        fogOfWar: fog,
        diplomacy: _warDiplomacy(),
        mapData: map,
      );

      expect(peace.legacy.changed, isTrue);
      expect(
        peace.legacy.units.map(_autoExploreTurnUnitSnapshot),
        war.legacy.units.map(_autoExploreTurnUnitSnapshot),
      );
      expect(
        (peace.legacy.units.single.col, peace.legacy.units.single.row),
        (1, 0),
      );
      expect(peace.legacy.units.single.queuedPath?.targetCol, 2);
      expect(peace.legacy.units.single.posture, UnitPosture.autoExploring);
      expect(peace.kernel.accepted, isTrue);
      expect(peace.kernel.state.units.single.posture, UnitPosture.active);
      expect(peace.kernel.execution, isNull);
      expect(war.kernel.accepted, isTrue);
      expect(
        (war.kernel.state.units.single.col, war.kernel.state.units.single.row),
        (0, 0),
      );
      expect(war.kernel.state.units.single.posture, UnitPosture.active);
      expect(war.kernel.events, isEmpty);
      expect(war.kernel.execution, isNull);
    });

    test('enters terrain beyond per-turn movement capacity', () {
      final scout = _autoExploringScout(movementPoints: 2);
      final map = _map(
        cols: 2,
        terrainOverrides: const {
          1: [TerrainType.snow, TerrainType.forest, TerrainType.hills],
        },
      );
      final target = map.tileAt(1, 0)!;
      final targetCost = UnitMovementCostRules.costToEnterTile(
        target,
        unitType: scout.type,
      );
      final capacity = UnitMovementBalance.maxMovementPointsFor(
        type: scout.type,
        carriedArtifactId: scout.carriedArtifactId,
      );
      expect(targetCost.value, greaterThan(capacity));

      final pair = _runLegacyAndKernel(
        units: [scout],
        fogOfWar: _originOnlyFog(),
        mapData: map,
      );
      final moved = pair.legacy.units.single;

      expect(pair.legacy.changed, isTrue);
      expect((moved.col, moved.movementPoints), (1, 0));
      expect(moved.posture, UnitPosture.autoExploring);
      expect(pair.kernel.accepted, isFalse);
      expect(pair.kernel.reason, 'unit_movement_capacity_insufficient');
      expect(pair.kernel.state, same(pair.kernelInput));
      expect(pair.kernel.events, isEmpty);
      expect(pair.kernel.execution, isNull);
    });

    test('hidden full-state blocker changes the chosen destination', () {
      final scout = _autoExploringScout(movementPoints: 2);
      final blocker = GameUnit(
        id: 'hidden_blocker',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Hidden blocker',
        col: 2,
        row: 0,
      );
      final map = _map(cols: 5);

      final projected = _advance(
        units: [scout],
        fogOfWar: _originOnlyFog(),
        mapData: map,
      );
      final fullState = _runLegacyAndKernel(
        units: [scout, blocker],
        fogOfWar: _originOnlyFog(),
        mapData: map,
      );

      expect(projected.units.first.col, 2);
      expect(fullState.legacy.units.first.col, 1);
      expect(fullState.legacy.units.last, same(blocker));
      expect(fullState.kernel.accepted, isTrue);
      expect(fullState.kernel.state.units.first.col, 1);
      expect(
        fullState.kernel.state.units.first.posture,
        UnitPosture.autoExploring,
      );
      expect(fullState.kernel.state.units.last, same(blocker));
      expect(
        _eventSnapshot(fullState.kernel.events.single as UnitMovedEvent),
        'turn_auto_scout:0,0->1,0',
      );
      expect(
        _executionSnapshot(fullState.kernel.execution!),
        'turn_auto_scout:0,0->1,0',
      );
    });

    test('no target keeps auto-explore posture and reports no change', () {
      final scout = _autoExploringScout(movementPoints: 2);
      final inputFog = _originOnlyFog();

      final pair = _runLegacyAndKernel(
        units: [scout],
        fogOfWar: inputFog,
        mapData: _map(cols: 1),
      );

      expect(pair.legacy.changed, isFalse);
      expect(pair.legacy.units.single, same(scout));
      expect(pair.legacy.units.single.posture, UnitPosture.autoExploring);
      expect(pair.legacy.fogOfWar, same(inputFog));
      expect(pair.kernel.accepted, isTrue);
      expect(pair.kernel.state.units.single.posture, UnitPosture.active);
      expect(pair.kernel.events, isEmpty);
      expect(pair.kernel.execution, isNull);
    });

    test('finishes a queued path before choosing the next automatic route', () {
      final scout = _autoExploringScout(movementPoints: 0).copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 1,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );

      final result = TurnMovementOrchestrator.resetForPlayers(
        state: TurnMovementState(
          units: [scout],
          cities: const [],
          diplomacy: DiplomacyState.empty,
          fogOfWar: _originOnlyFog(),
        ),
        context: TurnMovementContext(
          playerIds: const {_playerId},
          phaseKnownPlayerIds: const {_playerId},
          mapData: _map(cols: 6),
        ),
      );
      final moved = result.state.units.single;

      expect(result.changed, isTrue);
      expect(
        (
          col: moved.col,
          movementPoints: moved.movementPoints,
          queuedTargetCol: moved.queuedPath?.targetCol,
          posture: moved.posture,
        ),
        (
          col: 3,
          movementPoints: 0,
          queuedTargetCol: 4,
          posture: UnitPosture.autoExploring,
        ),
      );
      expect(moved.queuedPath?.steps.map((step) => step.col), [1, 2, 3, 4]);
      expect(
        result.state.fogOfWar.fogForPlayer(_playerId).discoveredHexes,
        _lineHexes(6),
      );
    });

    test('updates fog sequentially but replans across a reserved route', () {
      final first = _autoExploringScout(
        id: 'first_scout',
        row: 0,
        movementPoints: 2,
      );
      final second = _autoExploringScout(
        id: 'second_scout',
        row: 1,
        movementPoints: 2,
      );
      final origins = {
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 0, row: 1),
      };

      final result = _advance(
        units: [first, second],
        fogOfWar: _fog(discovered: origins, visible: origins),
        mapData: _map(cols: 6, rows: 2),
      );
      final secondWithoutFirst = _advance(
        units: [second],
        fogOfWar: _fog(discovered: origins, visible: origins),
        mapData: _map(cols: 6, rows: 2),
      );

      expect(result.changed, isTrue);
      expect(
        _autoExploreTurnUnitSnapshot(secondWithoutFirst.units.single),
        'second_scout:2,0;mp=0;target=3,0;steps=0,1|1,0|2,0|3,0',
      );
      expect(result.units.map(_autoExploreTurnUnitSnapshot), [
        'first_scout:2,0;mp=0;target=3,0;steps=0,0|1,0|2,0|3,0',
        'second_scout:2,1;mp=0;target=5,0;steps=0,1|1,0|2,1|3,0|4,0|5,0',
      ]);
      expect(
        _sharedQueuedPathCoordinates(result.units[0], result.units[1]),
        const ['1,0', '3,0'],
      );
      expect(
        result.fogOfWar
            .fogForPlayer(_playerId)
            .discoveredHexes
            .map((hex) => '${hex.col},${hex.row}')
            .toList()
          ..sort(),
        const [
          '0,0',
          '0,1',
          '1,0',
          '1,1',
          '2,0',
          '2,1',
          '3,0',
          '3,1',
          '4,0',
          '4,1',
        ],
      );
    });
  });

  _registerTurnAutoExploreContinuationCharacterizationTests();
}

const _playerId = 'player_1';

GameUnit _autoExploringScout({
  String id = 'turn_auto_scout',
  int col = 0,
  int row = 0,
  required int movementPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.scout,
    name: 'Turn auto scout',
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: UnitPosture.autoExploring,
  );
}

TurnAutoExploreAdvance _advance({
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  required MapTraversalView mapData,
  List<GameCity> cities = const [],
}) {
  return TurnAutoExploreAdvancer.advance(
    units: units,
    fogOfWar: fogOfWar,
    cities: cities,
    playerIds: const {_playerId},
    mapData: mapData,
    fogOfWarService: const FogOfWarService(),
  );
}

FogOfWarState _originOnlyFog() => _fog(
  discovered: {const HexCoordinate(col: 0, row: 0)},
  visible: {const HexCoordinate(col: 0, row: 0)},
);

FogOfWarState _fog({
  required Set<HexCoordinate> discovered,
  required Set<HexCoordinate> visible,
}) {
  return FogOfWarState(
    players: {
      _playerId: PlayerFogOfWar(
        playerId: _playerId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

Set<HexCoordinate> _lineHexes(int count) => {
  for (var col = 0; col < count; col++) HexCoordinate(col: col, row: 0),
};

MapData _map({
  required int cols,
  int rows = 1,
  Map<int, List<TerrainType>> terrainOverrides = const {},
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: terrainOverrides[col] ?? const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

String _autoExploreTurnUnitSnapshot(GameUnit unit) {
  final path = unit.queuedPath;
  final target = path == null ? '-' : '${path.targetCol},${path.targetRow}';
  final steps = path == null
      ? '-'
      : path.steps.map((step) => '${step.col},${step.row}').join('|');
  return '${unit.id}:${unit.col},${unit.row};mp=${unit.movementPoints};'
      'target=$target;steps=$steps';
}

List<String> _sharedQueuedPathCoordinates(GameUnit first, GameUnit second) {
  final firstCoordinates = {
    for (final step in first.queuedPath!.steps) '${step.col},${step.row}',
  };
  return <String>[
    for (final step in second.queuedPath!.steps)
      if (firstCoordinates.contains('${step.col},${step.row}'))
        '${step.col},${step.row}',
  ]..sort();
}
