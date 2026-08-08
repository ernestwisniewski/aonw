import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'support/fake_multiplayer_database.dart';
import 'support/multiplayer_match_store_fixture.dart';

void main() {
  group('ServerpodMultiplayerMatchStore presence', () {
    test('maps an expired lease page to its public match identity', () async {
      final row = matchStorePresenceLeaseRow(
        expiresAt: matchStoreFixtureCreatedAt,
      ).copyWith(match: matchStoreRow());
      final database = FakeMultiplayerDatabase()
        ..queueFind<GameMatchPresenceLease>([row]);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final page = await store.listExpiredPresenceLeases(
        nowUtc: matchStoreFixtureCreatedAt,
      );

      expect(page.candidates, hasLength(1));
      expect(page.candidates.single.matchId, 'match-1');
      expect(page.candidates.single.lease.userIdentifier, 'user-1');
      expect(page.nextCursor, isNull);
    });

    test(
      'renews a lease with CAS under the authoritative match lock',
      () async {
        final now = matchStoreFixtureCreatedAt.add(const Duration(minutes: 10));
        final renewedRow = matchStorePresenceLeaseRow(
          expiresAt: now.add(const Duration(seconds: 30)),
          updatedAt: now,
        );
        final database = FakeMultiplayerDatabase()
          ..queueFindFirst<GameMatch>(matchStoreRow())
          ..queueUpdateWhere<GameMatchPresenceLease>([renewedRow]);
        final store = ServerpodMultiplayerMatchStore(FakeSession(database));

        final renewed = await store.renewPresenceLease(
          matchId: 'match-1',
          userIdentifier: 'user-1',
          connectionGeneration: 'generation-1',
          expiresAt: renewedRow.expiresAt,
          updatedAt: renewedRow.updatedAt,
        );

        expect(renewed, isTrue);
        expect(database.callsFor('transaction'), hasLength(1));
        final lockRead = database.callsFor('findFirstRow').single;
        expect(lockRead.rowType, GameMatch);
        expect(lockRead.lockMode, LockMode.forUpdate);
        expect(lockRead.lockBehavior, LockBehavior.wait);
        expect(
          database.callsFor('updateWhere').single.rowType,
          GameMatchPresenceLease,
        );
        expect(database.callsFor('updateRow'), isEmpty);
        expect(database.callsFor('insert'), isEmpty);
        expect(database.callsFor('unsafeExecute'), isEmpty);
      },
    );

    test('reports a stale generation as an unchanged lease', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueUpdateWhere<GameMatchPresenceLease>(const []);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final renewed = await store.renewPresenceLease(
        matchId: 'match-1',
        userIdentifier: 'user-1',
        connectionGeneration: 'stale-generation',
        expiresAt: matchStoreFixtureCreatedAt.add(const Duration(minutes: 1)),
        updatedAt: matchStoreFixtureCreatedAt,
      );

      expect(renewed, isFalse);
    });
  });
}
