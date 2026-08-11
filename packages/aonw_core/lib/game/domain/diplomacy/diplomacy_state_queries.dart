part of 'diplomacy_state.dart';

abstract final class _DiplomacyStateQueryOperations {
  static bool hasContact(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    return key.isNotEmpty && state.contactKeys.contains(key);
  }

  static DiplomaticRelation relationBetween(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    return state.relations[key] ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
  }

  static DiplomaticRelationStatus statusBetween(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) => playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId
      ? DiplomaticRelationStatus.neutral
      : relationBetween(state, playerAId, playerBId).status;

  static int relationScoreBetween(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) => playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId
      ? 0
      : relationBetween(state, playerAId, playerBId).relationScore;

  static DiplomaticRelationStatus scoreStatusBetween(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    final score = relationScoreBetween(state, playerAId, playerBId);
    return score >= DiplomacyState.friendlyScoreThreshold
        ? DiplomaticRelationStatus.friendly
        : score <= DiplomacyState.hostileScoreThreshold
        ? DiplomaticRelationStatus.hostile
        : DiplomaticRelationStatus.neutral;
  }

  static List<DiplomaticProposal> proposalsFor(
    DiplomacyState state,
    String playerId,
  ) {
    final proposals = [
      for (final proposal in state.pendingProposals.values)
        if (proposal.involves(playerId)) proposal,
    ]..sort((a, b) => a.createdTurn.compareTo(b.createdTurn));
    return List.unmodifiable(proposals);
  }

  static List<DiplomaticMessage> messagesFor(
    DiplomacyState state,
    String playerId,
  ) {
    final result = [
      for (final message in state.messages.values)
        if (message.involves(playerId)) message,
    ]..sort((a, b) => b.createdTurn.compareTo(a.createdTurn));
    return List.unmodifiable(result);
  }

  static List<DiplomaticMessage> messagesBetween(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    final relationKey = DiplomacyState.relationKey(playerAId, playerBId);
    final result = [
      for (final message in state.messages.values)
        if (DiplomacyState.relationKey(
              message.fromPlayerId,
              message.toPlayerId,
            ) ==
            relationKey)
          message,
    ]..sort((a, b) => b.createdTurn.compareTo(a.createdTurn));
    return List.unmodifiable(result);
  }

  static List<DiplomaticScoreEntry> scoreEntriesBetween(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    return state.scoreHistory[DiplomacyState.relationKey(
          playerAId,
          playerBId,
        )] ??
        const [];
  }

  static List<DiplomaticProposal> expiredProposals(
    DiplomacyState state,
    int turn,
  ) {
    final expired = [
      for (final proposal in state.pendingProposals.values)
        if (proposal.isExpired(turn)) proposal,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(expired);
  }

  static List<DiplomaticMessage> expiredMessages(
    DiplomacyState state,
    int turn,
  ) {
    final expired = [
      for (final message in state.messages.values)
        if (message.isExpired(turn)) message,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(expired);
  }

  static List<DiplomaticRelation> expiredTruces(
    DiplomacyState state,
    int turn,
  ) {
    final expired = [
      for (final relation in state.relations.values)
        if (relation.status == DiplomaticRelationStatus.truce &&
            relation.statusExpiresOnTurn != null &&
            turn >= relation.statusExpiresOnTurn!)
          relation,
    ]..sort((a, b) => a.key.compareTo(b.key));
    return List.unmodifiable(expired);
  }

  static List<DiplomaticMessage> promisesDue(DiplomacyState state, int turn) {
    final due = [
      for (final message in state.messages.values)
        if (message.hasActivePromise &&
            message.promiseDueTurn != null &&
            turn >= message.promiseDueTurn!)
          message,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(due);
  }
}
