import 'package:aonw_core/game/domain/wonder/wonder_type.dart';
import 'package:aonw_core/util/collection_equality.dart';

class WonderRegistry {
  factory WonderRegistry({Map<WonderType, String> completedBy = const {}}) {
    if (completedBy.isEmpty) return empty;
    return WonderRegistry._(completedBy: Map.unmodifiable(completedBy));
  }

  const WonderRegistry._({required this.completedBy});

  static const empty = WonderRegistry._(completedBy: {});

  final Map<WonderType, String> completedBy;

  factory WonderRegistry.fromJson(Object? json) {
    if (json == null) return WonderRegistry.empty;
    if (json is! Map<Object?, Object?>) {
      throw ArgumentError.value(
        json,
        'WonderRegistry',
        'Expected a JSON object',
      );
    }
    return WonderRegistry(
      completedBy: {
        for (final entry in json.entries)
          if (entry.key case final String key)
            WonderType.fromString(key): switch (entry.value) {
              final String playerId when playerId.isNotEmpty => playerId,
              final invalid => throw ArgumentError.value(
                invalid,
                'WonderRegistry.$key',
                'Expected a non-empty String',
              ),
            },
      },
    );
  }

  Map<String, dynamic> toJson() => {
    for (final entry in _sortedEntries()) entry.key.name: entry.value,
  };

  bool isCompleted(WonderType type) => completedBy.containsKey(type);

  String? ownerOf(WonderType type) => completedBy[type];

  WonderRegistry complete({
    required WonderType type,
    required String playerId,
  }) {
    return WonderRegistry(completedBy: {...completedBy, type: playerId});
  }

  Iterable<MapEntry<WonderType, String>> _sortedEntries() {
    final entries = completedBy.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));
    return entries;
  }

  @override
  bool operator ==(Object other) =>
      other is WonderRegistry && mapEquals(other.completedBy, completedBy);

  @override
  int get hashCode => mapHash(completedBy);
}
