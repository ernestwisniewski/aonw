abstract final class GameFogOfWarStateMigrator {
  static List<Map<String, dynamic>> migrate(Object? json) {
    if (json is! List) return const [];

    return [
      for (final entry in json)
        if (entry is Map && _isNonEmptyString(entry['playerId']))
          {
            'playerId': entry['playerId'],
            'discoveredHexes': _migrateHexes(entry['discoveredHexes']),
          },
    ];
  }

  static List<Map<String, int>> _migrateHexes(Object? json) {
    if (json is! List) return const [];

    return [
      for (final entry in json)
        if (entry is Map && entry['col'] is num && entry['row'] is num)
          {
            'col': (entry['col'] as num).toInt(),
            'row': (entry['row'] as num).toInt(),
          },
    ];
  }

  static bool _isNonEmptyString(Object? value) {
    return value is String && value.isNotEmpty;
  }
}
