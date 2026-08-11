part of 'diplomacy_state.dart';

final class DiplomacyState {
  static const empty = DiplomacyState._(
    contactKeys: {},
    relations: {},
    pendingProposals: {},
    messages: {},
    scoreHistory: {},
  );

  static const int minRelationScore = -100;
  static const int maxRelationScore = 100;
  static const int friendlyScoreThreshold = 40;
  static const int hostileScoreThreshold = -40;
  static const int defaultProposalDurationTurns = 5;
  static const int defaultMessageDurationTurns = 5;
  static const int defaultTruceDurationTurns = 10;
  static const int defaultPromiseDurationTurns = 3;
  static const int defaultPromiseBrokenPenalty = -15;

  factory DiplomacyState({
    Set<String> contactKeys = const {},
    Map<String, DiplomaticRelation> relations = const {},
    Map<String, DiplomaticProposal> pendingProposals = const {},
    Map<String, DiplomaticMessage> messages = const {},
    Map<String, List<DiplomaticScoreEntry>> scoreHistory = const {},
  }) => _immutableDiplomacyState(
    contactKeys: contactKeys,
    relations: relations,
    pendingProposals: pendingProposals,
    messages: messages,
    scoreHistory: scoreHistory,
  );

  const DiplomacyState._({
    required this.contactKeys,
    required this.relations,
    required this.pendingProposals,
    required this.messages,
    required this.scoreHistory,
  });

  factory DiplomacyState.fromJson(Object? json) {
    return _DiplomacyStateJsonParser.from(json);
  }

  final Set<String> contactKeys;
  final Map<String, DiplomaticRelation> relations;
  final Map<String, DiplomaticProposal> pendingProposals;
  final Map<String, DiplomaticMessage> messages;
  final Map<String, List<DiplomaticScoreEntry>> scoreHistory;

  bool hasContact(String playerAId, String playerBId) =>
      _DiplomacyStateQueryOperations.hasContact(this, playerAId, playerBId);

  DiplomaticRelation relationBetween(String playerAId, String playerBId) =>
      _DiplomacyStateQueryOperations.relationBetween(
        this,
        playerAId,
        playerBId,
      );

  DiplomaticRelationStatus statusBetween(String playerAId, String playerBId) =>
      _DiplomacyStateQueryOperations.statusBetween(this, playerAId, playerBId);

  int relationScoreBetween(String playerAId, String playerBId) =>
      _DiplomacyStateQueryOperations.relationScoreBetween(
        this,
        playerAId,
        playerBId,
      );

  DiplomaticRelationStatus scoreStatusBetween(
    String playerAId,
    String playerBId,
  ) => _DiplomacyStateQueryOperations.scoreStatusBetween(
    this,
    playerAId,
    playerBId,
  );

  List<DiplomaticProposal> proposalsFor(String playerId) =>
      _DiplomacyStateQueryOperations.proposalsFor(this, playerId);

  List<DiplomaticMessage> messagesFor(String playerId) =>
      _DiplomacyStateQueryOperations.messagesFor(this, playerId);

  List<DiplomaticMessage> messagesBetween(String playerAId, String playerBId) =>
      _DiplomacyStateQueryOperations.messagesBetween(
        this,
        playerAId,
        playerBId,
      );

  List<DiplomaticScoreEntry> scoreEntriesBetween(
    String playerAId,
    String playerBId,
  ) => _DiplomacyStateQueryOperations.scoreEntriesBetween(
    this,
    playerAId,
    playerBId,
  );

  List<DiplomaticProposal> expiredProposals(int turn) =>
      _DiplomacyStateQueryOperations.expiredProposals(this, turn);

  List<DiplomaticMessage> expiredMessages(int turn) =>
      _DiplomacyStateQueryOperations.expiredMessages(this, turn);

  List<DiplomaticRelation> expiredTruces(int turn) =>
      _DiplomacyStateQueryOperations.expiredTruces(this, turn);

  List<DiplomaticMessage> promisesDue(int turn) =>
      _DiplomacyStateQueryOperations.promisesDue(this, turn);

  DiplomacyState registerUnitAttack({
    required String attackerPlayerId,
    required String defenderPlayerId,
    int? turn,
  }) => _DiplomacyStateMutationOperations.registerUnitAttack(
    this,
    attackerPlayerId: attackerPlayerId,
    defenderPlayerId: defenderPlayerId,
    turn: turn,
  );

