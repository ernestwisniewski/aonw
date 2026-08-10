part of 'diplomacy_state.dart';

final class DiplomacyState
    with _DiplomacyStateQueries, _DiplomacyStateMutations {
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
}
