import 'package:aonw_core/domain.dart';

import 'measurement.dart';

const movementCommandScales = [100, 1000, 10000];
const _movementActorId = 'movement_benchmark_actor';
const _movementOpponentId = 'movement_benchmark_opponent';
const _movementUnitId = 'movement_benchmark_unit';
const _movementStart = (col: 4, row: 4);
const _movementTarget = (col: 7, row: 4);

/// Resolves one authoritative move through the neutral kernel and both state
/// adapters while exercising fog recomputation and diplomatic contact.
PerformanceCaseResult runMovementCommandWorkload({
  Iterable<int> scales = movementCommandScales,
  int timingSamples = 21,
}) {
  if (timingSamples <= 0) {
    throw ArgumentError.value(
      timingSamples,
      'timingSamples',
      'Must be positive.',
    );
  }
  final stable = <String, Object?>{};
  final observations = <String, Object?>{};
  for (final scale in scales) {
    final result = _runMovementCommandScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }
  return PerformanceCaseResult(
    'map.movement-command',
    {'sizes': stable},
    {'sizes': observations},
  );
}

_MovementCommandScaleResult _runMovementCommandScale(
  int scale,
  int timingSamples,
) {
  final fixture = _MovementCommandFixture.forScale(scale);
  final countedTraversal = _CountingMovementTraversal(fixture.mapView());
  final counted = _executeMovementCommandBatch(fixture, countedTraversal);
  _executeMovementCommandBatch(fixture, fixture.mapView());

  final samples = <Duration>[];
  for (var run = 0; run < timingSamples; run++) {
    final measured = measureSync(
      () => _executeMovementCommandBatch(fixture, fixture.mapView()),
    );
    samples.add(measured.elapsed);
    _verifyMovementCommandOutput(counted, measured.value);
  }

  return _MovementCommandScaleResult(
    stable: {
      'scale': scale,
      'dimensions': {
        'cols': fixture.worldMap.cols,
        'rows': fixture.worldMap.rows,
      },
      'indexedTiles': fixture.worldMap.indexedTileCount,
      'boundaryCount': counted.outputs.length,
      'acceptedBoundaries': counted.acceptedBoundaries,
      'eventCount': counted.eventCount,
      'executedSteps': counted.executedSteps,
      'diplomaticContacts': counted.diplomaticContacts,
      'fogFullRecomputes': counted.counters.fullRecomputeCount,
      'fogPlayerRecomputes': counted.counters.playerRecomputeCount,
      'fogIncrementalRecomputes': counted.counters.unitMoveIncrementalCount,
      'fogFallbackRecomputes': counted.counters.unitMoveFallbackCount,
      ...countedTraversal.snapshot,
      'outputDigest': stableDigest(counted.outputs),
    },
    observations: {'movementCommandTiming': timingObservation(samples)},
  );
}

_MovementCommandBatch _executeMovementCommandBatch(
  _MovementCommandFixture fixture,
  MapTraversalView mapView,
) {
  final counters = FogOfWarRecomputeCounters();
  final fogService = FogOfWarService(counters: counters);
  final kernel = MovementCommandResolver(fogOfWarService: fogService).resolve(
    state: fixture.kernelState,
    command: fixture.command,
    actorPlayerId: _movementActorId,
    mapData: mapView,
  );
  final persistent = PersistentMoveUnitResolver(fogOfWarService: fogService)
      .resolve(
        state: fixture.persistentState,
        command: fixture.command,
        actorPlayerId: _movementActorId,
        mapData: mapView,
      );
  final domain =
      DomainMoveUnitResolver(
        commandResolver: MovementCommandResolver(fogOfWarService: fogService),
      ).resolve(
        state: fixture.domainState,
        command: fixture.command,
        actorPlayerId: _movementActorId,
        mapData: mapView,
      );

  return _MovementCommandBatch(
    outputs: [
      _normalizedMovementBoundary(
        accepted: kernel.accepted,
        reason: kernel.reason,
        units: kernel.units,
        fogOfWar: kernel.fogOfWar,
        diplomacy: kernel.diplomacy,
        events: kernel.events,
        execution: kernel.execution,
      ),
      _normalizedMovementBoundary(
        accepted: persistent.accepted,
        reason: persistent.reason,
        units: persistent.state.units,
        fogOfWar: persistent.state.fogOfWar,
        diplomacy: persistent.state.runtimeState.diplomacy,
        events: persistent.events,
        execution: persistent.execution,
      ),
      _normalizedMovementBoundary(
        accepted: domain.accepted,
        reason: domain.reason,
        units: domain.state.units,
        fogOfWar: domain.state.fogOfWar,
        diplomacy: domain.state.diplomacy,
        events: domain.events,
        execution: domain.execution,
      ),
    ],
    counters: counters,
  );
}

