import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/city/domain_worker_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Applies authoritative worker improvement and assignment commands.
final class WorkerEngineHandler {
  const WorkerEngineHandler({
    this.resolver = const DomainWorkerCommandResolver(),
  });

  final DomainWorkerCommandResolver resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    if (command is SelectWorkerImprovementCommand) {
      return _selectImprovement(snapshot, command, context);
    }
    if (command is ConfirmWorkerImprovementCommand) {
      return _confirmImprovement(snapshot, command, context);
    }
    if (command is CancelWorkerJobCommand) {
      return _cancelJob(snapshot, command, context);
    }
    if (command is AssignWorkerToHexCommand) {
      return _assignWorker(snapshot, command, context);
    }
    if (command is CancelWorkerAssignmentCommand) {
      return _cancelAssignment(snapshot, command, context);
    }
    return GameEngineResult.rejected(
      snapshot: snapshot,
      reason: 'unsupported_domain_command',
    );
  }

  GameEngineResult _selectImprovement(
    CanonicalGameSnapshot snapshot,
    SelectWorkerImprovementCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.selectWorkerImprovement(
      state: snapshot.domain,
      interaction: snapshot.interaction,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _confirmImprovement(
    CanonicalGameSnapshot snapshot,
    ConfirmWorkerImprovementCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.confirmWorkerImprovement(
      state: snapshot.domain,
      interaction: snapshot.interaction,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      cityRuleset: context.ruleset.city,
      technologyRuleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
    ),
  );

  GameEngineResult _cancelJob(
    CanonicalGameSnapshot snapshot,
    CancelWorkerJobCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.cancelWorkerJob(
      state: snapshot.domain,
      interaction: snapshot.interaction,
      command: command,
      actorPlayerId: context.actorPlayerId,
    ),
  );

  GameEngineResult _assignWorker(
    CanonicalGameSnapshot snapshot,
    AssignWorkerToHexCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.assignWorkerToHex(
      state: snapshot.domain,
      interaction: snapshot.interaction,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
    ),
  );

  GameEngineResult _cancelAssignment(
    CanonicalGameSnapshot snapshot,
    CancelWorkerAssignmentCommand command,
    GameEngineContext context,
  ) => _result(
    snapshot,
    resolver.cancelWorkerAssignment(
      state: snapshot.domain,
      interaction: snapshot.interaction,
      command: command,
      actorPlayerId: context.actorPlayerId,
    ),
  );

  GameEngineResult _result(
    CanonicalGameSnapshot snapshot,
    DomainWorkerCommandResult result,
  ) {
    if (!result.accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final domainChanged = !identical(result.state, snapshot.domain);
    final interactionChanged = !identical(
      result.interaction,
      snapshot.interaction,
    );
    return GameEngineResult.accepted(
      snapshot: domainChanged || interactionChanged
          ? snapshot.copyWith(
              domain: domainChanged ? result.state : null,
              interaction: interactionChanged ? result.interaction : null,
            )
          : snapshot,
    );
  }
}
