import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_persistence.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'support/fake_multiplayer_database.dart';
import 'support/multiplayer_match_store_fixture.dart';

void main() {
  group('ServerpodMultiplayerMatchStore persistence', () {
    test(
      'creates the match, roster, and initial snapshot atomically',
      () async {
        final database = FakeMultiplayerDatabase()
          ..queueInsertRow<GameMatch>(matchStoreRow());
        final store = ServerpodMultiplayerMatchStore(FakeSession(database));
        final state = StoredMatchState(
          match: matchStoreMatch(),
          snapshot: matchStoreSnapshot(),
        );

        final created = await store.createState(state);

        expect(identical(created, state), isTrue);
        expect(database.callsFor('transaction'), hasLength(1));
        expect(database.callsFor('insertRow').map((call) => call.rowType), [
          GameMatch,
          GameSnapshot,
        ]);
        final rosterInsert = database.callsFor('insert').single;
        expect(rosterInsert.rowType, GamePlayer);
        expect(rosterInsert.rows.single, isA<GamePlayer>());
      },
    );

    test('does not issue a roster insert for an empty match', () async {
      final database = FakeMultiplayerDatabase()
        ..queueInsertRow<GameMatch>(matchStoreRow());
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await store.createState(
        StoredMatchState(
          match: matchStoreMatch(players: const []),
          snapshot: matchStoreSnapshot(),
        ),
      );

      expect(database.callsFor('deleteWhere'), hasLength(1));
      expect(database.callsFor('insert'), isEmpty);
    });

    test('maps the reviewed invite uniqueness violation', () async {
      final database = FakeMultiplayerDatabase()
        ..queueInsertRowError(
          FakeDatabaseQueryException(
            code: '23505',
            constraintName: 'aonw_match_invite_code_idx',
          ),
        );
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await expectLater(
        store.createState(
          StoredMatchState(
            match: matchStoreMatch(inviteCode: 'PRIVATE'),
            snapshot: matchStoreSnapshot(),
          ),
        ),
        throwsA(isA<InviteCodeConflictException>()),
      );
    });

    test('does not hide unrelated database query failures', () async {
      final failure = FakeDatabaseQueryException(
        code: '23505',
        constraintName: 'another_constraint',
      );
      final database = FakeMultiplayerDatabase()..queueInsertRowError(failure);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await expectLater(
        store.createState(
          StoredMatchState(
            match: matchStoreMatch(inviteCode: 'PRIVATE'),
            snapshot: matchStoreSnapshot(),
          ),
        ),
        throwsA(same(failure)),
      );
    });

    test('saves canonical match state, roster, and snapshot', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueUpdateRow<GameMatch>(matchStoreRow(state: 'running'))
        ..queueUnsafeQuery(const [])
        ..queueUnsafeExecute(1)
        ..queueUnsafeExecute(1);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));
      final state = StoredMatchState(
        match: matchStoreMatch(state: 'running'),
        snapshot: matchStoreSnapshot(offset: 7),
      );

      final saved = await store.saveState(state);

      expect(identical(saved, state), isTrue);
      expect(database.callsFor('updateRow').single.rowType, GameMatch);
      expect(database.callsFor('unsafeExecute'), hasLength(2));
    });

    test('appends an event with its idempotency identity', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueUpdateRow<GameMatch>(matchStoreRow(state: 'running'))
        ..queueUnsafeQuery([
          [17, 4],
        ])
        ..queueUnsafeExecute(1)
        ..queueUnsafeExecute(1);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));
      final state = StoredMatchState(
        match: matchStoreMatch(state: 'running'),
        snapshot: matchStoreSnapshot(offset: 5),
      );

      await store.appendEvent(
        state,
        matchStoreEvent(),
        actorPlayerId: 'player-1',
        clientMessageId: 'client-message-1',
      );

      final inserted =
          database
                  .callsFor('insertRow')
                  .singleWhere((call) => call.rowType == GameEvent)
                  .rows
                  .single
              as GameEvent;
      expect(inserted.actorPlayerId, 'player-1');
      expect(inserted.clientMessageId, 'client-message-1');
      expect(inserted.offset, 5);
    });

    test('finds an event by its client message identity', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFindFirst<GameEvent>(matchStoreEventRow());
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final event = await store.findEventByClientMessageId(
        'match-1',
        actorPlayerId: 'player-1',
        clientMessageId: 'message-5',
      );

      expect(event?.offset, 5);
    });
  });

  group('ServerpodMultiplayerMatchStore state loading', () {
    test('loads and maps a complete stored state', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFind<GamePlayer>([matchStorePlayerRow()])
        ..queueFindFirst<GameSnapshot>(matchStoreSnapshotRow());
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      final state = await store.findState('match-1');

      expect(state?.match.players.single.id, 'player-1');
      expect(state?.snapshot.offset, 4);
    });

    test('returns null when a private match does not exist', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(null);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      expect(await store.findPrivateState('UNKNOWN'), isNull);
    });

    test('fails when a match has no authoritative snapshot', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(matchStoreRow())
        ..queueFind<GamePlayer>([matchStorePlayerRow()])
        ..queueFindFirst<GameSnapshot>(null);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await expectLater(store.findState('match-1'), throwsStateError);
    });

    test('applies locks only inside a transaction', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(null)
        ..queueFindFirst<GameMatch>(null);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      expect(await store.findState('missing', lock: true), isNull);
      await store.transaction((transactionStore) async {
        expect(await transactionStore.findState('missing', lock: true), isNull);
        return transactionStore.transaction((nestedStore) async {
          expect(identical(nestedStore, transactionStore), isTrue);
        });
      });

      final calls = database.callsFor('findFirstRow').toList();
      expect(calls.first.lockMode, isNull);
      expect(calls.last.lockMode, LockMode.forUpdate);
      expect(calls.last.lockBehavior, LockBehavior.wait);
      expect(calls.last.transaction, isA<FakeTransaction>());
    });

    test('reports a missing row through dependent queries', () async {
      final database = FakeMultiplayerDatabase()
        ..queueFindFirst<GameMatch>(null);
      final store = ServerpodMultiplayerMatchStore(FakeSession(database));

      await expectLater(store.listEvents('missing', 0), throwsStateError);
    });
  });
}
