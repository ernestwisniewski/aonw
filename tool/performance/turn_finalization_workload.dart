import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

import 'measurement.dart';

const turnFinalizationWorkloadScales = [100, 1000, 10000];
const _players = [
  Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF3D5FA8),
  Player(id: 'player_2', name: 'Player 2', colorValue: 0xFFB83A3A),
];
final _savedAt = DateTime.utc(2026, 7, 17, 12);

PerformanceCaseResult runTurnFinalizationWorkload({
  Iterable<int> entityCounts = turnFinalizationWorkloadScales,
  int timingSamples = 21,
}) {
  final counts = entityCounts.toList(growable: false);
  _validateInputs(counts, timingSamples);
  final stableBySize = <String, Object?>{};
  final observationsBySize = <String, Object?>{};
  for (final entityCount in counts) {
    final fixture = _TurnFinalizationFixture.create(entityCount);
    _executeBoundaryRoundTrip(fixture);
    final measurements = [
      for (var sample = 0; sample < timingSamples; sample++)
        measureSync(() => _executeBoundaryRoundTrip(fixture)),
    ];
    final stableSamples = [
      for (final measurement in measurements)
        _stableResult(fixture, measurement.value),
    ];
    _requireStableSamples(stableSamples, entityCount);
    stableBySize['$entityCount'] = stableSamples.first;
    observationsBySize['$entityCount'] = {
      'boundaryRoundTrip': timingObservation([
        for (final measurement in measurements) measurement.elapsed,
      ]),
    };
  }

  return PerformanceCaseResult(
    'turn.finalization',
    {'entityCounts': counts, 'sizes': stableBySize},
    {
      'portableTimingGate': false,
      'samplesPerCase': timingSamples,
      'sizes': observationsBySize,
    },
  );
}

void _validateInputs(List<int> entityCounts, int timingSamples) {
  if (entityCounts.isEmpty || entityCounts.any((count) => count < 2)) {
    throw ArgumentError.value(
      entityCounts,
      'entityCounts',
      'Must contain values of at least two for the combat fixture.',
    );
  }
  if (entityCounts.toSet().length != entityCounts.length) {
    throw ArgumentError.value(entityCounts, 'entityCounts', 'Must be unique.');
  }
  if (timingSamples < 1) {
    throw ArgumentError.value(
      timingSamples,
      'timingSamples',
      'Must be positive.',
    );
  }
}

_BoundaryResult _executeBoundaryRoundTrip(_TurnFinalizationFixture fixture) {
  final save = fixture.save;
  final canonicalInput = CanonicalGameSnapshot.snapshot(
    domain: fixture.state
        .withMatchRules(save.matchRules)
        .copyWith(
          turn: save.turn,
          participants: save.players,
          gameMode: save.gameMode,
          turnStatesByPlayerId: save.playerStates,
        ),
    metadata: GameSnapshotMetadata(
      id: save.id,
      schemaVersion: save.schemaVersion,
      name: save.name,
      world: WorldReference(name: save.mapName, source: save.mapSource),
      savedAtUtc: save.savedAt,
      camera: GameSnapshotCamera(
        x: save.camera.x,
        y: save.camera.y,
        zoom: save.camera.zoom,
      ),
    ),
    eventLogOffset: fixture.eventLogOffset,
  );
  final playerIds = _players.map((player) => player.id).toList();
  final canonicalResult = const GameEngine().apply(
    snapshot: canonicalInput,
    command: SubmitTurnCommand(playerIds.last),
    context: GameEngineContext(
      actorPlayerId: playerIds.last,
      mapView: fixture.mapView,
      ruleset: GameRuleset.defaults,
      commandTick: 0,
      turnPlayerIds: playerIds,
      requiredTurnSubmissionPlayerIds: playerIds,
      savedAt: _savedAt,
    ),
  );
  return _BoundaryResult(
    snapshot: canonicalResult.snapshot,
    events: canonicalResult.events,
    movementDelta: canonicalResult.movementDelta,
  );
}

