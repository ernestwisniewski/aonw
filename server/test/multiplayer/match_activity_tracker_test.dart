import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/match_activity_tracker.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  test('records, preserves and expires human match activity', () {
    final createdAt = DateTime.utc(2026, 8, 1);
    const tracker = MatchActivityTracker();
    final initial = StoredMatchState(
      match: WireMatch(
        id: 'match-activity',
        ownerUserId: 'user-1',
        name: 'Activity match',
        mapName: 'verdantia',
        players: const [],
        maxPlayers: 2,
        minPlayers: 2,
        quickplay: false,
        turn: 1,
        state: 'running',
        createdAt: createdAt,
      ),
      snapshot: const WireSnapshot(
        matchId: 'match-activity',
        offset: 0,
        save: {},
        state: {},
      ),
    );
    final activityAt = createdAt.add(const Duration(hours: 2));
    final recorded = tracker.record(initial, activityAt);
    final preserved = tracker.preserveActivity(
      recorded.snapshot,
      recorded.snapshot.copyWith(state: {'phase': 'running'}),
    );
    final state = recorded.copyWith(snapshot: preserved);

    expect(
      state.snapshot.state['lastHumanActivityAt'],
      activityAt.toIso8601String(),
    );
    expect(
      tracker.hasExpired(
        state,
        nowUtc: activityAt.add(
          const Duration(hours: 11, minutes: 59, seconds: 59),
        ),
        timeout: defaultMultiplayerMatchInactivityTimeout,
      ),
      isFalse,
    );
    expect(
      tracker.hasExpired(
        state,
        nowUtc: activityAt.add(defaultMultiplayerMatchInactivityTimeout),
        timeout: defaultMultiplayerMatchInactivityTimeout,
      ),
      isTrue,
    );
  });
}
