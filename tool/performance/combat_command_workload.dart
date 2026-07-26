import 'package:aonw_core/domain.dart';

import 'measurement.dart';

part 'combat_command_workload_fixture.dart';

const combatCommandScales = [100, 1000, 10000];
const _combatActorId = 'combat_benchmark_actor';
const _combatOpponentId = 'combat_benchmark_opponent';
const _combatAttackerId = 'combat_benchmark_attacker';
const _combatDefenderId = 'combat_benchmark_defender';
const _combatTurn = 7;
const _combatCommandTick = 13;
const _combatCommand = AttackHexCommand(_combatAttackerId, 2, 2);
final _combatRuleset = GameRuleset.defaults.copyWith(
  combat: const CombatRuleset(varianceRange: 0, retreatThresholdPercent: 0),
);

/// Resolves one deterministic instant combat through the neutral kernel and
/// both state-boundary adapters while unrelated entities increase by scale.
PerformanceCaseResult runCombatCommandWorkload({
  Iterable<int> scales = combatCommandScales,
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
    final result = _runCombatCommandScale(scale, timingSamples);
    stable['$scale'] = result.stable;
    observations['$scale'] = result.observations;
  }
  return PerformanceCaseResult(
    'map.combat-command',
    {'sizes': stable},
    {'samplesPerBoundary': timingSamples, 'sizes': observations},
  );
}

_CombatCommandScaleResult _runCombatCommandScale(int scale, int timingSamples) {
  final fixture = _CombatCommandFixture.forScale(scale);
  final counted = _executeCountedBoundaries(fixture);

  _executeKernelBoundary(fixture, fixture.mapTiles);
  _executePersistentBoundary(fixture, fixture.mapTiles);
  _executeDomainBoundary(fixture, fixture.mapTiles);

  final kernelSamples = <Duration>[];
  final persistentSamples = <Duration>[];
  final domainSamples = <Duration>[];
  for (var run = 0; run < timingSamples; run++) {
    final kernel = measureSync(
      () => _executeKernelBoundary(fixture, fixture.mapTiles),
    );
    final persistent = measureSync(
      () => _executePersistentBoundary(fixture, fixture.mapTiles),
    );
    final domain = measureSync(
      () => _executeDomainBoundary(fixture, fixture.mapTiles),
    );
    kernelSamples.add(kernel.elapsed);
    persistentSamples.add(persistent.elapsed);
    domainSamples.add(domain.elapsed);
    _verifyBoundaryOutput(counted.kernel.output, kernel.value);
    _verifyBoundaryOutput(counted.persistent.output, persistent.value);
    _verifyBoundaryOutput(counted.domain.output, domain.value);
  }

  final outputs = counted.outputs;
  final outputDigests = {
    for (final entry in outputs.entries)
      entry.key: stableDigest(entry.value.output),
  };
  final eventPayloads = [
    for (final boundary in outputs.values) boundary.output['events'],
  ];
  final outcomePayloads = [
    for (final boundary in outputs.values) boundary.output['outcomes'],
  ];
  final contactPayloads = [
    for (final boundary in outputs.values)
      boundary.output['hasOpponentContact'],
  ];
  return _CombatCommandScaleResult(
    stable: {
      'scale': scale,
      'inputEntities': fixture.entityCount,
      'inputArtifacts': fixture.artifacts.length,
      'boundaryCount': outputs.length,
      'acceptedBoundaries': outputs.values
          .where((boundary) => boundary.output['accepted'] == true)
          .length,
      'eventCount': outputs.values.fold<int>(
        0,
        (count, boundary) =>
            count + (boundary.output['events']! as List<Object?>).length,
      ),
      'combatResolvedEvents': outputs.values.fold<int>(
        0,
        (count, boundary) =>
            count + (boundary.output['outcomes']! as List<Object?>).length,
      ),
      'diplomaticContacts': contactPayloads
          .where((value) => value == true)
          .length,
      'fogFullRecomputesByBoundary': {
        for (final entry in outputs.entries)
          entry.key: entry.value.fogCounters.fullRecomputeCount,
      },
      'fogPlayerRecomputesByBoundary': {
        for (final entry in outputs.entries)
          entry.key: entry.value.fogCounters.playerRecomputeCount,
      },
      'tileLookupCallsByBoundary': counted.tileLookupCalls,
      'tileLookupHitsByBoundary': counted.tileLookupHits,
      'boundaryOutputDigests': outputDigests,
      'eventDigest': stableDigest(eventPayloads),
      'outcomeDigest': stableDigest(outcomePayloads),
      'contactDigest': stableDigest(contactPayloads),
      'outputDigest': stableDigest({
        for (final entry in outputs.entries) entry.key: entry.value.output,
      }),
    },
    observations: {
      'kernelTiming': timingObservation(kernelSamples),
      'persistentAdapterTiming': timingObservation(persistentSamples),
      'domainAdapterTiming': timingObservation(domainSamples),
    },
  );
}

