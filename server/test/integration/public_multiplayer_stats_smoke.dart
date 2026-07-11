import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats_service.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Public multiplayer stats', (sessionBuilder, endpoints) {
    tearDown(() async {
      await sessionBuilder.build().db.unsafeExecute(
        '''DELETE FROM "aonw_match" WHERE "publicId" LIKE 'stats-%' ''',
      );
    });

    test(
      'aggregates lifecycle and turn columns without snapshot JSON',
      () async {
        final session = sessionBuilder.build();
        final now = DateTime.utc(2026, 7, 12, 12);
        await GameMatch.db.insert(session, [
          _match('open', state: 'open', turn: 0, createdAt: now),
          _match(
            'running-one',
            state: 'running',
            turn: 4,
            createdAt: now,
            startedAt: DateTime.utc(2026, 7, 10, 9),
          ),
          _match(
            'running-two',
            state: 'running',
            turn: 11,
            createdAt: now,
            startedAt: DateTime.utc(2026, 7, 11, 9),
          ),
          _match(
            'completed',
            state: 'finished',
            turn: 26,
            createdAt: now,
            startedAt: DateTime.utc(2026, 7, 10, 10),
            endedAt: DateTime.utc(2026, 7, 12, 10),
            outcomeCondition: 'conquest',
            winnerPlayerId: 'public-player-one',
          ),
          _match(
            'abandoned-started',
            state: 'abandoned',
            turn: 60,
            createdAt: now,
            startedAt: DateTime.utc(2026, 7, 9, 10),
            endedAt: DateTime.utc(2026, 7, 11, 10),
          ),
          _match(
            'legacy-finished-lobby',
            state: 'finished',
            turn: 80,
            createdAt: now,
            endedAt: DateTime.utc(2026, 7, 12, 11),
          ),
          _match(
            'abandoned-lobby',
            state: 'abandoned',
            turn: 0,
            createdAt: now,
            endedAt: DateTime.utc(2026, 7, 12, 11),
          ),
        ]);

        final stats = await PublicMultiplayerStatsService(
          nowUtc: () => now,
        ).snapshot(ServerpodPublicMultiplayerStatsStore(session));

        expect(stats.totals.activeSessions, 2);
        expect(stats.totals.openLobbies, 1);
        expect(stats.totals.matchesStarted, 4);
        expect(stats.totals.matchesCompleted, 1);
        expect(stats.totals.matchesAbandoned, 1);
        expect(stats.turns.averageCompleted, 26);
        expect(stats.turns.longestCompleted, 26);
        expect(stats.turns.totalPlayed, 101);
        expect(stats.turns.distribution.map((point) => point.count), [
          0,
          0,
          1,
          0,
          0,
        ]);
        expect(
          stats.outcomes
              .singleWhere((outcome) => outcome.condition == 'conquest')
              .count,
          1,
        );
        final today = stats.activity.singleWhere(
          (point) => point.date == '2026-07-12',
        );
        expect(today.started, 0);
        expect(today.completed, 1);
        expect(
          stats.activity.every(
            (point) => !point.toJson().containsKey('abandoned'),
          ),
          isTrue,
        );
      },
    );

    test(
      'keeps cross-section invariants during concurrent match transitions',
      () async {
        final now = DateTime.utc(2026, 7, 12, 12);
        final setupSession = sessionBuilder.build();
        final service = PublicMultiplayerStatsService(
          nowUtc: () => now,
          cacheTtl: Duration.zero,
        );
        final baseline = await service.snapshot(
          ServerpodPublicMultiplayerStatsStore(setupSession),
        );
        await GameMatch.db.insertRow(
          setupSession,
          _match(
            'concurrent-snapshot',
            state: 'running',
            turn: 4,
            createdAt: now.subtract(const Duration(days: 2)),
            startedAt: now.subtract(const Duration(days: 1)),
          ),
        );

        final running = _relativeSignature(
          await service.snapshot(
            ServerpodPublicMultiplayerStatsStore(setupSession),
          ),
          baseline,
        );
        expect(running, _runningSignature);

        final writerSession = sessionBuilder.build();
        final readerSession = sessionBuilder.build();
        final observed = <_StatsSignature>{running};
        final writes = () async {
          for (var transition = 0; transition < 80; transition += 1) {
            final finishes = transition.isEven;
            await writerSession.db.unsafeExecute(
              finishes
                  ? '''
UPDATE "aonw_match"
SET "state" = 'finished',
    "turn" = 26,
    "endedAt" = @endedAt,
    "outcomeCondition" = 'conquest',
    "winnerPlayerId" = 'stats-winner'
WHERE "publicId" = 'stats-concurrent-snapshot'
'''
                  : '''
UPDATE "aonw_match"
SET "state" = 'running',
    "turn" = 4,
    "endedAt" = NULL,
    "outcomeCondition" = NULL,
    "winnerPlayerId" = NULL
WHERE "publicId" = 'stats-concurrent-snapshot'
''',
              parameters: finishes
                  ? QueryParameters.named({'endedAt': now})
                  : null,
            );
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
        }();
        final reads = () async {
          for (var read = 0; read < 120; read += 1) {
            final current = _relativeSignature(
              await service.snapshot(
                ServerpodPublicMultiplayerStatsStore(readerSession),
              ),
              baseline,
            );
            expect(
              current,
              anyOf(_runningSignature, _finishedSignature),
              reason:
                  'Every response must describe either the complete running '
                  'state or the complete finished state.',
            );
            observed.add(current);
            await Future<void>.delayed(Duration.zero);
          }
        }();

        await Future.wait([writes, reads]);
        expect(observed, contains(_runningSignature));
        expect(observed, contains(_finishedSignature));
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}

typedef _StatsSignature = ({
  int active,
  int started,
  int completed,
  int conquest,
  int turns26To50,
  int totalTurns,
  int completedToday,
});

const _runningSignature = (
  active: 1,
  started: 1,
  completed: 0,
  conquest: 0,
  turns26To50: 0,
  totalTurns: 4,
  completedToday: 0,
);

const _finishedSignature = (
  active: 0,
  started: 1,
  completed: 1,
  conquest: 1,
  turns26To50: 1,
  totalTurns: 26,
  completedToday: 1,
);

_StatsSignature _relativeSignature(
  PublicMultiplayerStats current,
  PublicMultiplayerStats baseline,
) {
  int outcome(PublicMultiplayerStats stats, String condition) =>
      stats.outcomes.singleWhere((point) => point.condition == condition).count;
  int distribution(PublicMultiplayerStats stats, String label) => stats
      .turns
      .distribution
      .singleWhere((point) => point.label == label)
      .count;
  int completedToday(PublicMultiplayerStats stats) => stats.activity
      .singleWhere((point) => point.date == '2026-07-12')
      .completed;

  return (
    active: current.totals.activeSessions - baseline.totals.activeSessions,
    started: current.totals.matchesStarted - baseline.totals.matchesStarted,
    completed:
        current.totals.matchesCompleted - baseline.totals.matchesCompleted,
    conquest: outcome(current, 'conquest') - outcome(baseline, 'conquest'),
    turns26To50:
        distribution(current, '26–50') - distribution(baseline, '26–50'),
    totalTurns: current.turns.totalPlayed - baseline.turns.totalPlayed,
    completedToday: completedToday(current) - completedToday(baseline),
  );
}

GameMatch _match(
  String id, {
  required String state,
  required int turn,
  required DateTime createdAt,
  DateTime? startedAt,
  DateTime? endedAt,
  String? outcomeCondition,
  String? winnerPlayerId,
}) {
  return GameMatch(
    publicId: 'stats-$id',
    ownerUserIdentifier: 'private-owner-$id',
    name: 'Stats $id',
    mapName: 'verdantia',
    state: state,
    turn: turn,
    maxPlayers: 2,
    minPlayers: 2,
    private: false,
    quickplay: false,
    createdAt: createdAt,
    startedAt: startedAt,
    endedAt: endedAt,
    outcomeCondition: outcomeCondition,
    winnerPlayerId: winnerPlayerId,
  );
}
