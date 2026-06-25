import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/util/collection_equality.dart';

class PlayerResearchState {
  static const empty = PlayerResearchState._(
    unlockedTechnologyIds: <TechnologyId>{},
    activeTechnologyId: null,
    progressByTechnologyId: <TechnologyId, int>{},
    scienceOverflow: 0,
  );

  final Set<TechnologyId> unlockedTechnologyIds;
  final TechnologyId? activeTechnologyId;
  final Map<TechnologyId, int> progressByTechnologyId;
  final int scienceOverflow;

  factory PlayerResearchState({
    Set<TechnologyId> unlockedTechnologyIds = const {},
    TechnologyId? activeTechnologyId,
    Map<TechnologyId, int> progressByTechnologyId = const {},
    int scienceOverflow = 0,
  }) {
    return PlayerResearchState._(
      unlockedTechnologyIds: Set.unmodifiable(unlockedTechnologyIds),
      activeTechnologyId: activeTechnologyId,
      progressByTechnologyId: Map.unmodifiable(progressByTechnologyId),
      scienceOverflow: scienceOverflow < 0 ? 0 : scienceOverflow,
    );
  }

  const PlayerResearchState._({
    required this.unlockedTechnologyIds,
    required this.activeTechnologyId,
    required this.progressByTechnologyId,
    required this.scienceOverflow,
  });

  factory PlayerResearchState.fromJson(Map<String, dynamic> json) {
    final unlocked = (json['unlockedTechnologyIds'] as List<dynamic>)
        .map((value) => TechnologyId.fromString(value as String))
        .toSet();
    final progressJson = json['progressByTechnologyId'] as Map<String, dynamic>;
    final progress = progressJson.map(
      (key, value) =>
          MapEntry(TechnologyId.fromString(key), (value as num).toInt()),
    );
    final activeRaw = json['activeTechnologyId'] as String?;
    final overflow = switch (json['scienceOverflow']) {
      final num value => value.toInt(),
      _ => 0,
    };

    return PlayerResearchState(
      unlockedTechnologyIds: unlocked,
      activeTechnologyId: activeRaw != null
          ? TechnologyId.fromString(activeRaw)
          : null,
      progressByTechnologyId: progress,
      scienceOverflow: overflow,
    );
  }

  Map<String, dynamic> toJson() => {
    'unlockedTechnologyIds': unlockedTechnologyIds.map((id) => id.name).toList()
      ..sort(),
    if (activeTechnologyId != null)
      'activeTechnologyId': activeTechnologyId!.name,
    'progressByTechnologyId': {
      for (final entry in _sortedProgressEntries()) entry.key.name: entry.value,
    },
    if (scienceOverflow > 0) 'scienceOverflow': scienceOverflow,
  };

  bool hasUnlocked(TechnologyId id) => unlockedTechnologyIds.contains(id);

  int progressFor(TechnologyId id) => progressByTechnologyId[id] ?? 0;

  PlayerResearchState unlock(TechnologyId id) {
    final unlocked = {...unlockedTechnologyIds, id};
    final progress = Map<TechnologyId, int>.of(progressByTechnologyId)
      ..remove(id);
    return PlayerResearchState(
      unlockedTechnologyIds: unlocked,
      activeTechnologyId: activeTechnologyId == id ? null : activeTechnologyId,
      progressByTechnologyId: progress,
      scienceOverflow: scienceOverflow,
    );
  }

  PlayerResearchState withActiveTechnology(TechnologyId? id) {
    return PlayerResearchState(
      unlockedTechnologyIds: unlockedTechnologyIds,
      activeTechnologyId: id,
      progressByTechnologyId: progressByTechnologyId,
      scienceOverflow: scienceOverflow,
    );
  }

  PlayerResearchState withProgress(TechnologyId id, int progress) {
    final nextProgress = Map<TechnologyId, int>.of(progressByTechnologyId);
    if (progress <= 0) {
      nextProgress.remove(id);
    } else {
      nextProgress[id] = progress;
    }
    return PlayerResearchState(
      unlockedTechnologyIds: unlockedTechnologyIds,
      activeTechnologyId: activeTechnologyId,
      progressByTechnologyId: nextProgress,
      scienceOverflow: scienceOverflow,
    );
  }

  PlayerResearchState withScienceOverflow(int overflow) {
    return PlayerResearchState(
      unlockedTechnologyIds: unlockedTechnologyIds,
      activeTechnologyId: activeTechnologyId,
      progressByTechnologyId: progressByTechnologyId,
      scienceOverflow: overflow,
    );
  }

  Iterable<MapEntry<TechnologyId, int>> _sortedProgressEntries() {
    final entries = progressByTechnologyId.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));
    return entries;
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerResearchState &&
      setEquals(other.unlockedTechnologyIds, unlockedTechnologyIds) &&
      other.activeTechnologyId == activeTechnologyId &&
      mapEquals(other.progressByTechnologyId, progressByTechnologyId) &&
      other.scienceOverflow == scienceOverflow;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_sortedIds(unlockedTechnologyIds)),
    activeTechnologyId,
    Object.hashAll(
      _sortedProgressEntries().map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
    scienceOverflow,
  );

  static List<TechnologyId> _sortedIds(Set<TechnologyId> ids) {
    return ids.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}
