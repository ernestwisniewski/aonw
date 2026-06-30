part of 'diplomacy_state.dart';

final class _DiplomacyStateJsonParser {
  final Map<Object?, Object?> json;

  const _DiplomacyStateJsonParser(this.json);

  static DiplomacyState from(Object? json) {
    if (json == null) return DiplomacyState.empty;
    if (json is! Map<Object?, Object?>) {
      throw ArgumentError.value(
        json,
        'DiplomacyState',
        'Expected a JSON object',
      );
    }
    return _DiplomacyStateJsonParser(json).parse();
  }

  DiplomacyState parse() {
    if (_containsNoSerializedDiplomacy) return DiplomacyState.empty;

    final contacts = _parseContactKeys();
    final relations = _parseRelations();
    final proposals = _parseProposals();
    final messages = _parseMessages();
    final scoreHistory = _parseScoreHistory();

    if (contacts.isEmpty &&
        relations.isEmpty &&
        proposals.isEmpty &&
        messages.isEmpty &&
        scoreHistory.isEmpty) {
      return DiplomacyState.empty;
    }

    return DiplomacyState(
      contactKeys: Set.unmodifiable(contacts),
      relations: Map.unmodifiable(relations),
      pendingProposals: Map.unmodifiable(proposals),
      messages: Map.unmodifiable(messages),
      scoreHistory: Map.unmodifiable(scoreHistory),
    );
  }

  bool get _containsNoSerializedDiplomacy {
    return json['contacts'] == null &&
        json['relations'] == null &&
        json['pendingProposals'] == null &&
        json['messages'] == null &&
        json['scoreHistory'] == null;
  }

  Set<String> _parseContactKeys() {
    final parsed = <String>{};
    for (final contactJson in _jsonList('contacts')) {
      final key = _contactKeyFromJson(contactJson);
      if (key.isNotEmpty) parsed.add(key);
    }
    return parsed;
  }

  Map<String, DiplomaticRelation> _parseRelations() {
    final parsed = <String, DiplomaticRelation>{};
    for (final relationJson in _jsonList('relations')) {
      final relation = DiplomaticRelation.fromJson(
        _jsonObject(relationJson, 'DiplomacyState.relations[]'),
      );
      if (relation.playerAId == relation.playerBId) continue;
      parsed[relation.key] = relation;
    }
    return parsed;
  }

  Map<String, DiplomaticProposal> _parseProposals() {
    final parsed = <String, DiplomaticProposal>{};
    for (final proposalJson in _jsonList('pendingProposals')) {
      final proposal = DiplomaticProposal.fromJson(
        _jsonObject(proposalJson, 'DiplomacyState.pendingProposals[]'),
      );
      if (proposal.fromPlayerId == proposal.toPlayerId) continue;
      parsed[proposal.id] = proposal;
    }
    return parsed;
  }

  Map<String, DiplomaticMessage> _parseMessages() {
    final parsed = <String, DiplomaticMessage>{};
    for (final messageJson in _jsonList('messages')) {
      final message = DiplomaticMessage.fromJson(
        _jsonObject(messageJson, 'DiplomacyState.messages[]'),
      );
      if (message.fromPlayerId == message.toPlayerId) continue;
      parsed[message.id] = message;
    }
    return parsed;
  }

  Map<String, List<DiplomaticScoreEntry>> _parseScoreHistory() {
    final parsed = <String, List<DiplomaticScoreEntry>>{};
    for (final entryJson in _jsonList('scoreHistory')) {
      final entry = DiplomaticScoreEntry.fromJson(
        _jsonObject(entryJson, 'DiplomacyState.scoreHistory[]'),
      );
      if (entry.playerAId == entry.playerBId) continue;
      parsed.putIfAbsent(entry.key, () => <DiplomaticScoreEntry>[]).add(entry);
    }
    return {
      for (final entry in parsed.entries)
        entry.key: List<DiplomaticScoreEntry>.unmodifiable(
          <DiplomaticScoreEntry>[...entry.value]..sort(_compareScoreEntries),
        ),
    };
  }

  List<Object?> _jsonList(String field) {
    final value = json[field];
    if (value == null) return const <Object?>[];
    if (value is List<dynamic>) return value.cast<Object?>();
    throw ArgumentError.value(
      value,
      'DiplomacyState.$field',
      'Expected a JSON list',
    );
  }

  Map<String, dynamic> _jsonObject(Object? value, String field) {
    return switch (value) {
      final Map<String, dynamic> typed => typed,
      final Map<Object?, Object?> untyped => Map<String, dynamic>.from(untyped),
      _ => throw ArgumentError.value(value, field, 'Expected a JSON object'),
    };
  }
}

String _requiredString(Map<String, dynamic> json, String field) {
  return requiredStringValue(json[field], field);
}

String? _optionalString(Map<String, dynamic> json, String field) {
  return optionalStringValue(json[field], field);
}

int _requiredNonNegativeInt(Object? value, String field) {
  return requiredNonNegativeIntValue(value, field);
}

int? _optionalNonNegativeInt(Object? value, String field) {
  return optionalNonNegativeIntValue(value, field);
}

int? _optionalInt(Object? value, String field) {
  return optionalIntValue(value, field);
}

T _enumValue<T extends Enum>(Object? value, Iterable<T> values, String field) {
  return enumByName(value, values, field);
}

T? _optionalEnumValue<T extends Enum>(
  Object? value,
  Iterable<T> values,
  String field,
) {
  return optionalEnumByName(value, values, field);
}
