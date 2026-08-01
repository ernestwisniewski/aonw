import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const movementActorId = 'player_1';
const movementOpponentId = 'player_2';
const movementUnitId = 'mover';

typedef MovementStates = ({
  MovementCommandState kernel,
  CanonicalGameSnapshot engine,
  DomainState domain,
});

typedef MovementResults = ({
  MovementCommandResult kernel,
  GameEngineResult engine,
  DomainMoveUnitResult domain,
});

MovementStates movementStates({
  required GameUnit mover,
  List<GameUnit> additionalUnits = const [],
  List<GameCity> cities = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
}) {
  final units = [mover, ...additionalUnits];
  final diplomacy = DiplomacyState.empty.addContact(
    movementActorId,
    'sentinel',
  );
  final domain = DomainState.snapshot(
    turn: 7,
    matchRules: MatchRules.standard,
    participants: const [
      Player(
        id: movementActorId,
        name: 'One',
        colorValue: 0xFF112233,
        country: PlayerCountry.poland,
      ),
      Player(
        id: movementOpponentId,
        name: 'Two',
        colorValue: 0xFF445566,
        country: PlayerCountry.france,
      ),
    ],
    playerGold: const {movementActorId: 17, movementOpponentId: 23},
    units: units,
    cities: cities,
    fogOfWar: fogOfWar,
    diplomacy: diplomacy,
  );
  return (
    kernel: MovementCommandState(
      units: domain.units,
      cities: domain.cities,
      fogOfWar: domain.fogOfWar,
      diplomacy: domain.diplomacy,
      playerIds: const [movementActorId, movementOpponentId],
    ),
    engine: _engineSnapshot(domain),
    domain: domain,
  );
}

MovementResults resolveMovement(
  MovementStates states,
  MoveUnitCommand command,
  MapReadView map, {
  MovementCommandVisibilityMode visibilityMode =
      MovementCommandVisibilityMode.authoritative,
}) {
  return (
    kernel: const MovementCommandResolver().resolve(
      state: states.kernel,
      command: command,
      actorPlayerId: movementActorId,
      mapData: map,
      visibilityMode: visibilityMode,
    ),
    engine: const GameEngine().apply(
      snapshot: states.engine,
      command: command,
      context: GameEngineContext(
        actorPlayerId: movementActorId,
        mapView: map,
        ruleset: GameRuleset.defaults,
        commandTick: 1,
        movementVisibilityMode: visibilityMode,
      ),
    ),
    domain: const DomainMoveUnitResolver().resolve(
      state: states.domain,
      command: command,
      actorPlayerId: movementActorId,
      mapData: map,
      visibilityMode: visibilityMode,
    ),
  );
}

void expectAcceptedMovementParity(
  MovementStates before,
  MovementResults results,
) {
  expect(results.kernel.accepted, isTrue);
  expect(results.engine, isA<GameEngineAccepted>());
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.domain.reason, isNull);
  final engine = results.engine as GameEngineAccepted;
  expect(engine.snapshot.domain.units, results.kernel.units);
  expect(results.domain.state.units, results.kernel.units);
  expect(engine.snapshot.domain.fogOfWar, results.kernel.fogOfWar);
  expect(results.domain.state.fogOfWar, results.kernel.fogOfWar);
  expect(engine.snapshot.domain.diplomacy, results.kernel.diplomacy);
  expect(results.domain.state.diplomacy, results.kernel.diplomacy);
  expect(
    executionSnapshot(_engineExecution(engine)),
    executionSnapshot(results.kernel.execution),
  );
  expect(
    executionSnapshot(results.domain.execution),
    executionSnapshot(results.kernel.execution),
  );
  if (before.kernel.units.length > 1) {
    expect(results.kernel.units.last, same(before.kernel.units.last));
    expect(
      engine.snapshot.domain.units.last,
      same(before.engine.domain.units.last),
    );
    expect(results.domain.state.units.last, same(before.domain.units.last));
  }
  expect(
    engine.snapshot.domain.playerGold,
    same(before.engine.domain.playerGold),
  );
  expect(results.domain.state.playerGold, same(before.domain.playerGold));
}

