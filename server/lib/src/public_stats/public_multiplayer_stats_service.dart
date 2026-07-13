import 'package:aonw_server/src/public_stats/public_multiplayer_stats.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats_store.dart';

const publicMultiplayerStatsWindowDays = 30;
const publicMultiplayerStatsCacheTtl = Duration(seconds: 30);

final class PublicMultiplayerStatsService {
  PublicMultiplayerStatsService({
    DateTime Function()? nowUtc,
    this.windowDays = publicMultiplayerStatsWindowDays,
    this.cacheTtl = publicMultiplayerStatsCacheTtl,
  }) : _nowUtc = nowUtc ?? _systemNowUtc;

  static const _outcomeConditions = [
    'conquest',
    'domination',
    'cultural',
    'score',
    'draw',
    'resignation',
  ];
  static const _turnDistributionLabels = [
    '1–10',
    '11–25',
    '26–50',
    '51–100',
    '101+',
  ];

  final DateTime Function() _nowUtc;
  final int windowDays;
  final Duration cacheTtl;
  Future<PublicMultiplayerStats>? _cached;
  DateTime? _cachedAt;

  Future<PublicMultiplayerStats> snapshot(PublicMultiplayerStatsStore store) {
    final now = _nowUtc().toUtc();
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < cacheTtl) {
      return cached;
    }
    final next = _loadAndResetOnFailure(store, now);
    _cached = next;
    _cachedAt = now;
    return next;
  }

  Future<PublicMultiplayerStats> _loadAndResetOnFailure(
    PublicMultiplayerStatsStore store,
    DateTime generatedAt,
  ) async {
    try {
      return await _load(store, generatedAt);
    } catch (_) {
      if (_cachedAt == generatedAt) {
        _cached = null;
        _cachedAt = null;
      }
      rethrow;
    }
  }

  Future<PublicMultiplayerStats> _load(
    PublicMultiplayerStatsStore store,
    DateTime generatedAt,
  ) async {
    final today = DateTime.utc(
      generatedAt.year,
      generatedAt.month,
      generatedAt.day,
    );
    final start = today.subtract(Duration(days: windowDays - 1));
    final end = today.add(const Duration(days: 1));
    final stored = await store.loadSnapshot(
      startInclusive: start,
      endExclusive: end,
    );
    final overview = stored.overview;
    final storedActivity = stored.activity;
    final storedOutcomes = stored.outcomes;
    final activityByDate = {
      for (final point in storedActivity) _dateKey(point.date): point,
    };
    final outcomeCounts = <String, int>{};
    for (final outcome in storedOutcomes) {
      final publicCondition = _outcomeConditions.contains(outcome.condition)
          ? outcome.condition
          : 'unknown';
      outcomeCounts.update(
        publicCondition,
        (count) => count + outcome.count,
        ifAbsent: () => outcome.count,
      );
    }
    final unknownOutcomeCount = outcomeCounts['unknown'] ?? 0;

    return PublicMultiplayerStats(
      generatedAt: generatedAt,
      windowDays: windowDays,
      totals: PublicMultiplayerTotals(
        activeSessions: overview.activeSessions,
        openLobbies: overview.openLobbies,
        matchesStarted: overview.matchesStarted,
        matchesCompleted: overview.matchesCompleted,
        matchesAbandoned: overview.matchesAbandoned,
      ),
      activity: [
        for (var dayOffset = 0; dayOffset < windowDays; dayOffset += 1)
          _activityPoint(start.add(Duration(days: dayOffset)), activityByDate),
      ],
      outcomes: [
        for (final condition in [
          ..._outcomeConditions,
          if (unknownOutcomeCount > 0) 'unknown',
        ])
          PublicMultiplayerOutcomeCount(
            condition: condition,
            count: outcomeCounts[condition] ?? 0,
          ),
      ],
      turns: PublicMultiplayerTurnStats(
        averageCompleted: overview.averageCompletedTurns,
        longestCompleted: overview.longestCompletedTurns,
        totalPlayed: overview.totalPlayedTurns,
        distribution: [
          for (final label in _turnDistributionLabels)
            PublicMultiplayerTurnDistributionPoint(
              label: label,
              count: overview.completedTurnDistribution[label] ?? 0,
            ),
        ],
      ),
    );
  }

  PublicMultiplayerActivityPoint _activityPoint(
    DateTime date,
    Map<String, PublicMultiplayerDailyActivity> activityByDate,
  ) {
    final key = _dateKey(date);
    final stored = activityByDate[key];
    return PublicMultiplayerActivityPoint(
      date: key,
      started: stored?.started ?? 0,
      completed: stored?.completed ?? 0,
    );
  }

  static DateTime _systemNowUtc() => DateTime.now().toUtc();

  String _dateKey(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
