import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'map_boundary_source_guard.dart';
import 'resolved_dart_workspace.dart';

part 'authoritative_turn_movement_transport_ast.dart';
part 'authoritative_turn_movement_transport_ast_boundary.dart';
part 'authoritative_turn_movement_transport_forwarding.dart';
part 'authoritative_turn_movement_transport_graph.dart';
part 'authoritative_turn_movement_transport_rules.dart';

const _canonicalPipelinePath =
    'packages/aonw_core/lib/game/application/turn/'
    'canonical_turn_pipeline.dart';
const _movementExecutorPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'movement_command_executor.dart';
const _queuedPathAdvancerPath =
    'packages/aonw_core/lib/game/domain/turn/movement/'
    'turn_queued_path_advancer.dart';
const _unitMovementAdvancerPath =
    'packages/aonw_core/lib/game/domain/turn/movement/'
    'turn_unit_movement_advancer.dart';
const _wireMapperPath =
    'packages/aonw_core/lib/protocol/'
    'movement_execution_wire_mapper.dart';
const _wireEventPath = 'packages/aonw_core/lib/protocol/wire_event.dart';
const _wireAckPath = 'packages/aonw_core/lib/protocol/wire_command_ack.dart';
const _localResolverPath =
    'lib/game/application/services/local_command_resolver.dart';
const _localMovementProjectionPath =
    'lib/game/application/services/local_movement_engine_projection.dart';
const _queuedEffectBuilderPath =
    'lib/game/application/services/queued_movement_effect_builder.dart';
const _liveServerEventPath = 'lib/api/transport/live_server_event.dart';
const _ackEffectResolverPath =
    'lib/api/transport/acknowledged_command_effect_resolver.dart';
const _externalEffectResolverPath =
    'lib/game/presentation/providers/game/'
    'external_snapshot_renderer_effect_resolver.dart';
const _dispatcherPath =
    'lib/game/presentation/engine/game_effect_dispatcher.dart';
const _serverTurnsPath =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';
const _serverDomainEnginePath =
    'server/lib/src/multiplayer/server_command_reducer_unit_action.dart';
const _movementAudiencePath =
    'server/lib/src/multiplayer/player_match_movement_audience.dart';
const _viewProjectorPath =
    'server/lib/src/multiplayer/player_match_view_projector.dart';
const _performancePath = 'tool/performance/turn_finalization_workload.dart';

const _movementExecutionConstructorSites = {
  '$_movementExecutorPath::MovementCommandExecutor._applyMovedUnit': 1,
  '$_queuedPathAdvancerPath::TurnQueuedPathAdvancer._moveAlongPlan': 1,
  '$_unitMovementAdvancerPath::TurnUnitMovementAdvancer._advanceUnit': 1,
  '$_wireMapperPath::MovementExecutionWireMapper.decode': 1,
};

const _turnMovementDeltaConstructorSites = {
  '$_canonicalPipelinePath::CanonicalTurnPipeline.simultaneousFinalize': 1,
};

const _expectedReferences = <String, Map<String, int>>{
  'CanonicalTurnPipeline.simultaneousFinalize': {
    '$_localResolverPath::LocalCommandResolver._finalizeSimultaneousTurn': 1,
    '$_serverTurnsPath::ServerCommandReducerTurns._finalizeSimultaneousTurn': 1,
    '$_performancePath::_executeBoundaryRoundTrip': 1,
  },
  'MovementExecutionWireMapper.encode': {
    '$_movementAudiencePath::_annotatedExecutions': 1,
  },
  'MovementExecutionWireMapper.decode': {
    '$_liveServerEventPath::LiveServerEvent.fromWire': 1,
    '$_ackEffectResolverPath::AcknowledgedCommandEffectResolver.resolve': 1,
  },
  'PlayerMatchMovementAudience.projectForRecipient': {
    '$_viewProjectorPath::PlayerMatchViewProjector.eventFor': 1,
    '$_viewProjectorPath::PlayerMatchViewProjector._ackForPrepared': 1,
  },
  'QueuedMovementEffectBuilder.fromExecutions': {
    '$_localResolverPath::LocalCommandResolver._finalizeSimultaneousTurn': 1,
    '$_localMovementProjectionPath::projectLocalMovementEngineResult': 1,
    '$_ackEffectResolverPath::AcknowledgedCommandEffectResolver.resolve': 1,
    '$_externalEffectResolverPath::'
            'ExternalSnapshotRendererEffectResolver.resolve':
        1,
  },
  'UnitAnimationController.animateUnitMove': {
    '$_dispatcherPath::GameEffectDispatcher._handleUnitMove': 1,
  },
};

const _transportGraphRootPaths = {
  _wireMapperPath,
  _wireEventPath,
  _wireAckPath,
  _localResolverPath,
  _localMovementProjectionPath,
  _queuedEffectBuilderPath,
  _liveServerEventPath,
  _ackEffectResolverPath,
  'lib/api/transport/network_command_transport.dart',
  'lib/game/application/services/live_snapshot_presentation_policy.dart',
  _externalEffectResolverPath,
  'lib/game/presentation/providers/game/live_snapshot_presentation_resolver.dart',
  'lib/game/presentation/providers/game/game_state_provider_renderer_effects.dart',
  'lib/game/presentation/providers/game/game_state_provider.dart',
  _dispatcherPath,
  'server/lib/src/multiplayer/server_command_reducer.dart',
  _serverDomainEnginePath,
  _serverTurnsPath,
  'server/lib/src/multiplayer/server_command_reducer_outcome.dart',
  'server/lib/src/multiplayer/match_command_service.dart',
  'server/lib/src/multiplayer/match_command_service_event.dart',
  'server/lib/src/multiplayer/match_command_service_handling.dart',
  _movementAudiencePath,
  _viewProjectorPath,
};