void expectRejectedMovementIdentity(
  MovementStates states,
  MovementResults results, {
  required String reason,
}) {
  expect(results.kernel.accepted, isFalse);
  expect(results.engine, isA<GameEngineRejected>());
  expect(results.domain.accepted, isFalse);
  expect(results.kernel.reason, reason);
  expect((results.engine as GameEngineRejected).reason, reason);
  expect(results.domain.reason, reason);
  expect(results.kernel.units, same(states.kernel.units));
  expect(results.kernel.fogOfWar, same(states.kernel.fogOfWar));
  expect(results.kernel.diplomacy, same(states.kernel.diplomacy));
  expect(results.kernel.events, isEmpty);
  expect(results.kernel.execution, isNull);
  expect(results.engine.snapshot, same(states.engine));
  expect(results.domain.state, same(states.domain));
}

void expectAcceptedMovementIdentity(
  MovementStates states,
  MovementResults results,
) {
  expect(results.kernel.accepted, isTrue);
  expect(results.engine, isA<GameEngineAccepted>());
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.kernel.units, same(states.kernel.units));
  expect(results.kernel.fogOfWar, same(states.kernel.fogOfWar));
  expect(results.kernel.diplomacy, same(states.kernel.diplomacy));
  expect(results.kernel.events, isEmpty);
  expect(results.kernel.execution, isNull);
  expect(results.engine.snapshot, same(states.engine));
  expect(results.domain.state, same(states.domain));
}

MovementCommandExecution? _engineExecution(GameEngineAccepted result) {
  final executions = result.movementDelta.executions;
  return executions.isEmpty ? null : executions.single;
}

CanonicalGameSnapshot _engineSnapshot(DomainState domain) {
  return CanonicalGameSnapshot.snapshot(
    domain: (domain).copyWith(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        movementActorId: PlayerTurnState.active,
        movementOpponentId: PlayerTurnState.active,
      },
    ),

    metadata: GameSnapshotMetadata(
      id: 'movement_parity',
      schemaVersion: 3,
      name: 'Movement parity',
      world: const WorldReference(name: 'test', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

void expectMoveEvent(
  List<GameEvent> events, {
  required int fromCol,
  required int toCol,
}) {
  expect(events, hasLength(1));
  expect(events.single, isA<UnitMovedEvent>());
  final event = events.single as UnitMovedEvent;
  expect(
    (event.unitId, event.fromCol, event.fromRow, event.toCol, event.toRow),
    (movementUnitId, fromCol, 0, toCol, 0),
  );
}

Object? executionSnapshot(MovementCommandExecution? execution) {
  if (execution == null) return null;
  final path = stepCoordinates(
    execution.steps,
  ).map((step) => '${step.$1}:${step.$2}').join('|');
  return '${execution.unitId}@${execution.fromCol}:${execution.fromRow}->$path';
}

List<(int, int)> stepCoordinates(Iterable<UnitMovementStep> steps) => [
  for (final step in steps) (step.col, step.row),
];

GameUnit movementUnit({
  String id = movementUnitId,
  String ownerPlayerId = movementActorId,
  int col = 0,
  int movementPoints = 5,
  UnitPosture posture = UnitPosture.active,
  GameUnitType type = GameUnitType.commander,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: id,
    col: col,
    row: 0,
    movementPoints: movementPoints,
    posture: posture,
  );
}

FogOfWarState movementFog({required int visibleCols, int? discoveredCols}) {
  final visible = {
    for (var col = 0; col < visibleCols; col++) HexCoordinate(col: col, row: 0),
  };
  final discovered = {
    for (var col = 0; col < (discoveredCols ?? visibleCols); col++)
      HexCoordinate(col: col, row: 0),
  };
  return FogOfWarState(
    players: {
      movementActorId: PlayerFogOfWar(
        playerId: movementActorId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

MapReadView movementMap({
  required int cols,
  int rows = 1,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
