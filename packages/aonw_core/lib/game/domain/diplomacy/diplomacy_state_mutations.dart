part of 'diplomacy_state.dart';

abstract final class _DiplomacyStateMutationOperations {
  static DiplomacyState registerUnitAttack(
    DiplomacyState state, {
    required String attackerPlayerId,
    required String defenderPlayerId,
    int? turn,
  }) {
    return setStatus(
      state,
      attackerPlayerId,
      defenderPlayerId,
      DiplomaticRelationStatus.hostile,
      turn: turn,
      reason: DiplomaticRelationChangeReason.unitAttack,
      allowDowngrade: false,
    ).adjustRelationScore(
      attackerPlayerId,
      defenderPlayerId,
      -10,
      turn: turn,
      reason: DiplomaticScoreChangeReason.unitAttack,
    );
  }

  static DiplomacyState registerCityAttack(
    DiplomacyState state, {
    required String attackerPlayerId,
    required String defenderPlayerId,
    int? turn,
  }) {
    return setStatus(
      state,
      attackerPlayerId,
      defenderPlayerId,
      DiplomaticRelationStatus.war,
      turn: turn,
      reason: DiplomaticRelationChangeReason.cityAttack,
      allowDowngrade: false,
    ).adjustRelationScore(
      attackerPlayerId,
      defenderPlayerId,
      -30,
      turn: turn,
      reason: DiplomaticScoreChangeReason.cityAttack,
    );
  }

  static DiplomacyState declareWar(
    DiplomacyState state, {
    required String playerId,
    required String targetPlayerId,
    int? turn,
  }) {
    return declareWarWithScoreEntry(
      state,
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      turn: turn,
    ).state;
  }

  static DiplomaticScoreAdjustment declareWarWithScoreEntry(
    DiplomacyState state, {
    required String playerId,
    required String targetPlayerId,
    int? turn,
  }) {
    return setStatus(
          state,
          playerId,
          targetPlayerId,
          DiplomaticRelationStatus.war,
          turn: turn,
          reason: DiplomaticRelationChangeReason.declarationOfWar,
          allowDowngrade: false,
        )
        .clearPairPendingActions(playerId, targetPlayerId)
        .adjustRelationScoreWithEntry(
          playerId,
          targetPlayerId,
          -25,
          turn: turn,
          reason: DiplomaticScoreChangeReason.declarationOfWar,
        );
  }

  static DiplomacyState setStatus(
    DiplomacyState state,
    String playerAId,
    String playerBId,
    DiplomaticRelationStatus status, {
    int? turn,
    DiplomaticRelationChangeReason? reason,
    bool allowDowngrade = true,
    int? statusExpiresOnTurn,
  }) {
    if (playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId) {
      return state;
    }

    final key = DiplomacyState.relationKey(playerAId, playerBId);
    final existingRelation = state.relations[key];
    final existing =
        existingRelation ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
    if (!allowDowngrade &&
        _statusSeverity[status]! < _statusSeverity[existing.status]!) {
      return state;
    }
    if (existingRelation != null &&
        existing.status == status &&
        existing.statusExpiresOnTurn == statusExpiresOnTurn) {
      return state;
    }

    final relation = DiplomaticRelation(
      playerAId: existing.playerAId,
      playerBId: existing.playerBId,
      status: status,
      relationScore: existing.relationScore,
      statusExpiresOnTurn: statusExpiresOnTurn,
      lastChangedTurn: turn,
      lastChangeReason: reason,
    );
    final next = Map<String, DiplomaticRelation>.from(state.relations)
      ..[key] = relation;
    return state.copyWith(
      contactKeys: Set.unmodifiable({...state.contactKeys, key}),
      relations: Map.unmodifiable(next),
    );
  }

