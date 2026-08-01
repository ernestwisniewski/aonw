part of 'canonical_game_snapshot_codec.dart';

T? _decodeOptional<T>(Object? value, T Function(Map<String, dynamic>) decode) {
  return value == null ? null : decode(_jsonObject(value));
}

List<T> _decodeJsonList<T>(
  Object? value,
  T Function(Map<String, dynamic>) decode,
) => [for (final entry in _jsonList(value)) decode(_jsonObject(entry))];

Map<String, MapObjectiveHoldState> _decodeObjectiveHolds(Object? value) => {
  for (final hold in _decodeJsonList(value, MapObjectiveHoldState.fromJson))
    hold.objectiveId: hold,
};

FogOfWarState _decodeFogOfWar(Object? value) {
  return switch (value) {
    null => FogOfWarState.empty,
    final List<dynamic> entries => FogOfWarState.fromJson(entries),
    _ => throw FormatException('Invalid fogOfWar: $value'),
  };
}

ResearchState _decodeResearch(Object? value) {
  return switch (value) {
    null => ResearchState.empty,
    final Map<Object?, Object?> entries => ResearchState.fromJson(
      Map<String, dynamic>.from(entries),
    ),
    _ => throw FormatException('Invalid research: $value'),
  };
}

Map<String, dynamic> _jsonObject(Object? value) {
  if (value is Map<Object?, Object?>) return Map<String, dynamic>.from(value);
  throw FormatException('Expected a JSON object, got $value');
}

Map<String, dynamic> _optionalJsonObject(Object? value) {
  return value == null ? const {} : _jsonObject(value);
}

List<dynamic> _jsonList(Object? value) {
  if (value == null) return const [];
  if (value is List<dynamic>) return value;
  throw FormatException('Expected a JSON array, got $value');
}

Map<String, int> _intMap(Object? value) {
  if (value == null) return const {};
  final json = _jsonObject(value);
  return {
    for (final entry in json.entries)
      entry.key: switch (entry.value) {
        final num number when number.toInt() == number => number.toInt(),
        final invalid => throw FormatException(
          'Expected an integer at ${entry.key}, got $invalid',
        ),
      },
  };
}

Map<String, PlayerCountry> _countryMap(Object? value) {
  if (value == null) return const {};
  final json = _jsonObject(value);
  return {
    for (final entry in json.entries)
      entry.key: switch (entry.value) {
        final String name => PlayerCountry.values.byName(name),
        final invalid => throw FormatException(
          'Expected a country name at ${entry.key}, got $invalid',
        ),
      },
  };
}

Set<String> _stringSet(Object? value) {
  return {
    for (final entry in _jsonList(value))
      if (entry is String && entry.isNotEmpty)
        entry
      else
        throw FormatException('Expected a non-empty string, got $entry'),
  };
}

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  if (value case final String source) {
    final parsed = DateTime.tryParse(source);
    if (parsed != null) return parsed.toUtc();
  }
  throw FormatException('Expected an ISO-8601 date, got $value');
}

List<String> _sortedStrings(Iterable<String> values) {
  return values.toList()..sort();
}

Map<String, int> _sortedIntMap(Map<String, int> values) {
  final entries = values.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return {for (final entry in entries) entry.key: entry.value};
}

Map<String, dynamic> _ownedJsonMap(Map<String, dynamic> source) {
  return Map<String, dynamic>.unmodifiable({
    for (final entry in source.entries) entry.key: _ownedJsonValue(entry.value),
  });
}

Object? _ownedJsonValue(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => _ownedJsonMap(map),
    final Map<Object?, Object?> map => _ownedJsonMap(
      Map<String, dynamic>.from(map),
    ),
    final Iterable<Object?> values => List<Object?>.unmodifiable(
      values.map(_ownedJsonValue),
    ),
    _ => value,
  };
}

Map<String, dynamic> _mutableJsonMap(Map<String, dynamic> source) {
  return {
    for (final entry in source.entries)
      entry.key: _mutableJsonValue(entry.value),
  };
}

Object? _mutableJsonValue(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => _mutableJsonMap(map),
    final List<Object?> values => values.map(_mutableJsonValue).toList(),
    _ => value,
  };
}
