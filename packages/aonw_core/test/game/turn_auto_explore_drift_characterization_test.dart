import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:test/test.dart';

part 'support/turn_auto_explore_continuation_characterization.dart';

void main() {
  group('turn auto-explore drift characterization', () {
    test('continuation stops before a known foreign city at peace and war', () {
      final scout = _autoExploringScout(movementPoints: 1);
      const foreignCity = GameCity(
        id: 'foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final fog = _fog(discovered: _lineHexes(2), visible: _lineHexes(2));
      final map = _map(cols: 3);
      final peace = _advance(
        units: [scout],
        cities: const [foreignCity],
        fogOfWar: fog,
        mapData: map,
      );
      final warDiplomacy = _warDiplomacy();
      final war = _advance(
        units: [scout],
        cities: const [foreignCity],
        fogOfWar: fog,
        diplomacy: warDiplomacy,
        mapData: map,
      );

      const stoppedScout = 'turn_auto_scout:0,0;mp=1;target=-;steps=-';
      expect(peace.changed, isTrue);
      expect(peace.units.map(_autoExploreTurnUnitSnapshot), [stoppedScout]);
      expect(peace.units.single.posture, UnitPosture.active);
      expect(peace.fogOfWar, same(fog));
      expect(peace.diplomacy, DiplomacyState.empty);
      expect(peace.interaction, DomainActionState.empty);
      expect(peace.events, isEmpty);
      expect(peace.executions, isEmpty);

      expect(war.changed, isTrue);
      expect(war.units.map(_autoExploreTurnUnitSnapshot), [stoppedScout]);
      expect(war.units.single.posture, UnitPosture.active);
      expect(war.fogOfWar, same(fog));
      expect(war.diplomacy, warDiplomacy);
      expect(war.interaction, DomainActionState.empty);
      expect(war.events, isEmpty);
      expect(war.executions, isEmpty);
    });

    test('finishes when only terrain beyond per-turn capacity remains', () {
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

      final pair = _runTurnAndKernel(
        units: [scout],
        fogOfWar: _originOnlyFog(),
        mapData: map,
      );
      expect(pair.turn.changed, isTrue);
      expect(pair.turn.units.single.posture, UnitPosture.active);
      expect(pair.turn.units.single.movementPoints, 2);
      expect(pair.turn.fogOfWar, same(pair.kernelInput.fogOfWar));
      expect(pair.turn.diplomacy, same(pair.kernelInput.diplomacy));
      expect(pair.turn.interaction, same(DomainActionState.empty));
      expect(pair.turn.events, isEmpty);
      expect(pair.turn.executions, isEmpty);
      expect(pair.kernel.accepted, isTrue);
      expect(pair.kernel.reason, isNull);
      expect(pair.kernel.state.units, pair.turn.units);
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
      final fullState = _runTurnAndKernel(
        units: [scout, blocker],
        fogOfWar: _originOnlyFog(),
        mapData: map,
      );

      expect(projected.units.first.col, 2);
      expect(fullState.turn.units.first.col, 1);
      expect(fullState.turn.units.last, same(blocker));
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

    test('no target finishes continuation like the resolver', () {
      final scout = _autoExploringScout(movementPoints: 2);
      final inputFog = _originOnlyFog();

      final pair = _runTurnAndKernel(
        units: [scout],
        fogOfWar: inputFog,
        mapData: _map(cols: 1),
      );

      expect(pair.turn.changed, isTrue);
      expect(pair.turn.units.single.posture, UnitPosture.active);
      expect(pair.turn.fogOfWar, same(inputFog));
      expect(
        pair.turn.units.map(_autoExploreTurnUnitSnapshot),
        pair.kernel.state.units.map(_autoExploreTurnUnitSnapshot),
      );
      expect(pair.turn.events, pair.kernel.events);
      expect(pair.turn.executions, isEmpty);
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
          interaction: DomainActionState.empty,
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
        'second_scout:2,1;mp=0;target=5,0;steps=0,1|1,0|2,1|3,1|4,1|5,0',
      ]);
      expect(
        _sharedQueuedPathCoordinates(result.units[0], result.units[1]),
        const ['1,0'],
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
  DiplomacyState diplomacy = DiplomacyState.empty,
  DomainActionState interaction = DomainActionState.empty,
}) {
  return TurnAutoExploreAdvancer.advance(
    units: units,
    fogOfWar: fogOfWar,
    diplomacy: diplomacy,
    interaction: interaction,
    cities: cities,
    playerIds: const {_playerId},
    phaseKnownPlayerIds: const {_playerId, 'player_2'},
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

WorldMap _map({
  required int cols,
  int rows = 1,
  Map<int, List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile(
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