Map<String, Object?> _normalizedMovementBoundary({
  required bool accepted,
  required String? reason,
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  required DiplomacyState diplomacy,
  required List<GameEvent> events,
  required MovementCommandExecution? execution,
}) {
  final moved = units.firstWhere((unit) => unit.id == _movementUnitId);
  return {
    'accepted': accepted,
    'reason': reason,
    'unit': {
      'col': moved.col,
      'row': moved.row,
      'movementPoints': moved.movementPoints,
      'queuedTarget': moved.queuedPath == null
          ? null
          : '${moved.queuedPath!.targetCol}:${moved.queuedPath!.targetRow}',
    },
    'visibleHexes': fogOfWar.fogForPlayer(_movementActorId).visibleHexes.length,
    'hasOpponentContact': diplomacy.hasContact(
      _movementActorId,
      _movementOpponentId,
    ),
    'events': [for (final event in events) _normalizedMovementEvent(event)],
    'execution': execution == null
        ? null
        : {
            'unitId': execution.unitId,
            'from': '${execution.fromCol}:${execution.fromRow}',
            'steps': [
              for (final step in execution.steps)
                '${step.col}:${step.row}:${step.cumulativeCost}',
            ],
          },
  };
}

Object _normalizedMovementEvent(GameEvent event) => switch (event) {
  UnitMovedEvent() => {
    'type': 'unitMoved',
    'unitId': event.unitId,
    'from': '${event.fromCol}:${event.fromRow}',
    'to': '${event.toCol}:${event.toRow}',
  },
  _ => event.runtimeType.toString(),
};

void _verifyMovementCommandOutput(
  _MovementCommandBatch expected,
  _MovementCommandBatch actual,
) {
  if (stableDigest(expected.outputs) != stableDigest(actual.outputs) ||
      expected.counterSnapshot != actual.counterSnapshot) {
    throw StateError('Movement command workload produced unstable output.');
  }
}

final class _MovementCommandFixture {
  const _MovementCommandFixture({
    required this.worldMap,
    required this.kernelState,
    required this.persistentState,
    required this.domainState,
    required this.command,
  });

