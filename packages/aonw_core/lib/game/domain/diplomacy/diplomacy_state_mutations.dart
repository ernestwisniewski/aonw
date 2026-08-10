part of 'diplomacy_state.dart';

mixin _DiplomacyStateMutations {
  DiplomacyState registerUnitAttack({
    required String attackerPlayerId,
    required String defenderPlayerId,
    int? turn,
  }) {
    return setStatus(
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

  DiplomacyState registerCityAttack({
    required String attackerPlayerId,
    required String defenderPlayerId,
    int? turn,
  }) {
    return setStatus(
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

  DiplomacyState declareWar({
    required String playerId,
    required String targetPlayerId,
    int? turn,
  }) {
    return declareWarWithScoreEntry(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      turn: turn,
    ).state;
  }

  DiplomaticScoreAdjustment declareWarWithScoreEntry({
    required String playerId,
    required String targetPlayerId,
    int? turn,
  }) {
    return setStatus(
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

  DiplomacyState setStatus(
    String playerAId,
    String playerBId,
    DiplomaticRelationStatus status, {
    int? turn,
    DiplomaticRelationChangeReason? reason,
    bool allowDowngrade = true,
    int? statusExpiresOnTurn,
  }) {
    if (playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId) {
      return _stateOf(this);
    }

    final key = _stateRelationKey(playerAId, playerBId);
    final existingRelation = _stateOf(this).relations[key];
    final existing =
        existingRelation ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
    if (!allowDowngrade &&
        _statusSeverity[status]! < _statusSeverity[existing.status]!) {
      return _stateOf(this);
    }
    if (existingRelation != null &&
        existing.status == status &&
        existing.statusExpiresOnTurn == statusExpiresOnTurn) {
      return _stateOf(this);
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
    final next = Map<String, DiplomaticRelation>.from(_stateOf(this).relations)
      ..[key] = relation;
    return _stateOf(this).copyWith(
      contactKeys: Set.unmodifiable({..._stateOf(this).contactKeys, key}),
      relations: Map.unmodifiable(next),
    );
  }

  DiplomacyState adjustRelationScore(
    String playerAId,
    String playerBId,
    int delta, {
    int? turn,
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) {
    return adjustRelationScoreWithEntry(
      playerAId,
      playerBId,
      delta,
      turn: turn,
      reason: reason,
      sourceId: sourceId,
    ).state;
  }

  DiplomaticScoreAdjustment adjustRelationScoreWithEntry(
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
      return DiplomaticScoreAdjustment(state: _stateOf(this), entry: null);
    }
    final key = _stateRelationKey(playerAId, playerBId);
    final existing =
        _stateOf(this).relations[key] ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
    final score = (existing.relationScore + delta).clamp(
      DiplomacyState.minRelationScore,
      DiplomacyState.maxRelationScore,
    );
    final relation = existing.copyWith(relationScore: score);
    final nextRelations = Map<String, DiplomaticRelation>.from(
      _stateOf(this).relations,
    )..[key] = relation;
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
      for (final historyEntry in _stateOf(this).scoreHistory.entries)
        historyEntry.key: [...historyEntry.value],
    };
    nextHistory.putIfAbsent(key, () => <DiplomaticScoreEntry>[]).add(entry);
    final state = _stateOf(this).copyWith(
      contactKeys: Set.unmodifiable({..._stateOf(this).contactKeys, key}),
      relations: Map.unmodifiable(nextRelations),
      scoreHistory: Map.unmodifiable({
        for (final historyEntry in nextHistory.entries)
          historyEntry.key: List<DiplomaticScoreEntry>.unmodifiable(
            historyEntry.value,
          ),
      }),
    );
    return DiplomaticScoreAdjustment(state: state, entry: entry);
  }

  DiplomacyState addContact(String playerAId, String playerBId) {
    final key = _stateRelationKey(playerAId, playerBId);
    if (key.isEmpty || _stateOf(this).contactKeys.contains(key))
      return _stateOf(this);
    return addContactKeys([key]);
  }

  DiplomacyState addContactKeys(Iterable<String> keys) {
    final next = Set<String>.of(_stateOf(this).contactKeys);
    for (final key in keys) {
      if (_isContactKey(key)) next.add(key);
    }
    if (setEquals(next, _stateOf(this).contactKeys)) return _stateOf(this);
    return _stateOf(this).copyWith(contactKeys: Set.unmodifiable(next));
  }

  DiplomacyState addProposal(DiplomaticProposal proposal) {
    if (proposal.id.isEmpty ||
        proposal.fromPlayerId.isEmpty ||
        proposal.toPlayerId.isEmpty ||
        proposal.fromPlayerId == proposal.toPlayerId) {
      return _stateOf(this);
    }
    final next = Map<String, DiplomaticProposal>.from(
      _stateOf(this).pendingProposals,
    );
    final duplicate = next.values.any(
      (existing) =>
          existing.fromPlayerId == proposal.fromPlayerId &&
          existing.toPlayerId == proposal.toPlayerId &&
          existing.kind == proposal.kind,
    );
    if (duplicate) return _stateOf(this);
    next[proposal.id] = proposal;
    return _stateOf(this).copyWith(
      contactKeys: Set.unmodifiable({
        ..._stateOf(this).contactKeys,
        _stateRelationKey(proposal.fromPlayerId, proposal.toPlayerId),
      }),
      pendingProposals: Map.unmodifiable(next),
    );
  }

  DiplomacyState removeProposal(String proposalId) {
    if (!_stateOf(this).pendingProposals.containsKey(proposalId))
      return _stateOf(this);
    final next = Map<String, DiplomaticProposal>.from(
      _stateOf(this).pendingProposals,
    )..remove(proposalId);
    return _stateOf(this).copyWith(pendingProposals: Map.unmodifiable(next));
  }

  DiplomacyState addMessage(DiplomaticMessage message) {
    if (message.id.isEmpty ||
        message.fromPlayerId.isEmpty ||
        message.toPlayerId.isEmpty ||
        message.fromPlayerId == message.toPlayerId) {
      return _stateOf(this);
    }
    final next = Map<String, DiplomaticMessage>.from(_stateOf(this).messages)
      ..[message.id] = message;
    return _stateOf(this).copyWith(
      contactKeys: Set.unmodifiable({
        ..._stateOf(this).contactKeys,
        _stateRelationKey(message.fromPlayerId, message.toPlayerId),
      }),
      messages: Map.unmodifiable(next),
    );
  }

  DiplomacyState updateMessage(DiplomaticMessage message) {
    if (!_stateOf(this).messages.containsKey(message.id)) return _stateOf(this);
    final next = Map<String, DiplomaticMessage>.from(_stateOf(this).messages)
      ..[message.id] = message;
    return _stateOf(this).copyWith(messages: Map.unmodifiable(next));
  }

  DiplomacyState removeMessage(String messageId) {
    if (!_stateOf(this).messages.containsKey(messageId)) return _stateOf(this);
    final next = Map<String, DiplomaticMessage>.from(_stateOf(this).messages)
      ..remove(messageId);
    return _stateOf(this).copyWith(messages: Map.unmodifiable(next));
  }

  DiplomacyState clearPairPendingActions(String playerAId, String playerBId) {
    final key = _stateRelationKey(playerAId, playerBId);
    if (key.isEmpty) return _stateOf(this);
    final nextProposals = {
      for (final entry in _stateOf(this).pendingProposals.entries)
        if (_stateRelationKey(
              entry.value.fromPlayerId,
              entry.value.toPlayerId,
            ) !=
            key)
          entry.key: entry.value,
    };
    return _stateOf(
      this,
    ).copyWith(pendingProposals: Map.unmodifiable(nextProposals));
  }
}
