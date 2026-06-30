part of 'diplomacy_state.dart';

final class DiplomaticScoreAdjustment {
  const DiplomaticScoreAdjustment({required this.state, required this.entry});

  final DiplomacyState state;
  final DiplomaticScoreEntry? entry;

  bool get applied => entry != null;
}

final class DiplomacyState {
  static const empty = DiplomacyState();

  static const int minRelationScore = -100;
  static const int maxRelationScore = 100;
  static const int friendlyScoreThreshold = 40;
  static const int hostileScoreThreshold = -40;
  static const int defaultProposalDurationTurns = 5;
  static const int defaultMessageDurationTurns = 5;
  static const int defaultTruceDurationTurns = 10;
  static const int defaultPromiseDurationTurns = 3;
  static const int defaultPromiseBrokenPenalty = -15;

  const DiplomacyState({
    this.contactKeys = const {},
    this.relations = const {},
    this.pendingProposals = const {},
    this.messages = const {},
    this.scoreHistory = const {},
  });

  factory DiplomacyState.fromJson(Object? json) {
    return _DiplomacyStateJsonParser.from(json);
  }

  final Set<String> contactKeys;
  final Map<String, DiplomaticRelation> relations;
  final Map<String, DiplomaticProposal> pendingProposals;
  final Map<String, DiplomaticMessage> messages;
  final Map<String, List<DiplomaticScoreEntry>> scoreHistory;

  bool get isEmpty =>
      contactKeys.isEmpty &&
      relations.isEmpty &&
      pendingProposals.isEmpty &&
      messages.isEmpty &&
      scoreHistory.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool hasContact(String playerAId, String playerBId) {
    final key = relationKey(playerAId, playerBId);
    return key.isNotEmpty && contactKeys.contains(key);
  }

  DiplomaticRelation relationBetween(String playerAId, String playerBId) {
    final key = relationKey(playerAId, playerBId);
    final relation = relations[key];
    if (relation != null) return relation;

    return DiplomaticRelation.between(
      playerAId: playerAId,
      playerBId: playerBId,
    );
  }

  DiplomaticRelationStatus statusBetween(String playerAId, String playerBId) {
    if (playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId) {
      return DiplomaticRelationStatus.neutral;
    }
    return relationBetween(playerAId, playerBId).status;
  }

  int relationScoreBetween(String playerAId, String playerBId) {
    if (playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId) {
      return 0;
    }
    return relationBetween(playerAId, playerBId).relationScore;
  }

  DiplomaticRelationStatus scoreStatusBetween(
    String playerAId,
    String playerBId,
  ) {
    final score = relationScoreBetween(playerAId, playerBId);
    if (score >= friendlyScoreThreshold) {
      return DiplomaticRelationStatus.friendly;
    }
    if (score <= hostileScoreThreshold) return DiplomaticRelationStatus.hostile;
    return DiplomaticRelationStatus.neutral;
  }

  List<DiplomaticProposal> proposalsFor(String playerId) {
    final proposals = [
      for (final proposal in pendingProposals.values)
        if (proposal.involves(playerId)) proposal,
    ]..sort((a, b) => a.createdTurn.compareTo(b.createdTurn));
    return List.unmodifiable(proposals);
  }

  List<DiplomaticMessage> messagesFor(String playerId) {
    final result = [
      for (final message in messages.values)
        if (message.involves(playerId)) message,
    ]..sort((a, b) => b.createdTurn.compareTo(a.createdTurn));
    return List.unmodifiable(result);
  }

  List<DiplomaticMessage> messagesBetween(String playerAId, String playerBId) {
    final result = [
      for (final message in messages.values)
        if (relationKey(message.fromPlayerId, message.toPlayerId) ==
            relationKey(playerAId, playerBId))
          message,
    ]..sort((a, b) => b.createdTurn.compareTo(a.createdTurn));
    return List.unmodifiable(result);
  }

  List<DiplomaticScoreEntry> scoreEntriesBetween(
    String playerAId,
    String playerBId,
  ) {
    final entries = scoreHistory[relationKey(playerAId, playerBId)];
    if (entries == null) return const [];
    return entries;
  }

