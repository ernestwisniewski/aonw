import 'package:aonw_server/src/multiplayer/multiplayer_match_store_snapshots.dart';
import 'package:test/test.dart';

import 'support/fake_multiplayer_database.dart';
import 'support/multiplayer_match_store_fixture.dart';

void main() {
  group('MultiplayerMatchSnapshotStore', () {
    test(
      'inserts the first authoritative snapshot and prunes older rows',
      () async {
        final database = FakeMultiplayerDatabase()
          ..queueUnsafeQuery(const [])
          ..queueUnsafeExecute(1)
          ..queueUnsafeExecute(1);
        final store = MultiplayerMatchSnapshotStore(
          FakeSession(database),
          null,
        );

        await store.saveLatest(7, matchStoreSnapshot(offset: 4));

        final writes = database.callsFor('unsafeExecute').toList();
        expect(writes, hasLength(2));
        expect(writes.first.query, contains('INSERT INTO'));
        expect(writes.last.query, contains('DELETE FROM'));
        expect(writes.first.parameters, containsPair('matchId', 7));
        expect(writes.first.parameters, containsPair('offset', 4));
      },
    );

    test(
      'updates the latest snapshot monotonically in one transaction',
      () async {
      const transaction = FakeTransaction();
        final database = FakeMultiplayerDatabase()
          ..queueUnsafeQuery([
            [17, 3],
          ])
          ..queueUnsafeExecute(1)
          ..queueUnsafeExecute(1);
        final store = MultiplayerMatchSnapshotStore(
          FakeSession(database),
          transaction,
        );

        await store.saveLatest(7, matchStoreSnapshot(offset: 4));

        final writes = database.callsFor('unsafeExecute').toList();
        expect(writes.first.query, contains('UPDATE'));
        expect(writes.first.parameters, containsPair('snapshotId', 17));
        expect(writes.every((call) => call.transaction == transaction), isTrue);
      },
    );

    test('rejects a snapshot older than the persisted offset', () async {
      final database = FakeMultiplayerDatabase()
        ..queueUnsafeQuery([
          [17, 8],
        ]);
      final store = MultiplayerMatchSnapshotStore(FakeSession(database), null);

      await expectLater(
        store.saveLatest(7, matchStoreSnapshot(offset: 7)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('stale offset 7'),
          ),
        ),
      );
      expect(database.callsFor('unsafeExecute'), isEmpty);
    });

    test('fails closed when the first snapshot is not inserted', () async {
      final database = FakeMultiplayerDatabase()
        ..queueUnsafeQuery(const [])
        ..queueUnsafeExecute(0);
      final store = MultiplayerMatchSnapshotStore(FakeSession(database), null);

      await expectLater(
        store.saveLatest(7, matchStoreSnapshot()),
        throwsStateError,
      );
    });

    test(
      'fails closed when the latest snapshot changed concurrently',
      () async {
        final database = FakeMultiplayerDatabase()
          ..queueUnsafeQuery([
            [17, 3],
          ])
          ..queueUnsafeExecute(0);
        final store = MultiplayerMatchSnapshotStore(
          FakeSession(database),
          null,
        );

        await expectLater(
          store.saveLatest(7, matchStoreSnapshot()),
          throwsStateError,
        );
      },
    );
  });
}
