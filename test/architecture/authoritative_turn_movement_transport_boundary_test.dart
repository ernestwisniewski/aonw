import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/authoritative_turn_movement_transport_guard.dart';

const _canonicalPipelinePath =
    'packages/aonw_core/lib/game/application/turn/'
    'canonical_turn_pipeline.dart';
const _wireEventPath = 'packages/aonw_core/lib/protocol/wire_event.dart';
const _wireAckPath = 'packages/aonw_core/lib/protocol/wire_command_ack.dart';
const _liveServerEventPath = 'lib/api/transport/live_server_event.dart';
const _localResolverPath =
    'lib/game/application/services/local_command_resolver.dart';
const _queuedEffectBuilderPath =
    'lib/game/application/services/queued_movement_effect_builder.dart';
const _virtualBypassHelperPath =
    'lib/game/application/services/authoritative_movement_bypass.dart';
const _dispatcherPath =
    'lib/game/presentation/engine/game_effect_dispatcher.dart';
const _movementAudiencePath =
    'server/lib/src/multiplayer/player_match_movement_audience.dart';
const _viewProjectorPath =
    'server/lib/src/multiplayer/player_match_view_projector.dart';
const _serverTurnsPath =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';
const _serverAutoExplorePath =
    'server/lib/src/multiplayer/server_command_reducer_auto_explore.dart';
const _performancePath = 'tool/performance/turn_finalization_workload.dart';

void main() {
  group('authoritative turn movement transport boundary', () {
    test(
      'resolved production ownership and forwarding match the contract',
      _expectProductionContract,
    );

    for (final scenario in _mutationScenarios()) {
      test(scenario.name, () => _expectMutationRejected(scenario));
    }
    test(
      'unrelated collection ordering remains outside the movement boundary',
      _expectUnrelatedOrderingAllowed,
    );
  });
}

Future<void> _expectProductionContract() async {
  final audit = await authoritativeTurnMovementTransportAudit();

  expect(audit.violations, isEmpty);
  expect(audit.canonicalFinalizeReferencesByPath, {
    _localResolverPath: 1,
    _serverTurnsPath: 1,
    _performancePath: 1,
  });
}

Future<void> _expectMutationRejected(_MutationScenario scenario) async {
  final physicalSources = {
    for (final path in scenario.physicalPaths) path: _source(path),
  };
  final audit = await authoritativeTurnMovementTransportAudit(
    sourceOverrides: scenario.overrides(physicalSources),
  );

  for (final fragment in scenario.expectedViolationFragments) {
    expect(
      audit.violations,
      contains(contains(fragment)),
      reason:
          '${scenario.name} must independently reject "$fragment".\n'
          'Actual violations:\n${audit.violations.join('\n')}',
    );
  }
  for (final entry in physicalSources.entries) {
    expect(
      _source(entry.key),
      entry.value,
      reason: 'Analyzer overlays must not mutate ${entry.key}.',
    );
  }
}

Future<void> _expectUnrelatedOrderingAllowed() async {
  final original = _source(_queuedEffectBuilderPath);
  final audit = await authoritativeTurnMovementTransportAudit(
    sourceOverrides: {
      _queuedEffectBuilderPath:
          '''
$original

List<String> _sortedLabels(Iterable<String> values) =>
    values.toList()..sort();
''',
    },
  );

  expect(audit.violations, isEmpty);
  expect(_source(_queuedEffectBuilderPath), original);
}