  List<DiplomaticProposal> expiredProposals(int turn) {
    final expired = [
      for (final proposal in pendingProposals.values)
        if (proposal.isExpired(turn)) proposal,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(expired);
  }

  List<DiplomaticMessage> expiredMessages(int turn) {
    final expired = [
      for (final message in messages.values)
        if (message.isExpired(turn)) message,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(expired);
  }

  List<DiplomaticRelation> expiredTruces(int turn) {
    final expired = [
      for (final relation in relations.values)
        if (relation.status == DiplomaticRelationStatus.truce &&
            relation.statusExpiresOnTurn != null &&
            turn >= relation.statusExpiresOnTurn!)
          relation,
    ]..sort((a, b) => a.key.compareTo(b.key));
    return List.unmodifiable(expired);
  }

  List<DiplomaticMessage> promisesDue(int turn) {
    final due = [
      for (final message in messages.values)
        if (message.hasActivePromise &&
            message.promiseDueTurn != null &&
            turn >= message.promiseDueTurn!)
          message,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(due);
  }

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
      return this;
    }

    final key = relationKey(playerAId, playerBId);
    final existingRelation = relations[key];
    final existing =
        existingRelation ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
    if (!allowDowngrade &&
        _statusSeverity(status) < _statusSeverity(existing.status)) {
      return this;
    }
    if (existingRelation != null &&
        existing.status == status &&
        existing.statusExpiresOnTurn == statusExpiresOnTurn) {
      return this;
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
    final next = Map<String, DiplomaticRelation>.from(relations)
      ..[key] = relation;
    return copyWith(
      contactKeys: Set.unmodifiable({...contactKeys, key}),
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
      return DiplomaticScoreAdjustment(state: this, entry: null);
    }
    final key = relationKey(playerAId, playerBId);
    final existing =
        relations[key] ??
        DiplomaticRelation.between(playerAId: playerAId, playerBId: playerBId);
    final score = (existing.relationScore + delta).clamp(
      minRelationScore,
      maxRelationScore,
    );
    final relation = existing.copyWith(relationScore: score);
    final nextRelations = Map<String, DiplomaticRelation>.from(relations)
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
      for (final historyEntry in scoreHistory.entries)
        historyEntry.key: [...historyEntry.value],
    };
    nextHistory.putIfAbsent(key, () => <DiplomaticScoreEntry>[]).add(entry);
    final state = copyWith(
      contactKeys: Set.unmodifiable({...contactKeys, key}),
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
    final key = relationKey(playerAId, playerBId);
    if (key.isEmpty || contactKeys.contains(key)) return this;
    return addContactKeys([key]);
  }

  DiplomacyState addContactKeys(Iterable<String> keys) {
    final next = Set<String>.of(contactKeys);
    for (final key in keys) {
      if (_isContactKey(key)) next.add(key);
    }
    if (setEquals(next, contactKeys)) return this;
    return copyWith(contactKeys: Set.unmodifiable(next));
  }

  DiplomacyState addProposal(DiplomaticProposal proposal) {
    if (proposal.id.isEmpty ||
        proposal.fromPlayerId.isEmpty ||
        proposal.toPlayerId.isEmpty ||
        proposal.fromPlayerId == proposal.toPlayerId) {
      return this;
    }
    final next = Map<String, DiplomaticProposal>.from(pendingProposals);
    final duplicate = next.values.any(
      (existing) =>
          existing.fromPlayerId == proposal.fromPlayerId &&
          existing.toPlayerId == proposal.toPlayerId &&
          existing.kind == proposal.kind,
    );
    if (duplicate) return this;
    next[proposal.id] = proposal;
    return copyWith(
      contactKeys: Set.unmodifiable({
        ...contactKeys,
        relationKey(proposal.fromPlayerId, proposal.toPlayerId),
      }),
      pendingProposals: Map.unmodifiable(next),
    );
  }

  DiplomacyState removeProposal(String proposalId) {
    if (!pendingProposals.containsKey(proposalId)) return this;
    final next = Map<String, DiplomaticProposal>.from(pendingProposals)
      ..remove(proposalId);
    return copyWith(pendingProposals: Map.unmodifiable(next));
  }

  DiplomacyState addMessage(DiplomaticMessage message) {
    if (message.id.isEmpty ||
        message.fromPlayerId.isEmpty ||
        message.toPlayerId.isEmpty ||
        message.fromPlayerId == message.toPlayerId) {
      return this;
    }
    final next = Map<String, DiplomaticMessage>.from(messages)
      ..[message.id] = message;
    return copyWith(
      contactKeys: Set.unmodifiable({
        ...contactKeys,
        relationKey(message.fromPlayerId, message.toPlayerId),
      }),
      messages: Map.unmodifiable(next),
    );
  }

  DiplomacyState updateMessage(DiplomaticMessage message) {
    if (!messages.containsKey(message.id)) return this;
    final next = Map<String, DiplomaticMessage>.from(messages)
      ..[message.id] = message;
    return copyWith(messages: Map.unmodifiable(next));
  }

  DiplomacyState removeMessage(String messageId) {
    if (!messages.containsKey(messageId)) return this;
    final next = Map<String, DiplomaticMessage>.from(messages)
      ..remove(messageId);
    return copyWith(messages: Map.unmodifiable(next));
  }

  DiplomacyState clearPairPendingActions(String playerAId, String playerBId) {
    final key = relationKey(playerAId, playerBId);
    if (key.isEmpty) return this;
    final nextProposals = {
      for (final entry in pendingProposals.entries)
        if (relationKey(entry.value.fromPlayerId, entry.value.toPlayerId) !=
            key)
          entry.key: entry.value,
    };
    return copyWith(pendingProposals: Map.unmodifiable(nextProposals));
  }

  DiplomacyState copyWith({
    Set<String>? contactKeys,
    Map<String, DiplomaticRelation>? relations,
    Map<String, DiplomaticProposal>? pendingProposals,
    Map<String, DiplomaticMessage>? messages,
    Map<String, List<DiplomaticScoreEntry>>? scoreHistory,
  }) {
    return DiplomacyState(
      contactKeys: contactKeys ?? this.contactKeys,
      relations: relations ?? this.relations,
      pendingProposals: pendingProposals ?? this.pendingProposals,
      messages: messages ?? this.messages,
      scoreHistory: scoreHistory ?? this.scoreHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    if (contactKeys.isNotEmpty) 'contacts': _sortedContactKeys(),
    if (relations.isNotEmpty)
      'relations': [
        for (final relation in _sortedRelations()) relation.toJson(),
      ],
    if (pendingProposals.isNotEmpty)
      'pendingProposals': [
        for (final proposal in _sortedProposals()) proposal.toJson(),
      ],
    if (messages.isNotEmpty)
      'messages': [for (final message in _sortedMessages()) message.toJson()],
    if (scoreHistory.isNotEmpty)
      'scoreHistory': [
        for (final entry in _sortedScoreEntries()) entry.toJson(),
      ],
  };

  @override
  bool operator ==(Object other) =>
      other is DiplomacyState &&
      setEquals(other.contactKeys, contactKeys) &&
      mapEquals(other.relations, relations) &&
      mapEquals(other.pendingProposals, pendingProposals) &&
      mapEquals(other.messages, messages) &&
      _historyEquals(other.scoreHistory, scoreHistory);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_sortedContactKeys()),
    mapHash(relations),
    mapHash(pendingProposals),
    mapHash(messages),
    _historyHash(scoreHistory),
  );

  static String relationKey(String playerAId, String playerBId) {
    if (playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId) {
      return '';
    }
    final pair = normalizedPair(playerAId, playerBId);
    return '${Uri.encodeComponent(pair.$1)}|${Uri.encodeComponent(pair.$2)}';
  }

  static (String, String) normalizedPair(String playerAId, String playerBId) {
    return playerAId.compareTo(playerBId) <= 0
        ? (playerAId, playerBId)
        : (playerBId, playerAId);
  }

  List<String> _sortedContactKeys() => contactKeys.toList()..sort();

  List<DiplomaticRelation> _sortedRelations() {
    final sorted = relations.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted;
  }

  List<DiplomaticProposal> _sortedProposals() {
    final sorted = pendingProposals.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted;
  }

  List<DiplomaticMessage> _sortedMessages() {
    final sorted = messages.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted;
  }

  List<DiplomaticScoreEntry> _sortedScoreEntries() {
    final entries = [for (final list in scoreHistory.values) ...list]
      ..sort(_compareScoreEntries);
    return entries;
  }

  static bool _historyEquals(
    Map<String, List<DiplomaticScoreEntry>> a,
    Map<String, List<DiplomaticScoreEntry>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || other.length != entry.value.length) return false;
      for (var i = 0; i < entry.value.length; i++) {
        if (entry.value[i] != other[i]) return false;
      }
    }
    return true;
  }

  static int _historyHash(Map<String, List<DiplomaticScoreEntry>> map) {
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Object.hashAll(
      entries.map(
        (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
      ),
    );
  }

  static String _contactKeyFromJson(Object? value) {
    if (value is String) {
      if (_isContactKey(value)) return value;
      throw ArgumentError.value(
        value,
        'DiplomacyState.contacts[]',
        'Expected a diplomatic contact key',
      );
    }
    throw ArgumentError.value(
      value,
      'DiplomacyState.contacts[]',
      'Expected a diplomatic contact key',
    );
  }

  static bool _isContactKey(String key) {
    final parts = key.split('|');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
  }

  static int _statusSeverity(DiplomaticRelationStatus status) {
    return switch (status) {
      DiplomaticRelationStatus.friendly => 0,
      DiplomaticRelationStatus.neutral => 0,
      DiplomaticRelationStatus.truce => 0,
      DiplomaticRelationStatus.hostile => 1,
      DiplomaticRelationStatus.war => 2,
    };
  }

  static int _compareScoreEntries(
    DiplomaticScoreEntry a,
    DiplomaticScoreEntry b,
  ) {
    final key = a.key.compareTo(b.key);
    if (key != 0) return key;
    final turn = a.turn.compareTo(b.turn);
    if (turn != 0) return turn;
    return (a.sourceId ?? '').compareTo(b.sourceId ?? '');
  }
}
