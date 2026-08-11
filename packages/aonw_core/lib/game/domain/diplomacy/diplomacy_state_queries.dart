part of 'diplomacy_state.dart';

const _stateRelationKey = DiplomacyState.relationKey;
DiplomacyState _stateOf(Object value) => value as DiplomacyState;

mixin _DiplomacyStateQueries {
  bool hasContact(String playerAId, String playerBId) {
    final key = _stateRelationKey(playerAId, playerBId);
    return key.isNotEmpty && _stateOf(this).contactKeys.contains(key);
  }

  DiplomaticRelation relationBetween(String playerAId, String playerBId) {
    final key = _stateRelationKey(playerAId, playerBId);
    return _stateOf(this).relations[key] ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
  }

  DiplomaticRelationStatus statusBetween(String playerAId, String playerBId) =>
      playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId
      ? DiplomaticRelationStatus.neutral
      : relationBetween(playerAId, playerBId).status;

  int relationScoreBetween(String playerAId, String playerBId) =>
      playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId
      ? 0
      : relationBetween(playerAId, playerBId).relationScore;

  DiplomaticRelationStatus scoreStatusBetween(
    String playerAId,
    String playerBId,
  ) {
    final score = relationScoreBetween(playerAId, playerBId);
    return score >= DiplomacyState.friendlyScoreThreshold
        ? DiplomaticRelationStatus.friendly
        : score <= DiplomacyState.hostileScoreThreshold
        ? DiplomaticRelationStatus.hostile
        : DiplomaticRelationStatus.neutral;
  }

  List<DiplomaticProposal> proposalsFor(String playerId) {
    final proposals = [
      for (final proposal in _stateOf(this).pendingProposals.values)
        if (proposal.involves(playerId)) proposal,
    ]..sort((a, b) => a.createdTurn.compareTo(b.createdTurn));
    return List.unmodifiable(proposals);
  }

  List<DiplomaticMessage> messagesFor(String playerId) {
    final result = [
      for (final message in _stateOf(this).messages.values)
        if (message.involves(playerId)) message,
    ]..sort((a, b) => b.createdTurn.compareTo(a.createdTurn));
    return List.unmodifiable(result);
  }

  List<DiplomaticMessage> messagesBetween(String playerAId, String playerBId) {
    final result = [
      for (final message in _stateOf(this).messages.values)
        if (_stateRelationKey(message.fromPlayerId, message.toPlayerId) ==
            _stateRelationKey(playerAId, playerBId))
          message,
    ]..sort((a, b) => b.createdTurn.compareTo(a.createdTurn));
    return List.unmodifiable(result);
  }

  List<DiplomaticScoreEntry> scoreEntriesBetween(
    String playerAId,
    String playerBId,
  ) {
    return _stateOf(this).scoreHistory[_stateRelationKey(
          playerAId,
          playerBId,
        )] ??
        const [];
  }

  List<DiplomaticProposal> expiredProposals(int turn) {
    final expired = [
      for (final proposal in _stateOf(this).pendingProposals.values)
        if (proposal.isExpired(turn)) proposal,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(expired);
  }

  List<DiplomaticMessage> expiredMessages(int turn) {
    final expired = [
      for (final message in _stateOf(this).messages.values)
        if (message.isExpired(turn)) message,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(expired);
  }

  List<DiplomaticRelation> expiredTruces(int turn) {
    final expired = [
      for (final relation in _stateOf(this).relations.values)
        if (relation.status == DiplomaticRelationStatus.truce &&
            relation.statusExpiresOnTurn != null &&
            turn >= relation.statusExpiresOnTurn!)
          relation,
    ]..sort((a, b) => a.key.compareTo(b.key));
    return List.unmodifiable(expired);
  }

  List<DiplomaticMessage> promisesDue(int turn) {
    final due = [
      for (final message in _stateOf(this).messages.values)
        if (message.hasActivePromise &&
            message.promiseDueTurn != null &&
            turn >= message.promiseDueTurn!)
          message,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(due);
  }
}
