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

    test('paginates expired leases after the exact durable cursor', () async {
      const pageSize = 64;
      final rows = [
        for (var index = 0; index <= pageSize; index++)
          matchStorePresenceLeaseRow(
            id: index + 1,
            expiresAt: matchStoreFixtureCreatedAt,
          ).copyWith(match: matchStoreRow()),
      ];
      final database = FakeMultiplayerDatabase()
        ..queueFind<GameMatchPresenceLease>(rows);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final page = await store.listExpiredPresenceLeases(
        nowUtc: matchStoreFixtureCreatedAt,
        after: ExpiredPresenceLeaseCursor(
          expiresAt: matchStoreFixtureCreatedAt,
          rowId: 0,
        ),
      );

      expect(page.candidates, hasLength(pageSize));
      expect(page.nextCursor?.expiresAt, matchStoreFixtureCreatedAt);
      expect(page.nextCursor?.rowId, pageSize);
    });

    test('inserts and then updates a durable presence lease', () async {
      final insertedLease = StoredMatchPresenceLease(
        userIdentifier: 'user-1',
        connectionGeneration: 'generation-1',
        expiresAt: matchStoreFixtureCreatedAt.add(const Duration(seconds: 30)),
        updatedAt: matchStoreFixtureCreatedAt,
      );
      final insertDatabase = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFindFirst<GameMatchPresenceLease>(null);
      final insertStore = ServerpodMultiplayerMatchStore(
        FakeSession(insertDatabase),
      );

      await insertStore.upsertPresenceLease(
        matchId: 'match-1',
        lease: insertedLease,
      );

      final inserted =
          insertDatabase.callsFor('insertRow').single.rows.single
              as GameMatchPresenceLease;
      expect(inserted.connectionGeneration, 'generation-1');
      expect(inserted.expiresAt, insertedLease.expiresAt);

      final existing = matchStorePresenceLeaseRow();
      final updatedLease = insertedLease.copyWith(
        connectionGeneration: 'generation-2',
        expiresAt: insertedLease.expiresAt.add(const Duration(seconds: 30)),
        updatedAt: insertedLease.updatedAt.add(const Duration(seconds: 1)),
      );
      final updateDatabase = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFindFirst<GameMatchPresenceLease>(existing);
      final updateStore = ServerpodMultiplayerMatchStore(
        FakeSession(updateDatabase),
      );

      await updateStore.upsertPresenceLease(
        matchId: 'match-1',
        lease: updatedLease,
      );

      final updated =
          updateDatabase.callsFor('updateRow').single.rows.single
              as GameMatchPresenceLease;
      expect(updated.connectionGeneration, 'generation-2');
      expect(updated.expiresAt, updatedLease.expiresAt);
      expect(updated.updatedAt, updatedLease.updatedAt);
    });

    test('deletes one or every durable lease for a match', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFindFirst<GameMatch>(matchStoreRow());
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await store.deletePresenceLease(
        matchId: 'match-1',
        userIdentifier: 'user-1',
      );
      await store.deletePresenceLeases('match-1');

      final deletes = database.callsFor('deleteWhere').toList();
      expect(deletes, hasLength(2));
      expect(
        deletes.map((call) => call.rowType),
        everyElement(GameMatchPresenceLease),
      );
    });

    test('presence lease copy keeps identity and replaces timestamps', () {
      final lease = StoredMatchPresenceLease(
        userIdentifier: 'user-1',
        connectionGeneration: 'generation-1',
        expiresAt: matchStoreFixtureCreatedAt,
        updatedAt: matchStoreFixtureCreatedAt,
      );
      final expiresAt = matchStoreFixtureCreatedAt.add(
        const Duration(minutes: 1),
      );
      final updatedAt = matchStoreFixtureCreatedAt.add(
        const Duration(seconds: 1),
      );

      final updated = lease.copyWith(
        connectionGeneration: 'generation-2',
        expiresAt: expiresAt,
        updatedAt: updatedAt,
      );

      expect(updated.userIdentifier, 'user-1');
      expect(updated.connectionGeneration, 'generation-2');
      expect(updated.expiresAt, expiresAt);
      expect(updated.updatedAt, updatedAt);
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