Map<String, Object?> _stableResult(
  _TurnFinalizationFixture fixture,
  _BoundaryResult result,
) {
  final output = result.snapshot;
  final outputEntities = _entityCount(output.domain);
  if (outputEntities != fixture.entityCount ||
      output.eventLogOffset != fixture.eventLogOffset ||
      output.domain.turn != fixture.save.turn + 1) {
    throw StateError(
      'Turn finalization did not preserve the bounded fixture at '
      '${fixture.entityCount} entities: outputEntities=$outputEntities, '
      'offset=${output.eventLogOffset}/'
      '${fixture.eventLogOffset}, turn=${output.domain.turn}/'
      '${fixture.save.turn + 1}.',
    );
  }
  final eventJson = [
    for (final event in result.events) GameEventSerializer.toJson(event),
  ];
  final combatResolvedEvents = result.events
      .whereType<CombatResolvedEvent>()
      .toList(growable: false);
  if (combatResolvedEvents.length != 1) {
    throw StateError(
      'Turn finalization did not resolve exactly one combat event at '
      '${fixture.entityCount} entities.',
    );
  }
  final combat = combatResolvedEvents.single;
  final movementDelta = result.movementDelta;
  return {
    'combatAttackerKilled': combat.outcome.attackerKilled,
    'combatAttackerUnitId': combat.attackerUnitId,
    'combatDefenderKilled': combat.outcome.defenderKilled,
    'combatDefenderUnitId': combat.defenderUnitId,
    'combatResolvedEvents': combatResolvedEvents.length,
    'eventCount': result.events.length,
    'inputArtifacts': fixture.state.artifacts.length,
    'inputEntities': fixture.entityCount,
    'inputOffset': fixture.eventLogOffset,
    'inputTurn': fixture.save.turn,
    'inputUnits': fixture.state.units.length,
    'movementAfterUnits': movementDelta.afterUnits.length,
    'movementBeforeUnits': movementDelta.beforeUnits.length,
    'offsetPreserved': output.eventLogOffset == fixture.eventLogOffset,
    'outputArtifacts': output.domain.artifacts.length,
    'outputDigest': stableDigest({
      'metadata': {
        'id': output.metadata.id,
        'schemaVersion': output.metadata.schemaVersion,
        'name': output.metadata.name,
        'world': output.metadata.world.name,
        'worldSource': output.metadata.world.source.name,
        'savedAtUtc': output.metadata.savedAtUtc.toIso8601String(),
      },
      'domain': CanonicalGameSnapshotCodec.encodeDomainState(output.domain),
      'eventLogOffset': output.eventLogOffset,
      'events': eventJson,
    }),
    'outputEntities': outputEntities,
    'outputOffset': output.eventLogOffset,
    'outputTurn': output.domain.turn,
    'outputUnits': output.domain.units.length,
  };
}

void _requireStableSamples(
  List<Map<String, Object?>> samples,
  int entityCount,
) {
  final expected = stableDigest(samples.first);
  if (samples.any((sample) => stableDigest(sample) != expected)) {
    throw StateError(
      'Turn finalization workload is not deterministic at $entityCount '
      'entities.',
    );
  }
}

int _entityCount(DomainState state) {
  return state.units.length +
      state.cities.length +
      state.artifacts.length +
      state.fieldImprovements.length;
}

final class _TurnFinalizationFixture {
  const _TurnFinalizationFixture({
    required this.entityCount,
    required this.eventLogOffset,
    required this.save,
    required this.state,
    required this.mapView,
  });

  factory _TurnFinalizationFixture.create(int entityCount) {
    final unitCount = entityCount < _players.length
        ? entityCount
        : _players.length;
    final units = [
      for (var index = 0; index < unitCount; index++)
        GameUnit.produced(
          id: 'unit_$index',
          ownerPlayerId: _players[index].id,
          type: GameUnitType.warrior,
          col: index,
          row: 0,
        ),
    ];
    final artifacts = [
      for (var index = 0; index < entityCount - unitCount; index++)
        WorldArtifact(
          id: 'artifact_$index',
          type:
              WorldArtifactType.values[index % WorldArtifactType.values.length],
          location: WorldArtifactLocation.map(col: index % 2, row: 0),
        ),
    ];
    return _TurnFinalizationFixture(
      entityCount: entityCount,
      eventLogOffset: entityCount * 2 + 7,
      save: GameSave(
        id: 'turn_finalization_$entityCount',
        name: 'Turn finalization $entityCount',
        mapName: 'synthetic',
        mapSource: MapSource.saved,
        turn: 7,
        playerStates: const {
          'player_1': PlayerTurnState.finished,
          'player_2': PlayerTurnState.active,
        },
        savedAt: DateTime.utc(2026, 7, 17, 11),
        camera: CameraState.zero,
        players: _players,
        gameMode: GameMode.multiplayer,
      ),
      state: DomainState.snapshot(
        playerColors: const {'player_1': 0xFF3D5FA8, 'player_2': 0xFFB83A3A},
        playerCountries: const {
          'player_1': PlayerCountry.poland,
          'player_2': PlayerCountry.germany,
        },
        playerGold: const {'player_1': 100, 'player_2': 100},
        units: units,
        artifacts: artifacts,

        submittedPlayerIds: const {'player_1'},
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'unit_0',
            defenderCol: 1,
            defenderRow: 0,
            declaredAtTick: 1,
            declaringPlayerId: 'player_1',
          ),
        ],
        turnStartedAt: DateTime.utc(2026, 7, 17, 11),
      ),
      mapView: _mapView(),
    );
  }

  final int entityCount;
  final int eventLogOffset;
  final GameSave save;
  final DomainState state;
  final MapReadView mapView;
}

final class _BoundaryResult {
  const _BoundaryResult({
    required this.snapshot,
    required this.events,
    required this.movementDelta,
  });

  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final MovementExecutionDelta movementDelta;
}

MapReadView _mapView() => WorldMap(
  cols: 2,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    WorldTile(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