List<_MutationScenario> _mutationScenarios() => [
  const _MutationScenario(
    name: 'resolved ratchets reject every direct contract bypass',
    physicalPaths: {
      _canonicalPipelinePath,
      _wireEventPath,
      _wireAckPath,
      _liveServerEventPath,
      _localResolverPath,
      _queuedEffectBuilderPath,
      _dispatcherPath,
      _movementAudiencePath,
      _serverTurnsPath,
    },
    overrides: _directContractBypasses,
    expectedViolationFragments: [
      'MovementCommandExecution constructor sites changed',
      'TurnMovementDelta constructor sites changed',
      'CanonicalTurnPipeline.simultaneousFinalize reference sites changed',
      'MovementExecutionWireMapper.encode reference sites changed',
      'MovementExecutionWireMapper.decode reference sites changed',
      'QueuedMovementEffectBuilder.fromExecutions reference sites changed',
      'UnitAnimationController.animateUnitMove reference sites changed',
      'imports forbidden movement producer',
      'references forbidden movement producer UnitMovementPathfinder',
      'must not reorder or rebuild authoritative movement with sort',
      'must not reorder or rebuild authoritative movement with addAll',
      'must not reorder or rebuild authoritative movement with toSet',
      'wire_event.dart::WireEvent.movementExecutions must be exactly one '
          'required non-null WireMovementExecutionList',
      'wire_command_ack.dart::WireCommandAck.movementExecutions must be '
          'exactly one required non-null WireMovementExecutionList',
      'LocalCommandResolver._finalizeSimultaneousTurn must forward '
          'TurnMovementDelta.executions directly',
      'LocalCommandResolver._finalizeSimultaneousTurn must preserve the '
          'CanonicalTurnPipeline result receiver provenance',
      'ServerCommandReducerTurns._finalizeSimultaneousTurn must forward '
          'TurnMovementDelta.executions directly',
      'ServerCommandReducerTurns._finalizeSimultaneousTurn must preserve the '
          'CanonicalTurnPipeline result receiver provenance',
      'CanonicalTurnPipeline.simultaneousFinalize must forward '
          'CanonicalTurnSuffixResult.movementExecutions directly',
      'CanonicalTurnPipeline.simultaneousFinalize must preserve the '
          'CanonicalTurnSuffix result receiver provenance',
      'must forward retainAtDestination directly',
      'must use the _onRendererStateChanged field only',
      'must forward retainMovementAtDestination directly',
    ],
  ),
  const _MutationScenario(
    name: 'event and ack egress require the projector result itself',
    physicalPaths: {_viewProjectorPath},
    overrides: _projectorEgressBypasses,
    expectedViolationFragments: [
      'PlayerMatchViewProjector.eventFor must forward '
          'PlayerMatchMovementAudience.projectForRecipient directly',
      'PlayerMatchViewProjector._ackForPrepared must forward '
          'PlayerMatchMovementAudience.projectForRecipient directly',
    ],
  ),
  const _MutationScenario(
    name: 'imported helper cannot re-plan, reorder, merge or rebuild',
    physicalPaths: {_queuedEffectBuilderPath},
    overrides: _transitiveHelperBypass,
    expectedViolationFragments: [
      'authoritative_movement_bypass.dart',
      'imports forbidden movement producer',
      'references forbidden movement producer UnitMovementPathfinder',
      'must not reorder or rebuild authoritative movement with sort',
      'must not reorder or rebuild authoritative movement with addAll',
      'must not reorder or rebuild authoritative movement with toSet',
      'must not reorder or rebuild authoritative movement with reversed',
    ],
  ),
  const _MutationScenario(
    name: 'direct auto-explore must forward its movement execution',
    physicalPaths: {_serverAutoExplorePath},
    overrides: _autoExploreForwardingBypass,
    expectedViolationFragments: [
      '_ServerCommandReducerAutoExplore._applyAutoExplore must forward '
          'AutoExploreCommandResult.execution directly as movementExecutions',
    ],
  ),
];

Map<String, String> _directContractBypasses(Map<String, String> sources) => {
  _canonicalPipelinePath: _illegalCanonicalSource(
    sources[_canonicalPipelinePath]!,
  ),
  ..._nullableEnvelopeBypasses(sources),
  _liveServerEventPath: _illegalProducerSource(sources[_liveServerEventPath]!),
  _localResolverPath: _illegalLocalSource(sources[_localResolverPath]!),
  _queuedEffectBuilderPath: _rebuildingBuilderSource(
    sources[_queuedEffectBuilderPath]!,
  ),
  _dispatcherPath: _illegalDispatcherSource(sources[_dispatcherPath]!),
  _movementAudiencePath: _illegalMapperSource(sources[_movementAudiencePath]!),
  _serverTurnsPath: _wrappedServerReceiverSource(sources[_serverTurnsPath]!),
};

