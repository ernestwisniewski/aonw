import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
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
  const adapter = LegacyGameSnapshotAdapter();
  final canonicalInput = adapter.toCanonical(
    save: fixture.save,
    state: fixture.state,
    eventLogOffset: fixture.eventLogOffset,
  );
  final canonicalResult = CanonicalTurnPipeline.simultaneousFinalize(
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: canonicalInput,
      playerIds: _players.map((player) => player.id),
      savedAt: _savedAt,
      mapView: fixture.mapView,
    ),
  );
  return _BoundaryResult(
    legacy: adapter.toLegacy(canonicalResult.snapshot),
    events: canonicalResult.events,
    movementDelta: canonicalResult.movementDelta,
  );
}

Map<String, Object?> _stableResult(
  _TurnFinalizationFixture fixture,
  _BoundaryResult result,
) {
  final outputEntities = _entityCount(result.legacy.state);
  if (outputEntities != fixture.entityCount ||
      result.legacy.eventLogOffset != fixture.eventLogOffset ||
      result.legacy.save.turn != fixture.save.turn + 1) {
    throw StateError(
      'Turn finalization did not preserve the bounded fixture at '
      '${fixture.entityCount} entities.',
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
    'offsetPreserved': result.legacy.eventLogOffset == fixture.eventLogOffset,
    'outputArtifacts': result.legacy.state.artifacts.length,
    'outputDigest': stableDigest({
      'save': result.legacy.save.toJson(),
      'state': result.legacy.state.toJson(),
      'eventLogOffset': result.legacy.eventLogOffset,
      'events': eventJson,
    }),
    'outputEntities': outputEntities,
    'outputOffset': result.legacy.eventLogOffset,
    'outputTurn': result.legacy.save.turn,
    'outputUnits': result.legacy.state.units.length,
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

int _entityCount(PersistentGameState state) {
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
          'player_2': PlayerTurnState.finished,
        },
        savedAt: DateTime.utc(2026, 7, 17, 11),
        camera: CameraState.zero,
        players: _players,
        gameMode: GameMode.multiplayer,
      ),
      state: PersistentGameState.snapshot(
        playerColors: const {'player_1': 0xFF3D5FA8, 'player_2': 0xFFB83A3A},
        playerCountries: const {
          'player_1': PlayerCountry.poland,
          'player_2': PlayerCountry.germany,
        },
        playerGold: const {'player_1': 100, 'player_2': 100},
        units: units,
        artifacts: artifacts,
        runtimeState: GameRuntimeState.snapshot(
          submittedPlayerIds: const {'player_1', 'player_2'},
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
      ),
      mapView: _mapView(),
    );
  }

  final int entityCount;
  final int eventLogOffset;
  final GameSave save;
  final PersistentGameState state;
  final MapReadView mapView;
}

final class _BoundaryResult {
  const _BoundaryResult({
    required this.legacy,
    required this.events,
    required this.movementDelta,
  });

  final LegacyGameSnapshotParts legacy;
  final List<GameEvent> events;
  final TurnMovementDelta movementDelta;
}

MapReadView _mapView() => MapData(
  cols: 2,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
).indexedReadView();