const _transportGraphStopPaths = {
  _canonicalPipelinePath,
  _movementExecutorPath,
  _queuedPathAdvancerPath,
  _unitMovementAdvancerPath,
};

const _forbiddenTransportTypes = {
  'UnitMovementPathfinder',
  'ScoutAutoExplorePlanner',
  'MovementCommandResolver',
  'TurnQueuedPathAdvancer',
  'LegacyWorldMapAdapter',
};

const _forbiddenTransportLibraryNames = {
  'unit_movement_pathfinder.dart',
  'scout_auto_explore_planner.dart',
  'movement_command_resolver.dart',
  'turn_queued_path_advancer.dart',
  'legacy_world_map_adapter.dart',
};

const _orderSensitiveOwners = {
  '$_canonicalPipelinePath::CanonicalTurnPipeline.simultaneousFinalize',
  '$_localResolverPath::LocalCommandResolver._finalizeSimultaneousTurn',
  '$_serverTurnsPath::ServerCommandReducerTurns._finalizeSimultaneousTurn',
  '$_serverDomainEnginePath::'
      '_ServerCommandReducerUnitAction._applyDomainCommandEngine',
  '$_localMovementProjectionPath::projectLocalMovementEngineResult',
  '$_movementAudiencePath::'
      'PlayerMatchMovementAudience.annotateForStorage',
  '$_movementAudiencePath::'
      'PlayerMatchMovementAudience.projectForRecipient',
  '$_movementAudiencePath::_annotatedExecutions',
  '$_movementAudiencePath::_projectedExecutions',
  '$_liveServerEventPath::LiveServerEvent.fromWire',
  '$_ackEffectResolverPath::AcknowledgedCommandEffectResolver.resolve',
  '$_queuedEffectBuilderPath::QueuedMovementEffectBuilder.fromExecutions',
  '$_externalEffectResolverPath::'
      'ExternalSnapshotRendererEffectResolver.resolve',
};

const _forbiddenOrderMembers = {
  'add',
  'addAll',
  'expand',
  'followedBy',
  'groupBy',
  'groupFoldBy',
  'groupListsBy',
  'merge',
  'mergeSort',
  'reversed',
  'shuffle',
  'sort',
  'sortBy',
  'sortByCompare',
  'sorted',
  'sortedBy',
  'sortedByCompare',
  'toSet',
};

const _executionCarrierNames = {
  'MovementCommandExecution',
  'WireMovementExecution',
};

/// Result of one resolved-AST audit of the authoritative movement boundary.
final class AuthoritativeTurnMovementTransportAudit {
  const AuthoritativeTurnMovementTransportAudit({
    required this.violations,
    required this.canonicalFinalizeReferencesByPath,
  });

  final List<String> violations;
  final Map<String, int> canonicalFinalizeReferencesByPath;
}

/// Audits ownership and ordering from canonical turn reduction to rendering.
///
/// The initial source scan only routes likely files into analyzer. Every
/// ownership, call, type, import, nullability and forwarding decision below is
/// made from resolved AST elements.
Future<AuthoritativeTurnMovementTransportAudit>
authoritativeTurnMovementTransportAudit({
  String? rootPath,
  Map<String, String> sourceOverrides = const {},
}) async {
  final workspace = ResolvedDartWorkspace(
    rootPath: rootPath ?? Directory.current.path,
    sourceOverrides: sourceOverrides,
  );
  try {
    final sources = productionDartSources();
    final normalizedOverrides = {
      for (final entry in sourceOverrides.entries)
        workspace.displayPath(entry.key): entry.value,
    };
    sources.addAll(normalizedOverrides);
    final paths = _candidatePaths(sources, normalizedOverrides.keys);
    final resolved = await _resolveTransportGraph(
      workspace: workspace,
      sources: sources,
      candidatePaths: paths,
    );
    final units = resolved.units;
    final facts = _TransportFacts();
    for (final entry in units.entries) {
      entry.value.unit.accept(
        _TransportFactVisitor(
          path: entry.key,
          unit: entry.value.unit,
          facts: facts,
          transportGraphPaths: resolved.transportGraphPaths,
        ),
      );
    }

    final violations = <String>[
      ..._constructorViolations(
        facts,
        typeName: 'MovementCommandExecution',
        expected: _movementExecutionConstructorSites,
      ),
      ..._constructorViolations(
        facts,
        typeName: 'TurnMovementDelta',
        expected: _turnMovementDeltaConstructorSites,
      ),
      ..._referenceViolations(facts),
      ...facts.boundaryViolations,
      ..._envelopeViolations(units),
      ..._projectorEgressViolations(units),
      ..._forwardingViolations(units),
      ..._engineMovementForwardingViolations(units),
      ..._rendererRetentionViolations(units),
    ]..sort();

    final canonicalSites =
        facts.referenceCounts['CanonicalTurnPipeline.simultaneousFinalize'] ??
        const {};
    final canonicalByPath = <String, int>{};
    for (final entry in canonicalSites.entries) {
      final path = entry.key.split('::').first;
      canonicalByPath.update(
        path,
        (count) => count + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    return AuthoritativeTurnMovementTransportAudit(
      violations: List.unmodifiable(violations),
      canonicalFinalizeReferencesByPath: Map.unmodifiable(canonicalByPath),
    );
  } finally {
    await workspace.dispose();
  }
}
