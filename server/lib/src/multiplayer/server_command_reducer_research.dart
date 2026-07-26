part of 'server_command_reducer.dart';

extension _ServerResearchCommandReducer on ServerCommandReducer {
  _CommandApplication _applySelectTechnologyCommand({
    required CanonicalGameSnapshot snapshot,
    required SelectTechnologyCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required GameRuleset ruleset,
  }) {
    final domain = snapshot.domain;
    final interaction = snapshot.interaction;
    final result = SelectTechnologyResolver.selectTechnology(
      research: domain.research,
      cities: domain.cities,
      fieldImprovements: domain.fieldImprovements,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      ruleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }

    final pendingAction =
        ResearchSelectionPendingActionPolicy.afterAcceptedSelection(
          pendingAction: interaction.pendingAction,
          playerId: command.playerId,
        );
    final researchChanged = !identical(result.research, domain.research);
    final interactionChanged = !identical(
      pendingAction,
      interaction.pendingAction,
    );
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: researchChanged
          ? domain.copyWith(research: result.research)
          : null,
      interaction: interactionChanged
          ? interaction.copyWith(pendingAction: pendingAction)
          : null,
    );
  }
}