  static DiplomacyState adjustRelationScore(
    DiplomacyState state,
    String playerAId,
    String playerBId,
    int delta, {
    int? turn,
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) {
    return adjustRelationScoreWithEntry(
      state,
      playerAId,
      playerBId,
      delta,
      turn: turn,
      reason: reason,
      sourceId: sourceId,
    ).state;
  }

  static DiplomaticScoreAdjustment adjustRelationScoreWithEntry(
    DiplomacyState state,
    String playerAId,
    String playerBId,
    int delta, {
    int? turn,
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) {
    if (delta == 0 ||
        playerAId.isEmpty ||
        playerBId.isEmpty ||
        playerAId == playerBId) {
      return DiplomaticScoreAdjustment(state: state, entry: null);
    }
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    final existing =
        state.relations[key] ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
    final score = (existing.relationScore + delta).clamp(
      DiplomacyState.minRelationScore,
      DiplomacyState.maxRelationScore,
    );
    final relation = existing.copyWith(relationScore: score);
    final nextRelations = Map<String, DiplomaticRelation>.from(state.relations)
      ..[key] = relation;
    final entry = DiplomaticScoreEntry.between(
      playerAId: playerAId,
      playerBId: playerBId,
      turn: turn ?? 0,
      delta: score - existing.relationScore,
      scoreAfter: score,
      reason: reason,
      sourceId: sourceId,
    );
    final nextHistory = <String, List<DiplomaticScoreEntry>>{
      for (final historyEntry in state.scoreHistory.entries)
        historyEntry.key: [...historyEntry.value],
    };
    nextHistory.putIfAbsent(key, () => <DiplomaticScoreEntry>[]).add(entry);
    final nextState = state.copyWith(
      contactKeys: Set.unmodifiable({...state.contactKeys, key}),
      relations: Map.unmodifiable(nextRelations),
      scoreHistory: Map.unmodifiable({
        for (final historyEntry in nextHistory.entries)
          historyEntry.key: List<DiplomaticScoreEntry>.unmodifiable(
            historyEntry.value,
          ),
      }),
    );
    return DiplomaticScoreAdjustment(state: nextState, entry: entry);
  }

  static DiplomacyState addContact(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    if (key.isEmpty || state.contactKeys.contains(key)) {
      return state;
    }
    return addContactKeys(state, [key]);
  }

  static DiplomacyState addContactKeys(
    DiplomacyState state,
    Iterable<String> keys,
  ) {
    final next = Set<String>.of(state.contactKeys);
    for (final key in keys) {
      if (_isContactKey(key)) next.add(key);
    }
    if (setEquals(next, state.contactKeys)) return state;
    return state.copyWith(contactKeys: Set.unmodifiable(next));
  }

  static DiplomacyState addProposal(
    DiplomacyState state,
    DiplomaticProposal proposal,
  ) {
    if (proposal.id.isEmpty ||
        proposal.fromPlayerId.isEmpty ||
        proposal.toPlayerId.isEmpty ||
        proposal.fromPlayerId == proposal.toPlayerId) {
      return state;
    }
    final next = Map<String, DiplomaticProposal>.from(state.pendingProposals);
    final duplicate = next.values.any(
      (existing) =>
          existing.fromPlayerId == proposal.fromPlayerId &&
          existing.toPlayerId == proposal.toPlayerId &&
          existing.kind == proposal.kind,
    );
    if (duplicate) return state;
    next[proposal.id] = proposal;
    return state.copyWith(
      contactKeys: Set.unmodifiable({
        ...state.contactKeys,
        DiplomacyState.relationKey(proposal.fromPlayerId, proposal.toPlayerId),
      }),
      pendingProposals: Map.unmodifiable(next),
    );
  }

  static DiplomacyState removeProposal(
    DiplomacyState state,
    String proposalId,
  ) {
    if (!state.pendingProposals.containsKey(proposalId)) {
      return state;
    }
    final next = Map<String, DiplomaticProposal>.from(state.pendingProposals)
      ..remove(proposalId);
    return state.copyWith(pendingProposals: Map.unmodifiable(next));
  }

  static DiplomacyState addMessage(
    DiplomacyState state,
    DiplomaticMessage message,
  ) {
    if (message.id.isEmpty ||
        message.fromPlayerId.isEmpty ||
        message.toPlayerId.isEmpty ||
        message.fromPlayerId == message.toPlayerId) {
      return state;
    }
    final next = Map<String, DiplomaticMessage>.from(state.messages)
      ..[message.id] = message;
    return state.copyWith(
      contactKeys: Set.unmodifiable({
        ...state.contactKeys,
        DiplomacyState.relationKey(message.fromPlayerId, message.toPlayerId),
      }),
      messages: Map.unmodifiable(next),
    );
  }

  static DiplomacyState updateMessage(
    DiplomacyState state,
    DiplomaticMessage message,
  ) {
    if (!state.messages.containsKey(message.id)) return state;
    final next = Map<String, DiplomaticMessage>.from(state.messages)
      ..[message.id] = message;
    return state.copyWith(messages: Map.unmodifiable(next));
  }

  static DiplomacyState removeMessage(DiplomacyState state, String messageId) {
    if (!state.messages.containsKey(messageId)) return state;
    final next = Map<String, DiplomaticMessage>.from(state.messages)
      ..remove(messageId);
    return state.copyWith(messages: Map.unmodifiable(next));
  }

  static DiplomacyState clearPairPendingActions(
    DiplomacyState state,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    if (key.isEmpty) return state;
    final nextProposals = {
      for (final entry in state.pendingProposals.entries)
        if (DiplomacyState.relationKey(
              entry.value.fromPlayerId,
              entry.value.toPlayerId,
            ) !=
            key)
          entry.key: entry.value,
    };
    return state.copyWith(pendingProposals: Map.unmodifiable(nextProposals));
  }
}
