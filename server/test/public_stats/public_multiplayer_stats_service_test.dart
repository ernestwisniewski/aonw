import 'dart:convert';

import 'package:aonw_server/src/public_stats/public_multiplayer_stats_service.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats_store.dart';
import 'package:test/test.dart';

void main() {
  test(
    'builds the stable public contract and zero-fills the UTC window',
    () async {
      var now = DateTime.utc(2026, 7, 12, 14, 30);
      final store = _FakeStatsStore(
        overview: const PublicMultiplayerStatsOverview(
          activeSessions: 3,
          openLobbies: 2,
          matchesStarted: 11,
          matchesCompleted: 7,
          matchesAbandoned: 1,
          averageCompletedTurns: 42.5,
          longestCompletedTurns: 121,
          totalPlayedTurns: 378,
          completedTurnDistribution: {
            '1–10': 1,
            '11–25': 2,
            '26–50': 3,
            '51–100': 0,
            '101+': 1,
          },
        ),
        activity: [
          PublicMultiplayerDailyActivity(
            date: DateTime.utc(2026, 6, 13),
            started: 2,
            completed: 1,
          ),
          PublicMultiplayerDailyActivity(
            date: DateTime.utc(2026, 7, 12),
            started: 1,
            completed: 0,
          ),
        ],
        outcomes: const [
          PublicMultiplayerStoredOutcome(condition: 'conquest', count: 4),
          PublicMultiplayerStoredOutcome(condition: 'unknown', count: 1),
          PublicMultiplayerStoredOutcome(
            condition: 'internal-experiment-alpha',
            count: 2,
          ),
          PublicMultiplayerStoredOutcome(
            condition: 'internal-experiment-beta',
            count: 3,
          ),
        ],
      );
      final service = PublicMultiplayerStatsService(nowUtc: () => now);

      final stats = await service.snapshot(store);
      final json = stats.toJson();
      final activity = json['activity']! as List<Object?>;
      final outcomes = json['outcomes']! as List<Object?>;
      final turns = json['turns']! as Map<String, Object>;

      expect(json['schemaVersion'], 1);
      expect(json['generatedAt'], '2026-07-12T14:30:00.000Z');
      expect(json['windowDays'], 30);
      expect(activity, hasLength(30));
      expect(activity.first, {
        'date': '2026-06-13',
        'started': 2,
        'completed': 1,
      });
      expect(activity[1], {'date': '2026-06-14', 'started': 0, 'completed': 0});
      expect(activity.last, {
        'date': '2026-07-12',
        'started': 1,
        'completed': 0,
      });
      expect(
        activity.whereType<Map<String, Object>>(),
        everyElement(isNot(contains('abandoned'))),
      );
      expect(outcomes, [
        {'condition': 'conquest', 'count': 4},
        {'condition': 'domination', 'count': 0},
        {'condition': 'cultural', 'count': 0},
        {'condition': 'score', 'count': 0},
        {'condition': 'draw', 'count': 0},
        {'condition': 'resignation', 'count': 0},
        {'condition': 'unknown', 'count': 6},
      ]);
      expect(
        outcomes
            .whereType<Map<String, Object>>()
            .map((outcome) => outcome['count']! as int)
            .fold<int>(0, (total, count) => total + count),
        10,
        reason: 'Collapsing unknown labels must preserve the total count.',
      );
      expect(turns, {
        'averageCompleted': 42.5,
        'longestCompleted': 121,
        'totalPlayed': 378,
        'distribution': [
          {'label': '1–10', 'count': 1},
          {'label': '11–25', 'count': 2},
          {'label': '26–50', 'count': 3},
          {'label': '51–100', 'count': 0},
          {'label': '101+', 'count': 1},
        ],
      });
      expect(jsonEncode(json), isNot(contains('userIdentifier')));
      expect(jsonEncode(json), isNot(contains('email')));
      expect(jsonEncode(json), isNot(contains('internal-experiment')));

      final cached = await service.snapshot(store);
      expect(identical(stats, cached), isTrue);
      expect(store.snapshotLoads, 1);

      now = now.add(const Duration(seconds: 31));
      await service.snapshot(store);
      expect(store.snapshotLoads, 2);
    },
  );

  test(
    'empty storage still returns all chart points and outcome categories',
    () async {
      final store = _FakeStatsStore(
        overview: const PublicMultiplayerStatsOverview(
          activeSessions: 0,
          openLobbies: 0,
          matchesStarted: 0,
          matchesCompleted: 0,
          matchesAbandoned: 0,
          averageCompletedTurns: 0,
          longestCompletedTurns: 0,
          totalPlayedTurns: 0,
          completedTurnDistribution: {},
        ),
        activity: const [],
        outcomes: const [],
      );

      final stats = await PublicMultiplayerStatsService(
        nowUtc: () => DateTime.utc(2026, 7, 12),
      ).snapshot(store);

      expect(stats.activity, hasLength(30));
      expect(stats.activity.every((point) => point.started == 0), isTrue);
      expect(stats.activity.every((point) => point.completed == 0), isTrue);
      expect(stats.outcomes.map((outcome) => outcome.condition), [
        'conquest',
        'domination',
        'cultural',
        'score',
        'draw',
        'resignation',
      ]);
      expect(
        stats.turns.distribution.map((point) => point.count),
        everyElement(0),
      );
    },
  );
}

final class _FakeStatsStore implements PublicMultiplayerStatsStore {
  _FakeStatsStore({
    required this.overview,
    required this.activity,
    required this.outcomes,
  });

  final PublicMultiplayerStatsOverview overview;
  final List<PublicMultiplayerDailyActivity> activity;
  final List<PublicMultiplayerStoredOutcome> outcomes;
  int snapshotLoads = 0;

  @override
  Future<PublicMultiplayerStoredSnapshot> loadSnapshot({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    snapshotLoads += 1;
    expect(startInclusive, DateTime.utc(2026, 6, 13));
    expect(endExclusive, DateTime.utc(2026, 7, 13));
    return PublicMultiplayerStoredSnapshot(
      overview: overview,
      activity: activity,
      outcomes: outcomes,
    );
  }
}
