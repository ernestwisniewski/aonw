import 'package:aonw_core/game/domain/technology.dart';

abstract final class GameResearchStateMigrator {
  static final _technologyIds = TechnologyId.values
      .map((technologyId) => technologyId.name)
      .toSet();

  static Map<String, dynamic> migrate(Map<String, dynamic>? json) {
    final players = json?['players'];
    if (players is! Map) {
      return {'players': <String, dynamic>{}};
    }

    return {
      'players': {
        for (final entry in players.entries)
          if (entry.key is String && entry.value is Map)
            entry.key as String: _migratePlayerResearch(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      },
    };
  }

  static Map<String, dynamic> _migratePlayerResearch(
    Map<String, dynamic> json,
  ) {
    final activeTechnologyId = json['activeTechnologyId'];

    return {
      'unlockedTechnologyIds': _knownTechnologyList(
        json['unlockedTechnologyIds'],
      ),
      if (activeTechnologyId is String &&
          _technologyIds.contains(activeTechnologyId))
        'activeTechnologyId': activeTechnologyId,
      'progressByTechnologyId': _knownProgressMap(
        json['progressByTechnologyId'],
      ),
    };
  }

  static List<String> _knownTechnologyList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && _technologyIds.contains(item)) item,
    ];
  }

  static Map<String, int> _knownProgressMap(Object? value) {
    if (value is! Map) return const {};

    return {
      for (final entry in value.entries)
        if (entry.key is String &&
            _technologyIds.contains(entry.key) &&
            entry.value is num &&
            (entry.value as num).toInt() > 0)
          entry.key as String: (entry.value as num).toInt(),
    };
  }
}
