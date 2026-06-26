part of 'hud_action_deck.dart';

final class _HudResearchAutoPromptPolicy {
  const _HudResearchAutoPromptPolicy({
    required this.remainingActionCount,
    required this.activePlayerId,
    required this.technologyRuleset,
    required this.gameSave,
  });

  final int remainingActionCount;
  final String activePlayerId;
  final TechnologyRuleset technologyRuleset;
  final GameSave gameSave;

  String? actionKeyFor(GameState? state) {
    if (state == null) return null;
    if (remainingActionCount != 1) return null;
    if (activePlayerId.isEmpty) return null;
    if (!_pendingResearchActionBelongsToActivePlayer(state.pendingAction)) {
      return null;
    }

    final playerResearch = state.research.forPlayer(activePlayerId);
    if (playerResearch.activeTechnologyId != null) return null;
    if (!_hasAvailableTechnology(playerResearch)) return null;

    return hudResearchActionKey(save: gameSave, activePlayerId: activePlayerId);
  }

  bool _pendingResearchActionBelongsToActivePlayer(
    PendingPlayerAction? pendingAction,
  ) {
    return switch (pendingAction) {
      PendingResearchSelection(:final ownerPlayerId) =>
        ownerPlayerId == activePlayerId,
      _ => true,
    };
  }

  bool _hasAvailableTechnology(PlayerResearchState playerResearch) {
    return technologyRuleset.technologies.keys.any(
      (technologyId) =>
          TechnologyAvailabilityService.availabilityFor(
            technologyId: technologyId,
            playerResearch: playerResearch,
            ruleset: technologyRuleset,
          ) ==
          TechnologyAvailability.available,
    );
  }
}