Map<String, String> _projectorEgressBypasses(Map<String, String> sources) => {
  _viewProjectorPath: _bypassedProjectorSource(sources[_viewProjectorPath]!),
};

Map<String, String> _nullableEnvelopeBypasses(Map<String, String> sources) => {
  _wireEventPath: _replaceOnce(
    sources[_wireEventPath]!,
    'required WireMovementExecutionList movementExecutions,',
    'WireMovementExecutionList? movementExecutions,',
  ),
  _wireAckPath: _replaceOnce(
    sources[_wireAckPath]!,
    'required WireMovementExecutionList movementExecutions,',
    'required WireMovementExecutionList? movementExecutions,',
  ),
};

Map<String, String> _transitiveHelperBypass(Map<String, String> sources) => {
  _queuedEffectBuilderPath: _helperBackedBuilderSource(
    sources[_queuedEffectBuilderPath]!,
  ),
  _virtualBypassHelperPath: _virtualBypassHelperSource,
};

Map<String, String> _autoExploreForwardingBypass(Map<String, String> sources) =>
    {
      _serverAutoExplorePath: _replaceOnce(
        sources[_serverAutoExplorePath]!,
        'movementExecutions: [?result.execution],',
        'movementExecutions: const [],',
      ),
    };

String _illegalCanonicalSource(String source) {
  return _wrappedCanonicalReceiverSource('''
$source

TurnMovementDelta _illegalMovementDelta(List<GameUnit> units) =>
    TurnMovementDelta(beforeUnits: units, afterUnits: units);
''');
}

String _illegalProducerSource(String source) {
  final withImport = _replaceOnce(
    source,
    "import 'package:aonw_core/game/domain/movement.dart';",
    '''
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
''',
  );
  return '''
$withImport

MovementCommandExecution _illegalExecution() => MovementCommandExecution(
  unitId: 'illegal',
  fromCol: 0,
  fromRow: 0,
  steps: const [],
);
typedef _ForbiddenPathfinder = UnitMovementPathfinder;
''';
}

String _illegalLocalSource(String source) {
  final wrapped = _wrappedLocalReceiverSource(source);
  return '''
$wrapped

final _illegalFinalize = CanonicalTurnPipeline.simultaneousFinalize;
final _illegalEffectBuilder = QueuedMovementEffectBuilder.fromExecutions;
''';
}

String _rebuildingBuilderSource(String source) {
  return _replaceOnce(
    source,
    'final ordered = List<MovementCommandExecution>.of(executions);',
    '''
var ordered = List<MovementCommandExecution>.of(executions);
    ordered.sort((left, right) => left.unitId.compareTo(right.unitId));
    ordered.addAll(executions);
    ordered = ordered.toSet().toList(growable: false);
''',
  );
}

String _illegalDispatcherSource(String source) {
  var mutated = _replaceOnce(
    source,
    'retainAtDestination: retainAtDestination,',
    'retainAtDestination: false,',
  );
  mutated = _replaceOnce(
    mutated,
    'retainAtDestination: retainMovementAtDestination,',
    'retainAtDestination: false,',
  );
  mutated = _shadowedRendererCallbackSource(mutated);
  return '''
$mutated

Future<void> _illegalAnimateUnitMove(
  UnitAnimationController controller,
  AnimateUnitMoveEffect effect,
) => controller.animateUnitMove(
  unitId: effect.unitId,
  fromCol: effect.fromCol,
  fromRow: effect.fromRow,
  steps: effect.steps,
  onComplete: () {},
);
''';
}

String _illegalMapperSource(String source) {
  return '''
$source

final _illegalEncode = MovementExecutionWireMapper.encode;
final _illegalDecode = MovementExecutionWireMapper.decode;
''';
}

