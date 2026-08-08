import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_limits.dart';
import 'package:test/test.dart';

import 'support/fake_multiplayer_database.dart';
import 'support/multiplayer_match_store_fixture.dart';

void main() {
  group('ServerpodMultiplayerMatchStore queries', () {
    test('merges participant and public matches without duplicates', () async {
      final database = FakeMultiplayerDatabase();
      final participant = matchStoreRow(
        publicId: 'participant',
        players: [matchStorePlayerRow()],
      );
      final public = matchStoreRow(
        id: 8,
        publicId: 'public',
        players: [matchStorePlayerRow(matchId: 8)],
        presenceLeases: [matchStorePresenceLeaseRow(id: 32, matchId: 8)],
        quickplay: false,
      );
      database
        ..queueFind<GameMatch>([participant])
        ..queueFind<GameMatch>([public, participant]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final matches = await store.listVisibleMatches(
        'user-1',
        nowUtc: matchStoreFixtureCreatedAt,
      );

      expect(matches.map((match) => match.id), ['participant', 'public']);
      expect(database.callsFor('find'), hasLength(2));
    });

    test('excludes public lobbies whose owner lease has expired', () async {
      final database = FakeMultiplayerDatabase();
      final live = matchStoreRow(
        id: 8,
        publicId: 'live',
        players: [matchStorePlayerRow(matchId: 8)],
        presenceLeases: [matchStorePresenceLeaseRow(id: 32, matchId: 8)],
        quickplay: false,
      );
      final expired = matchStoreRow(
        id: 9,
        publicId: 'expired',
        players: [matchStorePlayerRow(id: 12, matchId: 9)],
        presenceLeases: [
          matchStorePresenceLeaseRow(
            id: 33,
            matchId: 9,
            expiresAt: matchStoreFixtureCreatedAt,
          ),
        ],
        quickplay: false,
      );
      database
        ..queueFind<GameMatch>([])
        ..queueFind<GameMatch>([live, expired]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final matches = await store.listVisibleMatches(
        'viewer',
        nowUtc: matchStoreFixtureCreatedAt,
      );

      expect(matches.map((match) => match.id), ['live']);
    });

    test('hides a public lobby until an expired guest is swept', () async {
      final database = FakeMultiplayerDatabase();
      final lobby = matchStoreRow(
        id: 8,
        publicId: 'stale-guest',
        players: [
          matchStorePlayerRow(matchId: 8),
          matchStorePlayerRow(
            id: 12,
            matchId: 8,
            publicPlayerId: 'player-2',
            userIdentifier: 'user-2',
            seatOrder: 1,
          ),
        ],
        presenceLeases: [
          matchStorePresenceLeaseRow(id: 32, matchId: 8),
          matchStorePresenceLeaseRow(
            id: 33,
            matchId: 8,
            userIdentifier: 'user-2',
            expiresAt: matchStoreFixtureCreatedAt,
          ),
        ],
        quickplay: false,
      );
      database
        ..queueFind<GameMatch>([])
        ..queueFind<GameMatch>([lobby]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final matches = await store.listVisibleMatches(
        'viewer',
        nowUtc: matchStoreFixtureCreatedAt,
      );

      expect(matches, isEmpty);
    });

    test('selects the first quickplay candidate with a free seat', () async {
      final database = FakeMultiplayerDatabase();
      final full = matchStoreRow(publicId: 'full', maxPlayers: 1);
      final available = matchStoreRow(id: 8, publicId: 'available');
      database
        ..queueFind<GameMatch>([full, available])
        ..queueFind<GamePlayer>([matchStorePlayerRow()])
        ..queueFind<GamePlayer>([matchStorePlayerRow(matchId: 8)])
        ..queueFindFirst<GameSnapshot>(matchStoreSnapshotRow())
        ..queueFindFirst<GameSnapshot>(matchStoreSnapshotRow(matchId: 8));
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final state = await store.findOpenQuickplayCandidate(
        CreateMatchRequest(
          name: 'Quickplay',
          mapName: 'verdantia',
          maxPlayers: 4,
          minPlayers: 2,
          private: false,
        ),
      );

      expect(state?.match.id, 'available');
      expect(state?.snapshot.offset, 4);
    });

    test('returns null when the quickplay scan is empty', () async {
      final database = FakeMultiplayerDatabase()..queueFind<GameMatch>([]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final state = await store.findOpenQuickplayCandidate(
        CreateMatchRequest(
          name: 'Quickplay',
          mapName: 'verdantia',
          maxPlayers: 4,
          minPlayers: 2,
          private: false,
        ),
      );

      expect(state, isNull);
    });

    test('loads the requested bounded event page', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFind<GameEvent>([
          matchStoreEventRow(offset: 5),
          matchStoreEventRow(offset: 6),
        ]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final events = await store.listEvents('match-1', 4);

      expect(events.map((event) => event.offset), [5, 6]);
    });

    test('pages running states and skips an incompatible roster', () async {
      final database = FakeMultiplayerDatabase();
      final rows = <GameMatch>[];
      for (var index = 0; index <= multiplayerRunningMatchPageSize; index++) {
        final matchId = index + 1;
        rows.add(
          matchStoreRow(
            id: matchId,
            publicId: 'match-$matchId',
            state: 'running',
            createdAt: matchStoreFixtureCreatedAt.add(Duration(minutes: index)),
            players: [
              matchStorePlayerRow(
                id: 100 + index,
                matchId: matchId,
                countryId: index == 0 ? 'unsupported-country' : 'poland',
              ),
            ],
            snapshots: [
              matchStoreSnapshotRow(
                id: 200 + index,
                matchId: matchId,
                offset: index,
                snapshot: matchStoreSnapshot(
                  offset: index,
                  matchId: 'match-$matchId',
                ),
              ),
            ],
          ),
        );
      }
      database.queueFind<GameMatch>(rows);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));
      final after = RunningMatchCursor(
        createdAt: matchStoreFixtureCreatedAt.subtract(const Duration(days: 1)),
        publicId: 'before',
      );

      final page = await store.listRunningStates(after: after);

      expect(page.states, hasLength(multiplayerRunningMatchPageSize - 1));
      expect(
        page.nextCursor,
        RunningMatchCursor(
          createdAt: rows[multiplayerRunningMatchPageSize - 1].createdAt,
          publicId: rows[multiplayerRunningMatchPageSize - 1].publicId,
        ),
      );
      expect(page.nextCursor.hashCode, page.nextCursor.hashCode);
    });

    test('fails closed when a running match has no snapshot', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFind<GameMatch>([
          matchStoreRow(
            state: 'running',
            players: [matchStorePlayerRow()],
            snapshots: const [],
          ),
        ]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await expectLater(store.listRunningStates(), throwsStateError);
    });
  });
}
