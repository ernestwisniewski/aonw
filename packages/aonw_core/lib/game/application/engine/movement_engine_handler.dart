import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/application/engine/movement_execution_delta.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement/domain_auto_explore_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/domain_merchant_routing_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/domain_move_unit_resolver.dart';
import 'package:aonw_core/game/domain/movement/domain_unit_action_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/domain_worker_automation_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/worker_automation_command_phase.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/unit/domain_unit_detachment_resolver.dart';

/// Applies authoritative movement-family commands to a canonical snapshot.
final class MovementEngineHandler {
  const MovementEngineHandler({
    this.moveResolver = const DomainMoveUnitResolver(),
    this.autoExploreResolver = const DomainAutoExploreCommandResolver(),
    this.workerAutomationResolver =
        const DomainWorkerAutomationCommandResolver(),
    this.merchantResolver = const DomainMerchantRoutingCommandResolver(),
    this.unitActionResolver = const DomainUnitActionCommandResolver(),
    this.detachmentResolver = const DomainUnitDetachmentResolver(),
  });

  final DomainMoveUnitResolver moveResolver;
  final DomainAutoExploreCommandResolver autoExploreResolver;
  final DomainWorkerAutomationCommandResolver workerAutomationResolver;
  final DomainMerchantRoutingCommandResolver merchantResolver;
  final DomainUnitActionCommandResolver unitActionResolver;
  final DomainUnitDetachmentResolver detachmentResolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    return switch (command) {
      final MoveUnitCommand value => _move(snapshot, value, context),
      final CancelUnitActionCommand value => _cancel(snapshot, value, context),
      final AutoExploreUnitCommand value => _autoExplore(
        snapshot,
        value,
        context,
      ),
      final AutomateWorkerCommand value => _automateWorker(
        snapshot,
        value,
        context,
      ),
      final AssignMerchantTradeRouteCommand value => _merchant(
        snapshot,
        merchantResolver.assignRoute(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
          mapData: context.mapView,
        ),
      ),
      final MoveMerchantToCityCommand value => _merchant(
        snapshot,
        merchantResolver.moveToCity(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
          mapData: context.mapView,
        ),
      ),
      final DetachTroopCommand value => _detach(snapshot, value, context),
      _ => GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      ),
    };
  }

  GameEngineResult _move(
    CanonicalGameSnapshot snapshot,
    MoveUnitCommand command,
    GameEngineContext context,
  ) {
    final result = moveResolver.resolve(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapData: context.mapView,
      visibilityMode: context.movementVisibilityMode,
    );
    if (!result.accepted) return _rejected(snapshot, result.reason);
    return _accepted(
      snapshot,
      domain: result.state,
      events: result.events,
      execution: result.execution,
    );
  }

  GameEngineResult _cancel(
    CanonicalGameSnapshot snapshot,
    CancelUnitActionCommand command,
    GameEngineContext context,
  ) {
    final result = unitActionResolver.cancelUnitAction(
      state: snapshot.domain,
      interaction: snapshot.domain.actions,
      command: command,
      actorPlayerId: context.actorPlayerId,
    );
    if (!result.accepted) return _rejected(snapshot, result.reason);
    return _accepted(
      snapshot,
      domain: result.state,
      interaction: result.interaction,
    );
  }

  GameEngineResult _autoExplore(
    CanonicalGameSnapshot snapshot,
    AutoExploreUnitCommand command,
    GameEngineContext context,
  ) {
    final result = autoExploreResolver.resolve(
      state: snapshot.domain,
      interaction: snapshot.domain.actions,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapData: context.mapView,
    );
    if (!result.accepted) return _rejected(snapshot, result.reason);
    return _accepted(
      snapshot,
      domain: result.state,
      interaction: result.interaction,
      events: result.events,
      execution: result.execution,
    );
  }

  GameEngineResult _automateWorker(
    CanonicalGameSnapshot snapshot,
    AutomateWorkerCommand command,
    GameEngineContext context,
  ) {
    final result = workerAutomationResolver.resolve(
      state: snapshot.domain,
      interaction: snapshot.domain.actions,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapData: context.mapView,
      phase: WorkerAutomationCommandPhase.direct,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
      visibilityMode: context.movementVisibilityMode,
    );
    if (!result.accepted) return _rejected(snapshot, result.reason);
    return _accepted(
      snapshot,
      domain: result.state,
      interaction: result.interaction,
      events: result.events,
      execution: result.execution,
    );
  }

  GameEngineResult _merchant(
    CanonicalGameSnapshot snapshot,
    DomainMerchantRoutingCommandResult result,
  ) {
    if (!result.accepted) return _rejected(snapshot, result.reason);
    return _accepted(snapshot, domain: result.state);
  }

  GameEngineResult _detach(
    CanonicalGameSnapshot snapshot,
    DetachTroopCommand command,
    GameEngineContext context,
  ) {
    final result = detachmentResolver.detachTroop(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      visibilityMode: context.movementVisibilityMode,
    );
    if (!result.accepted) return _rejected(snapshot, result.reason);
    return _accepted(snapshot, domain: result.state);
  }

  static GameEngineResult _accepted(
    CanonicalGameSnapshot snapshot, {
    required DomainState domain,
    DomainActionState? interaction,
    List<GameEvent> events = const [],
    MovementCommandExecution? execution,
  }) {
    final domainChanged = !identical(domain, snapshot.domain);
    final nextInteraction = interaction ?? snapshot.domain.actions;
    final interactionChanged = !identical(
      nextInteraction,
      snapshot.domain.actions,
    );
    return GameEngineResult.accepted(
      snapshot: domainChanged || interactionChanged
          ? snapshot.copyWith(
              domain: domainChanged ? domain : null,
              actions: interactionChanged ? nextInteraction : null,
            )
          : snapshot,
      events: [for (final event in events) event as DomainEvent],
      movementDelta: MovementExecutionDelta(
        beforeUnits: snapshot.domain.units,
        afterUnits: domain.units,
        executions: [?execution],
      ),
    );
  }

  static GameEngineResult _rejected(
    CanonicalGameSnapshot snapshot,
    String? reason,
  ) {
    return GameEngineResult.rejected(
      snapshot: snapshot,
      reason: reason ?? 'command_rejected',
    );
  }
}
