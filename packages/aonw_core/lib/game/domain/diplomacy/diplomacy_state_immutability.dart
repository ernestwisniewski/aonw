part of 'diplomacy_state.dart';

DiplomacyState _immutableDiplomacyState({
  required Set<String> contactKeys,
  required Map<String, DiplomaticRelation> relations,
  required Map<String, DiplomaticProposal> pendingProposals,
  required Map<String, DiplomaticMessage> messages,
  required Map<String, List<DiplomaticScoreEntry>> scoreHistory,
}) {
  if (contactKeys.isEmpty &&
      relations.isEmpty &&
      pendingProposals.isEmpty &&
      messages.isEmpty &&
      scoreHistory.isEmpty) {
    return DiplomacyState.empty;
  }
  return DiplomacyState._(
    contactKeys: Set.unmodifiable(contactKeys),
    relations: Map.unmodifiable(relations),
    pendingProposals: Map.unmodifiable(pendingProposals),
    messages: Map.unmodifiable(messages),
    scoreHistory: _immutableDiplomacyScoreHistory(scoreHistory),
  );
}

extension DiplomacyStateCopying on DiplomacyState {
  DiplomacyState copyWith({
    Set<String>? contactKeys,
    Map<String, DiplomaticRelation>? relations,
    Map<String, DiplomaticProposal>? pendingProposals,
    Map<String, DiplomaticMessage>? messages,
    Map<String, List<DiplomaticScoreEntry>>? scoreHistory,
  }) {
    return DiplomacyState._(
      contactKeys: contactKeys == null
          ? this.contactKeys
          : Set.unmodifiable(contactKeys),
      relations: relations == null
          ? this.relations
          : Map.unmodifiable(relations),
      pendingProposals: pendingProposals == null
          ? this.pendingProposals
          : Map.unmodifiable(pendingProposals),
      messages: messages == null ? this.messages : Map.unmodifiable(messages),
      scoreHistory: scoreHistory == null
          ? this.scoreHistory
          : _immutableDiplomacyScoreHistory(scoreHistory),
    );
  }
}

extension DiplomacyStateEmptiness on DiplomacyState {
  bool get isEmpty =>
      contactKeys.isEmpty &&
      relations.isEmpty &&
      pendingProposals.isEmpty &&
      messages.isEmpty &&
      scoreHistory.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

Map<String, List<DiplomaticScoreEntry>> _immutableDiplomacyScoreHistory(
  Map<String, List<DiplomaticScoreEntry>> source,
) {
  if (source.isEmpty) return const {};
  return Map<String, List<DiplomaticScoreEntry>>.unmodifiable({
    for (final entry in source.entries)
      entry.key: List<DiplomaticScoreEntry>.unmodifiable(entry.value),
  });
}