  DiplomacyState registerCityAttack({
    required String attackerPlayerId,
    required String defenderPlayerId,
    int? turn,
  }) => _DiplomacyStateMutationOperations.registerCityAttack(
    this,
    attackerPlayerId: attackerPlayerId,
    defenderPlayerId: defenderPlayerId,
    turn: turn,
  );

  DiplomacyState declareWar({
    required String playerId,
    required String targetPlayerId,
    int? turn,
  }) => _DiplomacyStateMutationOperations.declareWar(
    this,
    playerId: playerId,
    targetPlayerId: targetPlayerId,
    turn: turn,
  );

  DiplomaticScoreAdjustment declareWarWithScoreEntry({
    required String playerId,
    required String targetPlayerId,
    int? turn,
  }) => _DiplomacyStateMutationOperations.declareWarWithScoreEntry(
    this,
    playerId: playerId,
    targetPlayerId: targetPlayerId,
    turn: turn,
  );

  DiplomacyState setStatus(
    String playerAId,
    String playerBId,
    DiplomaticRelationStatus status, {
    int? turn,
    DiplomaticRelationChangeReason? reason,
    bool allowDowngrade = true,
    int? statusExpiresOnTurn,
  }) => _DiplomacyStateMutationOperations.setStatus(
    this,
    playerAId,
    playerBId,
    status,
    turn: turn,
    reason: reason,
    allowDowngrade: allowDowngrade,
    statusExpiresOnTurn: statusExpiresOnTurn,
  );

  DiplomacyState adjustRelationScore(
    String playerAId,
    String playerBId,
    int delta, {
    int? turn,
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) => _DiplomacyStateMutationOperations.adjustRelationScore(
    this,
    playerAId,
    playerBId,
    delta,
    turn: turn,
    reason: reason,
    sourceId: sourceId,
  );

  DiplomaticScoreAdjustment adjustRelationScoreWithEntry(
    String playerAId,
    String playerBId,
    int delta, {
    int? turn,
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) => _DiplomacyStateMutationOperations.adjustRelationScoreWithEntry(
    this,
    playerAId,
    playerBId,
    delta,
    turn: turn,
    reason: reason,
    sourceId: sourceId,
  );

  DiplomacyState addContact(String playerAId, String playerBId) =>
      _DiplomacyStateMutationOperations.addContact(this, playerAId, playerBId);

  DiplomacyState addContactKeys(Iterable<String> keys) =>
      _DiplomacyStateMutationOperations.addContactKeys(this, keys);

  DiplomacyState addProposal(DiplomaticProposal proposal) =>
      _DiplomacyStateMutationOperations.addProposal(this, proposal);

  DiplomacyState removeProposal(String proposalId) =>
      _DiplomacyStateMutationOperations.removeProposal(this, proposalId);

  DiplomacyState addMessage(DiplomaticMessage message) =>
      _DiplomacyStateMutationOperations.addMessage(this, message);

  DiplomacyState updateMessage(DiplomaticMessage message) =>
      _DiplomacyStateMutationOperations.updateMessage(this, message);

  DiplomacyState removeMessage(String messageId) =>
      _DiplomacyStateMutationOperations.removeMessage(this, messageId);

  DiplomacyState clearPairPendingActions(String playerAId, String playerBId) =>
      _DiplomacyStateMutationOperations.clearPairPendingActions(
        this,
        playerAId,
        playerBId,
      );

  Map<String, dynamic> toJson() => {
    if (contactKeys.isNotEmpty) 'contacts': _sortedContactKeys(this),
    if (relations.isNotEmpty)
      'relations': [
        for (final relation in _sortedRelations(this)) relation.toJson(),
      ],
    if (pendingProposals.isNotEmpty)
      'pendingProposals': [
        for (final proposal in _sortedProposals(this)) proposal.toJson(),
      ],
    if (messages.isNotEmpty)
      'messages': [
        for (final message in _sortedMessages(this)) message.toJson(),
      ],
    if (scoreHistory.isNotEmpty)
      'scoreHistory': [
        for (final entry in _sortedScoreEntries(this)) entry.toJson(),
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
    Object.hashAll(_sortedContactKeys(this)),
    mapHash(relations),
    mapHash(pendingProposals),
    mapHash(messages),
    _historyHash(scoreHistory),
  );

  static String relationKey(String playerAId, String playerBId) {
    return diplomacyRelationKey(playerAId, playerBId);
  }

  static (String, String) normalizedPair(String playerAId, String playerBId) {
    return normalizedDiplomacyPair(playerAId, playerBId);
  }
}
