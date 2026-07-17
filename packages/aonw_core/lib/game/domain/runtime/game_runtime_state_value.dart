part of 'game_runtime_state.dart';

bool _sameRuntimeState(GameRuntimeState left, GameRuntimeState right) {
  return _sameRuntimeInteraction(left, right) &&
      _sameRuntimeParticipation(left, right) &&
      _sameRuntimeOutcomes(left, right);
}

bool _sameRuntimeInteraction(GameRuntimeState left, GameRuntimeState right) {
  return left.cityFoundingDraft == right.cityFoundingDraft &&
      left.pendingAction == right.pendingAction;
}

bool _sameRuntimeParticipation(GameRuntimeState left, GameRuntimeState right) {
  return setEquals(left.submittedPlayerIds, right.submittedPlayerIds) &&
      mapEquals(
        left.timeoutStreaksByPlayerId,
        right.timeoutStreaksByPlayerId,
      ) &&
      setEquals(left.afkPlayerIds, right.afkPlayerIds) &&
      setEquals(left.kickedPlayerIds, right.kickedPlayerIds) &&
      listEquals(left.intendedAttacks, right.intendedAttacks);
}

bool _sameRuntimeOutcomes(GameRuntimeState left, GameRuntimeState right) {
  return left.diplomacy == right.diplomacy &&
      mapEquals(
        left.dominationHoldTurnsByPlayerId,
        right.dominationHoldTurnsByPlayerId,
      ) &&
      mapEquals(
        left.culturalVictoryHoldTurnsByPlayerId,
        right.culturalVictoryHoldTurnsByPlayerId,
      ) &&
      mapEquals(
        left.mapObjectiveHoldStatesByObjectiveId,
        right.mapObjectiveHoldStatesByObjectiveId,
      ) &&
      listEquals(left.resourceTradeAgreements, right.resourceTradeAgreements) &&
      left.turnStartedAt == right.turnStartedAt;
}
