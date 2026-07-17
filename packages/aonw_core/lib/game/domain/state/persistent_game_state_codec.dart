part of 'persistent_game_state.dart';

Map<String, int> _intMap(Object? value, String field) {
  if (value == null) return const {};
  if (value is! Map<Object?, Object?>) {
    throw ArgumentError.value(
      value,
      'PersistentGameState.$field',
      'Expected a JSON object',
    );
  }
  return {
    for (final entry in value.entries)
      if (entry.key case final String key when key.isNotEmpty)
        key: switch (entry.value) {
          final int number => number,
          final num number => number.toInt(),
          final invalid => throw ArgumentError.value(
            invalid,
            'PersistentGameState.$field.$key',
            'Expected a number',
          ),
        },
  };
}

Map<String, PlayerCountry> _countryMap(Object? value, String field) {
  if (value == null) return const {};
  if (value is! Map<Object?, Object?>) {
    throw ArgumentError.value(
      value,
      'PersistentGameState.$field',
      'Expected a JSON object',
    );
  }
  return {
    for (final entry in value.entries)
      if (entry.key case final String key when key.isNotEmpty)
        key: _countryFromJson(entry.value, '$field.$key'),
  };
}

PlayerCountry _countryFromJson(Object? value, String field) {
  if (value is! String || value.isEmpty) {
    throw ArgumentError.value(
      value,
      'PersistentGameState.$field',
      'Expected a non-empty String',
    );
  }
  for (final country in PlayerCountry.values) {
    if (country.name == value) return country;
  }
  throw ArgumentError.value(
    value,
    'PersistentGameState.$field',
    'Unknown country',
  );
}

List<Map<String, dynamic>> _jsonList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) {
    throw ArgumentError.value(
      value,
      'PersistentGameState.$field',
      'Expected a JSON list',
    );
  }
  return [
    for (final entry in value)
      if (entry is Map<String, dynamic>)
        entry
      else if (entry is Map<Object?, Object?>)
        Map<String, dynamic>.from(entry)
      else
        throw ArgumentError.value(
          entry,
          'PersistentGameState.$field[]',
          'Expected a JSON object',
        ),
  ];
}
