import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology/domain_research_command_resolver.dart';
import 'package:aonw_core/game/domain/technology/research_selection_pending_action_policy.dart';

/// Applies authoritative research-selection commands.
final class ResearchEngineHandler {
  const ResearchEngineHandler({
    this.resolver = const DomainResearchCommandResolver(),
  });

  final DomainResearchCommandResolver resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    if (command is! SelectTechnologyCommand) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      );
    }
    final result = resolver.selectTechnology(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      ruleset: context.ruleset.technology,
      paceBalance: context.ruleset.paceBalance,
    );
    if (!result.accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final domain = result.state == snapshot.domain
        ? snapshot.domain
        : result.state;
    final pendingAction =
        ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
          pendingAction: snapshot.domain.actions.pendingAction,
          playerId: command.playerId,
        );
    final interaction =
        identical(pendingAction, snapshot.domain.actions.pendingAction)
        ? snapshot.domain.actions
        : snapshot.domain.actions.copyWith(pendingAction: pendingAction);
    final domainChanged = !identical(domain, snapshot.domain);
    final interactionChanged = !identical(interaction, snapshot.domain.actions);
    return GameEngineResult.accepted(
      snapshot: domainChanged || interactionChanged
          ? snapshot.copyWith(
              domain: domainChanged ? domain : null,
              actions: interactionChanged ? interaction : null,
            )
          : snapshot,
    );
  }
}