  factory _MovementCommandFixture.forScale(int scale) {
    final dimensions = _movementCommandDimensions(scale);
    final worldMap = WorldMap(
      cols: dimensions.cols,
      rows: dimensions.rows,
      tiles: [
        for (var index = 0; index < scale; index++)
          WorldTile(
            coordinate: HexCoord(
              col: index % dimensions.cols,
              row: index ~/ dimensions.cols,
            ),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
      ],
    );
    final units = <GameUnit>[
      GameUnit(
        id: _movementUnitId,
        ownerPlayerId: _movementActorId,
        type: GameUnitType.commander,
        name: 'Benchmark mover',
        col: _movementStart.col,
        row: _movementStart.row,
        movementPoints: 5,
      ),
      GameUnit(
        id: 'movement_benchmark_observer',
        ownerPlayerId: _movementOpponentId,
        type: GameUnitType.commander,
        name: 'Benchmark opponent',
        col: 8,
        row: 4,
        movementPoints: 5,
      ),
    ];
    const fogOfWar = FogOfWarState.empty;
    const diplomacy = DiplomacyState.empty;
    final persistent = PersistentGameState.snapshot(
      playerColors: const {
        _movementActorId: 0xFF112233,
        _movementOpponentId: 0xFF445566,
      },
      playerCountries: const {
        _movementActorId: PlayerCountry.poland,
        _movementOpponentId: PlayerCountry.france,
      },
      playerGold: const {_movementActorId: 10, _movementOpponentId: 10},
      units: units,
      fogOfWar: fogOfWar,
      runtimeState: GameRuntimeState.snapshot(diplomacy: diplomacy),
    );
    final domain = DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _movementActorId,
          name: 'Benchmark actor',
          colorValue: 0xFF112233,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _movementOpponentId,
          name: 'Benchmark opponent',
          colorValue: 0xFF445566,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_movementActorId: 10, _movementOpponentId: 10},
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
    );
    return _MovementCommandFixture(
      worldMap: worldMap,
      kernelState: MovementCommandState(
        units: units,
        cities: const [],
        fogOfWar: fogOfWar,
        diplomacy: diplomacy,
        playerIds: const [_movementActorId, _movementOpponentId],
      ),
      persistentState: persistent,
      domainState: domain,
      command: MoveUnitCommand(
        _movementUnitId,
        _movementTarget.col,
        _movementTarget.row,
      ),
    );
  }

  final WorldMap worldMap;
  final MovementCommandState kernelState;
  final PersistentGameState persistentState;
  final DomainState domainState;
  final MoveUnitCommand command;

  MapTraversalView mapView() => WorldMapReadView(worldMap);
}

final class _MovementCommandBatch {
  const _MovementCommandBatch({required this.outputs, required this.counters});

  final List<Map<String, Object?>> outputs;
  final FogOfWarRecomputeCounters counters;

  int get acceptedBoundaries =>
      outputs.where((output) => output['accepted'] == true).length;
  int get eventCount => outputs.fold(
    0,
    (count, output) => count + (output['events']! as List<Object?>).length,
  );
  int get executedSteps => outputs.fold(0, (count, output) {
    final execution = output['execution'] as Map<String, Object?>?;
    return count + (execution?['steps'] as List<Object?>?)!.length;
  });
  int get diplomaticContacts =>
      outputs.where((output) => output['hasOpponentContact'] == true).length;

  String get counterSnapshot =>
      '${counters.fullRecomputeCount}:${counters.playerRecomputeCount}:'
      '${counters.unitMoveIncrementalCount}:${counters.unitMoveFallbackCount}';
}

final class _CountingMovementTraversal implements MapTraversalView {
  _CountingMovementTraversal(this._delegate);

  final MapTraversalView _delegate;
  final Set<String> _coordinates = {};
  int _calls = 0;
  int _hits = 0;

  @override
  int get cols => _delegate.cols;

  @override
  int get rows => _delegate.rows;

  @override
  MapTileView? tileAt(int col, int row) {
    _calls++;
    _coordinates.add('$col:$row');
    final tile = _delegate.tileAt(col, row);
    if (tile != null) _hits++;
    return tile;
  }

  Map<String, int> get snapshot => {
    'tileLookupCalls': _calls,
    'tileLookupHits': _hits,
    'uniqueTileLookupCoordinates': _coordinates.length,
  };
}

({int cols, int rows}) _movementCommandDimensions(int scale) => switch (scale) {
  100 => (cols: 10, rows: 10),
  1000 => (cols: 25, rows: 40),
  10000 => (cols: 100, rows: 100),
  _ => throw ArgumentError.value(
    scale,
    'scale',
    'Supported scales are 100, 1000, and 10000.',
  ),
};

final class _MovementCommandScaleResult {
  const _MovementCommandScaleResult({
    required this.stable,
    required this.observations,
  });

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;
}