String _bypassedProjectorSource(String source) {
  final eventBypass = _replaceOnce(
    source,
    '''
        events: events,
        movementExecutions: PlayerMatchMovementAudience.projectForRecipient(
          canonical.movementExecutions,
          recipientPlayerId: recipient.playerId,
        ),
''',
    '''
        events: events,
        movementExecutions: (() {
          PlayerMatchMovementAudience.projectForRecipient(
            canonical.movementExecutions,
            recipientPlayerId: recipient.playerId,
          );
          return canonical.movementExecutions;
        })(),
''',
  );
  return _replaceOnce(
    eventBypass,
    '''
        reason: canonical.reason,
        movementExecutions: PlayerMatchMovementAudience.projectForRecipient(
          canonical.movementExecutions,
          recipientPlayerId: recipient.playerId,
        ),
''',
    '''
        reason: canonical.reason,
        movementExecutions: (() {
          PlayerMatchMovementAudience.projectForRecipient(
            canonical.movementExecutions,
            recipientPlayerId: recipient.playerId,
          );
          return canonical.movementExecutions;
        })(),
''',
  );
}

String _wrappedLocalReceiverSource(String source) {
  final wrapped = _replaceOnce(
    source,
    'movementDelta.executions,',
    '_movementDeltaIdentity(movementDelta).executions,',
  );
  return '''
$wrapped

TurnMovementDelta _movementDeltaIdentity(TurnMovementDelta value) => value;
''';
}

String _wrappedServerReceiverSource(String source) {
  final wrapped = _replaceOnce(
    source,
    'movementExecutions: result.movementDelta.executions,',
    'movementExecutions: '
        '_movementDeltaIdentity(result.movementDelta).executions,',
  );
  return '''
$wrapped

TurnMovementDelta _movementDeltaIdentity(TurnMovementDelta value) => value;
''';
}

String _wrappedCanonicalReceiverSource(String source) {
  final wrapped = _replaceOnce(
    source,
    'executions: suffix.movementExecutions,',
    'executions: _suffixIdentity(suffix).movementExecutions,',
  );
  return '''
$wrapped

CanonicalTurnSuffixResult _suffixIdentity(
  CanonicalTurnSuffixResult value,
) => value;
''';
}

String _shadowedRendererCallbackSource(String source) {
  return _replaceOnce(
    source,
    '''  }) async {
    final unitId = effect.unitId;''',
    '''  }) async {
    void _onRendererStateChanged() {}

    final unitId = effect.unitId;''',
  );
}

String _helperBackedBuilderSource(String source) {
  final withImport = _replaceOnce(
    source,
    "import 'package:aonw/game/domain/game_state_transition.dart';",
    '''
import 'package:aonw/game/application/services/authoritative_movement_bypass.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
''',
  );
  return _replaceOnce(
    withImport,
    'final ordered = List<MovementCommandExecution>.of(executions);',
    'final ordered = rebuildAuthoritativeMovement(executions);',
  );
}

const _virtualBypassHelperSource = '''
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';

typedef ForbiddenReplanner = UnitMovementPathfinder;

List<MovementCommandExecution> rebuildAuthoritativeMovement(
  Iterable<MovementCommandExecution> executions,
) {
  var rebuilt = List<MovementCommandExecution>.of(executions);
  rebuilt.sort((left, right) => left.unitId.compareTo(right.unitId));
  rebuilt.addAll(executions);
  rebuilt = rebuilt.toSet().toList(growable: false);
  rebuilt = rebuilt.reversed.toList(growable: false);
  return rebuilt;
}
''';

String _source(String path) => File(path).readAsStringSync();

String _replaceOnce(String source, String before, String after) {
  final first = source.indexOf(before);
  if (first < 0 || source.indexOf(before, first + before.length) >= 0) {
    throw StateError('Expected exactly one mutation anchor: $before');
  }
  return source.replaceFirst(before, after);
}

typedef _SourceOverrides =
    Map<String, String> Function(Map<String, String> sources);

final class _MutationScenario {
  const _MutationScenario({
    required this.name,
    required this.physicalPaths,
    required this.overrides,
    required this.expectedViolationFragments,
  });

  final String name;
  final Set<String> physicalPaths;
  final _SourceOverrides overrides;
  final List<String> expectedViolationFragments;
}
