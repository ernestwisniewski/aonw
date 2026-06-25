part of 'game_runtime_state.dart';

typedef _RuntimeJsonObjectMapper<T> = T Function(Map<String, dynamic> json);

Set<String> _readStringSet(Object? value, String field) {
  if (value == null) return const {};
  if (value is! List) {
    throw ArgumentError.value(
      value,
      'GameRuntimeState.$field',
      'Expected a JSON list',
    );
  }
  final result = <String>{};
  for (final entry in value) {
    if (entry is String && entry.isNotEmpty) {
      result.add(entry);
      continue;
    }
    throw ArgumentError.value(
      entry,
      'GameRuntimeState.$field[]',
      'Expected a non-empty String',
    );
  }
  return Set.unmodifiable(result);
}

int _stringSetHash(Set<String> values) {
  final sorted = [...values]..sort();
  return Object.hashAll(sorted);
}

Map<String, int> _readNonNegativeIntMap(Object? value, String field) {
  if (value == null) return const {};
  if (value is! Map<Object?, Object?>) {
    throw ArgumentError.value(
      value,
      'GameRuntimeState.$field',
      'Expected a JSON object',
    );
  }
  final result = <String, int>{};
  for (final entry in value.entries) {
    final key = entry.key;
    final rawValue = entry.value;
    if (key is! String || key.isEmpty) {
      throw ArgumentError.value(
        key,
        'GameRuntimeState.$field',
        'Expected a non-empty String key',
      );
    }
    if (rawValue is! num || rawValue < 0) {
      throw ArgumentError.value(
        rawValue,
        'GameRuntimeState.$field.$key',
        'Expected a non-negative integer',
      );
    }
    final intValue = rawValue.toInt();
    if (intValue != rawValue) {
      throw ArgumentError.value(
        rawValue,
        'GameRuntimeState.$field.$key',
        'Expected an integer',
      );
    }
    if (intValue > 0) result[key] = intValue;
  }
  return Map.unmodifiable(result);
}

Map<String, int> _sortedIntMap(Map<String, int> map) {
  final entries = map.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return {for (final entry in entries) entry.key: entry.value};
}

int _intMapHash(Map<String, int> map) {
  final entries = map.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

Map<String, MapObjectiveHoldState> _readMapObjectiveHoldStates(Object? value) {
  final result = <String, MapObjectiveHoldState>{};
  for (final hold in _readJsonObjectList(
    value,
    'mapObjectiveHoldStates',
    MapObjectiveHoldState.fromJson,
  )) {
    result[hold.objectiveId] = hold;
  }
  return Map.unmodifiable(result);
}

List<Map<String, dynamic>> _sortedMapObjectiveHoldStates(
  Map<String, MapObjectiveHoldState> map,
) {
  final entries = map.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return [for (final entry in entries) entry.value.toJson()];
}

bool _mapObjectiveHoldStateMapEquals(
  Map<String, MapObjectiveHoldState> a,
  Map<String, MapObjectiveHoldState> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapObjectiveHoldStateMapHash(Map<String, MapObjectiveHoldState> map) {
  final entries = map.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

List<ResourceTradeAgreement> _readResourceTradeAgreements(Object? value) {
  return _readJsonObjectList(
    value,
    'resourceTradeAgreements',
    ResourceTradeAgreement.fromJson,
  );
}

List<Map<String, dynamic>> _sortedResourceTradeAgreements(
  Iterable<ResourceTradeAgreement> agreements,
) {
  final sorted = agreements.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return [for (final agreement in sorted) agreement.toJson()];
}

List<IntendedAttack> _readIntendedAttacks(Object? value) {
  return _readJsonObjectList(value, 'intendedAttacks', IntendedAttack.fromJson);
}

List<T> _readJsonObjectList<T>(
  Object? value,
  String field,
  _RuntimeJsonObjectMapper<T> mapObject,
) {
  if (value == null) return const [];
  if (value is! List) {
    throw ArgumentError.value(
      value,
      'GameRuntimeState.$field',
      'Expected a JSON list',
    );
  }
  return List.unmodifiable([
    for (final entry in value) mapObject(_readJsonObject(entry, field)),
  ]);
}

Map<String, dynamic> _readJsonObject(Object? value, String field) {
  return switch (value) {
    final Map<String, dynamic> json => json,
    final Map<Object?, Object?> json => Map<String, dynamic>.from(json),
    _ => throw ArgumentError.value(
      value,
      'GameRuntimeState.$field[]',
      'Expected a JSON object',
    ),
  };
}

DateTime? _readOptionalUtcDateTime(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw ArgumentError.value(
      value,
      'GameRuntimeState.turnStartedAt',
      'Expected an ISO-8601 date string',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw ArgumentError.value(
      value,
      'GameRuntimeState.turnStartedAt',
      'Expected an ISO-8601 date string',
    );
  }
  return parsed.toUtc();
}
