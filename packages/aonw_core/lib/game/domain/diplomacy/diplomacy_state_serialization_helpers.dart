part of 'diplomacy_state.dart';

List<String> _sortedContactKeys(DiplomacyState state) {
  return state.contactKeys.toList()..sort();
}

List<DiplomaticRelation> _sortedRelations(DiplomacyState state) {
  final sorted = state.relations.values.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return sorted;
}

List<DiplomaticProposal> _sortedProposals(DiplomacyState state) {
  final sorted = state.pendingProposals.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return sorted;
}

List<DiplomaticMessage> _sortedMessages(DiplomacyState state) {
  final sorted = state.messages.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return sorted;
}

List<DiplomaticScoreEntry> _sortedScoreEntries(DiplomacyState state) {
  final entries = [for (final list in state.scoreHistory.values) ...list]
    ..sort(_compareScoreEntries);
  return entries;
}

bool _historyEquals(
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

int _historyHash(Map<String, List<DiplomaticScoreEntry>> map) {
  final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, Object.hashAll(entry.value))),
  );
}

String _contactKeyFromJson(Object? value) {
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

bool _isContactKey(String key) {
  final parts = key.split('|');
  return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
}

int _statusSeverity(DiplomaticRelationStatus status) {
  return switch (status) {
    DiplomaticRelationStatus.friendly => 0,
    DiplomaticRelationStatus.neutral => 0,
    DiplomaticRelationStatus.truce => 0,
    DiplomaticRelationStatus.hostile => 1,
    DiplomaticRelationStatus.war => 2,
  };
}

int _compareScoreEntries(DiplomaticScoreEntry a, DiplomaticScoreEntry b) {
  final key = a.key.compareTo(b.key);
  if (key != 0) return key;
  final turn = a.turn.compareTo(b.turn);
  if (turn != 0) return turn;
  return (a.sourceId ?? '').compareTo(b.sourceId ?? '');
}