_CountedCombatBoundaries _executeCountedBoundaries(
  _CombatCommandFixture fixture,
) {
  final kernelMap = _CountingCombatMapTiles(fixture.mapTiles);
  final persistentMap = _CountingCombatMapTiles(fixture.mapTiles);
  final domainMap = _CountingCombatMapTiles(fixture.mapTiles);
  return _CountedCombatBoundaries(
    kernel: _executeKernelBoundary(fixture, kernelMap),
    persistent: _executePersistentBoundary(fixture, persistentMap),
    domain: _executeDomainBoundary(fixture, domainMap),
    tileLookupCalls: {
      'kernel': kernelMap.calls,
      'persistent': persistentMap.calls,
      'domain': domainMap.calls,
    },
    tileLookupHits: {
      'kernel': kernelMap.hits,
      'persistent': persistentMap.hits,
      'domain': domainMap.hits,
    },
  );
}

_CombatBoundaryExecution _executeKernelBoundary(
  _CombatCommandFixture fixture,
  MapTileLookup mapTiles,
) {
  final counters = FogOfWarRecomputeCounters();
  final result =
      CombatCommandResolver(
        fogOfWarService: FogOfWarService(counters: counters),
      ).resolve(
        state: fixture.kernelState,
        command: _combatCommand,
        actorPlayerId: _combatActorId,
        turn: _combatTurn,
        commandTick: _combatCommandTick,
        mapTiles: mapTiles,
        ruleset: _combatRuleset,
      );
  return _CombatBoundaryExecution(
    output: _normalizedCombatBoundary(
      accepted: result.accepted,
      reason: result.reason,
      units: result.units,
      fogOfWar: result.fogOfWar,
      diplomacy: result.diplomacy,
      events: result.events,
    ),
    fogCounters: counters,
  );
}

_CombatBoundaryExecution _executePersistentBoundary(
  _CombatCommandFixture fixture,
  MapTileLookup mapTiles,
) {
  final counters = FogOfWarRecomputeCounters();
  final result =
      PersistentCombatCommandResolver(
        fogOfWarService: FogOfWarService(counters: counters),
      ).resolve(
        state: fixture.persistentState,
        command: _combatCommand,
        actorPlayerId: _combatActorId,
        turn: _combatTurn,
        commandTick: _combatCommandTick,
        mapTiles: mapTiles,
        ruleset: _combatRuleset,
      );
  return _CombatBoundaryExecution(
    output: _normalizedCombatBoundary(
      accepted: result.accepted,
      reason: result.reason,
      units: result.state.units,
      fogOfWar: result.state.fogOfWar,
      diplomacy: result.state.runtimeState.diplomacy,
      events: result.events,
    ),
    fogCounters: counters,
  );
}

_CombatBoundaryExecution _executeDomainBoundary(
  _CombatCommandFixture fixture,
  MapTileLookup mapTiles,
) {
  final counters = FogOfWarRecomputeCounters();
  final result =
      DomainCombatCommandResolver(
        fogOfWarService: FogOfWarService(counters: counters),
      ).resolve(
        state: fixture.domainState,
        command: _combatCommand,
        actorPlayerId: _combatActorId,
        commandTick: _combatCommandTick,
        mapTiles: mapTiles,
        ruleset: _combatRuleset,
      );
  return _CombatBoundaryExecution(
    output: _normalizedCombatBoundary(
      accepted: result.accepted,
      reason: result.reason,
      units: result.state.units,
      fogOfWar: result.state.fogOfWar,
      diplomacy: result.state.diplomacy,
      events: result.events,
    ),
    fogCounters: counters,
  );
}

Map<String, Object?> _normalizedCombatBoundary({
  required bool accepted,
  required String? reason,
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  required DiplomacyState diplomacy,
  required List<GameEvent> events,
}) {
  final attacker = _unitById(units, _combatAttackerId);
  final defender = _unitById(units, _combatDefenderId);
  final eventPayloads = [
    for (final event in events) GameEventSerializer.toJson(event),
  ];
  final outcomes = [
    for (final event in events.whereType<CombatResolvedEvent>())
      CombatOutcomeSerializer.toJson(event.outcome),
  ];
  return {
    'accepted': accepted,
    'reason': reason,
    'attacker': _normalizedUnit(attacker),
    'defender': _normalizedUnit(defender),
    'actorVisibleHexes': fogOfWar
        .fogForPlayer(_combatActorId)
        .visibleHexes
        .length,
    'opponentVisibleHexes': fogOfWar
        .fogForPlayer(_combatOpponentId)
        .visibleHexes
        .length,
    'hasOpponentContact': diplomacy.hasContact(
      _combatActorId,
      _combatOpponentId,
    ),
    'events': eventPayloads,
    'outcomes': outcomes,
  };
}

Map<String, Object?>? _normalizedUnit(GameUnit? unit) {
  if (unit == null) return null;
  return {
    'id': unit.id,
    'ownerPlayerId': unit.ownerPlayerId,
    'col': unit.col,
    'row': unit.row,
    'hitPoints': unit.hitPoints,
    'movementPoints': unit.movementPoints,
    'experiencePoints': unit.experiencePoints,
  };
}

GameUnit? _unitById(List<GameUnit> units, String unitId) {
  for (final unit in units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

void _verifyBoundaryOutput(
  Map<String, Object?> expected,
  _CombatBoundaryExecution actual,
) {
  if (stableDigest(expected) != stableDigest(actual.output) ||
      actual.fogCounters.fullRecomputeCount != 1 ||
      actual.fogCounters.playerRecomputeCount != 0 ||
      actual.fogCounters.unitMoveIncrementalCount != 0 ||
      actual.fogCounters.unitMoveFallbackCount != 0) {
    throw StateError('Combat command workload produced unstable output.');
  }
}
