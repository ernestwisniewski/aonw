import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:serverpod/serverpod.dart' show QueryParameters;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'MultiplayerEndpoint',
    (sessionBuilder, endpoints) {
      test(
        'rejects unauthenticated calls through Serverpod dispatch',
        () async {
          await expectLater(
            endpoints.multiplayer.listMatches(sessionBuilder),
            throwsA(isA<ServerpodUnauthenticatedException>()),
          );
        },
      );

      test('rejects duplicate multiplayer nicknames', () async {
        _ensureAuthServices();
        await endpoints.emailIdp.createAccount(
          sessionBuilder,
          email: 'alice-one@example.test',
          password: 'long-password',
          displayName: 'Alice',
        );

        await expectLater(
          endpoints.emailIdp.createAccount(
            sessionBuilder,
            email: 'alice-two@example.test',
            password: 'long-password',
            displayName: ' alice ',
          ),
          throwsA(
            isA<AccountAuthException>().having(
              (error) => error.code,
              'code',
              'display_name_taken',
            ),
          ),
        );
      });

      test('updates multiplayer nickname uniquely', () async {
        final owner = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'owner-update@example.test',
          displayName: 'Owner Before',
        );
        await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'guest-update@example.test',
          displayName: 'Guest Taken',
        );

        final saved = await endpoints.emailIdp.updateDisplayName(
          owner.session,
          displayName: 'Owner After',
        );
        expect(saved, 'Owner After');

        await expectLater(
          endpoints.emailIdp.updateDisplayName(
            owner.session,
            displayName: ' guest taken ',
          ),
          throwsA(
            isA<AccountAuthException>().having(
              (error) => error.code,
              'code',
              'display_name_taken',
            ),
          ),
        );
      });

      test('lists lobby metadata without deserializing its snapshot', () async {
        final owner = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'listing-owner@example.test',
          displayName: 'Listing Owner',
        );
        final guest = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'listing-guest@example.test',
          displayName: 'Listing Guest',
        );
        final viewer = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'listing-viewer@example.test',
          displayName: 'Listing Viewer',
        );
        final created = await endpoints.multiplayer.createMatch(
          owner.session,
          CreateMatchRequest(
            name: 'Snapshot-independent listing',
            mapName: 'myranth',
            maxPlayers: 2,
            minPlayers: 2,
            private: false,
          ),
        );
        final joined = await endpoints.multiplayer.joinMatch(
          guest.session,
          created.id,
        );

        final databaseSession = sessionBuilder.build();
        final persistedMatch = await GameMatch.db.findFirstRow(
          databaseSession,
          where: (table) => table.publicId.equals(joined.id),
        );
        expect(persistedMatch, isNotNull);
        final affectedRows = await databaseSession.db.unsafeExecute('''
UPDATE "aonw_snapshot"
SET "snapshot" = jsonb_set(
  "snapshot"::jsonb,
  '{v}',
  '999'::jsonb
)::json
WHERE "matchId" = @matchId
''', parameters: QueryParameters.named({'matchId': persistedMatch!.id!}));
        expect(affectedRows, 1);

        final listed = await endpoints.multiplayer.listMatches(viewer.session);
        final listedMatch = listed.singleWhere(
          (match) => match.id == joined.id,
        );
        expect(
          listedMatch.players.every((player) => player.userId == player.id),
          isTrue,
        );
        expect(listedMatch.ownerUserId, listedMatch.players.first.id);
      });

      test(
        'merges relation-backed participant and public match queries',
        () async {
          final session = sessionBuilder.build();
          const viewer = 'relation-list-viewer';
          const stranger = 'relation-list-stranger';
          final baseTime = DateTime.utc(2026, 7, 10);
          final specs = [
            (
              id: 'relation-private-viewer',
              user: viewer,
              state: 'open',
              isPrivate: true,
              inviteCode: 'RELATIONPRIVATE',
              age: 0,
            ),
            (
              id: 'relation-public-viewer',
              user: viewer,
              state: 'open',
              isPrivate: false,
              inviteCode: null,
              age: 1,
            ),
            (
              id: 'relation-public-stranger',
              user: stranger,
              state: 'open',
              isPrivate: false,
              inviteCode: null,
              age: 2,
            ),
            (
              id: 'relation-running-viewer',
              user: viewer,
              state: 'running',
              isPrivate: false,
              inviteCode: null,
              age: 3,
            ),
            (
              id: 'relation-running-stranger',
              user: stranger,
              state: 'running',
              isPrivate: false,
              inviteCode: null,
              age: 4,
            ),
            (
              id: 'relation-finished-viewer',
              user: viewer,
              state: 'finished',
              isPrivate: false,
              inviteCode: null,
              age: 5,
            ),
          ];
          final rows = await GameMatch.db.insert(session, [
            for (final spec in specs)
              GameMatch(
                publicId: spec.id,
                ownerUserIdentifier: spec.user,
                name: spec.id,
                mapName: 'verdantia',
                state: spec.state,
                turn: 0,
                maxPlayers: 2,
                minPlayers: 2,
                private: spec.isPrivate,
                quickplay: false,
                createdAt: baseTime.add(Duration(seconds: spec.age)),
                inviteCode: spec.inviteCode,
              ),
          ]);
          final usersByMatchId = {for (final spec in specs) spec.id: spec.user};
          await GamePlayer.db.insert(session, [
            for (var index = 0; index < rows.length; index += 1)
              GamePlayer(
                matchId: rows[index].id!,
                publicPlayerId: 'relation-player-$index',
                userIdentifier: usersByMatchId[rows[index].publicId]!,
                displayName: 'Relation player $index',
                colorValue: index,
                countryId: PlayerCountry.values[index].name,
                kind: WirePlayerKind.human.name,
                connectionState: WirePlayerConnectionState.connected.name,
                ready: false,
                seatOrder: 0,
              ),
          ]);

          final visible = await ServerpodMultiplayerMatchStore(
            session,
          ).listVisibleMatches(viewer);

          expect(visible.map((match) => match.id), [
            'relation-running-viewer',
            'relation-public-stranger',
            'relation-public-viewer',
            'relation-private-viewer',
          ]);
          expect(
            visible.where((match) => match.id == 'relation-public-viewer'),
            hasLength(1),
          );
        },
      );

      test('pages running matches with included latest snapshots', () async {
        final session = sessionBuilder.build();
        final createdAt = DateTime.utc(2026, 7, 11, 8);
        final matchCount = multiplayerRunningMatchPageSize + 2;
        final rows = await GameMatch.db.insert(session, [
          for (var index = 0; index < matchCount; index += 1)
            GameMatch(
              publicId: 'running-page-${index.toString().padLeft(3, '0')}',
              ownerUserIdentifier: 'running-page-owner',
              name: 'Running page $index',
              mapName: 'verdantia',
              state: 'running',
              turn: 1,
              maxPlayers: 2,
              minPlayers: 2,
              private: false,
              quickplay: false,
              createdAt: createdAt,
            ),
        ]);
        await GameSnapshot.db.insert(session, [
          GameSnapshot(
            matchId: rows.first.id!,
            offset: 0,
            snapshot: WireSnapshot(
              matchId: rows.first.publicId,
              offset: 0,
              save: const {},
              state: const {},
            ),
            createdAt: createdAt,
          ),
          for (var index = 0; index < rows.length; index += 1)
            GameSnapshot(
              matchId: rows[index].id!,
              offset: index == 0 ? 1 : 0,
              snapshot: WireSnapshot(
                matchId: rows[index].publicId,
                offset: index == 0 ? 1 : 0,
                save: const {},
                state: const {},
              ),
              createdAt: createdAt.add(const Duration(seconds: 1)),
            ),
        ]);
        final store = ServerpodMultiplayerMatchStore(session);

        final firstPage = await store.listRunningStates();
        final secondPage = await store.listRunningStates(
          after: firstPage.nextCursor,
        );

        expect(firstPage.states, hasLength(multiplayerRunningMatchPageSize));
        expect(firstPage.states.first.match.id, 'running-page-000');
        expect(firstPage.states.first.snapshot.offset, 1);
        expect(firstPage.states.last.match.id, 'running-page-063');
        expect(
          firstPage.nextCursor,
          RunningMatchCursor(
            createdAt: createdAt,
            publicId: 'running-page-063',
          ),
        );
        expect(secondPage.states.map((state) => state.match.id), [
          'running-page-064',
          'running-page-065',
        ]);
        expect(secondPage.nextCursor, isNull);

        await GameMatch.db.delete(session, rows.skip(64).toList());
        final exactFinalPage = await store.listRunningStates();
        expect(
          exactFinalPage.states,
          hasLength(multiplayerRunningMatchPageSize),
        );
        expect(exactFinalPage.nextCursor, isNull);
      });

      test(
        'updates only the latest snapshot and rejects stale offsets',
        () async {
          final session = sessionBuilder.build();
          final store = ServerpodMultiplayerMatchStore(session);
          final createdAt = DateTime.utc(2026, 7, 11, 9);
          final initial = StoredMatchState(
            match: WireMatch(
              id: 'snapshot-offset-guard',
              ownerUserId: 'snapshot-offset-owner',
              name: 'Snapshot offset guard',
              mapName: 'verdantia',
              players: const [],
              maxPlayers: 2,
              minPlayers: 2,
              turn: 1,
              state: 'open',
              createdAt: createdAt,
            ),
            snapshot: const WireSnapshot(
              matchId: 'snapshot-offset-guard',
              offset: 0,
              save: {'turn': 1},
              state: {'phase': 'lobby'},
            ),
          );
          await store.createState(initial);
          final next = initial.copyWith(
            snapshot: initial.snapshot.copyWith(
              offset: 1,
              save: const {'turn': 2},
              state: const {
                'phase': 'running',
                'payload': {'nested': 'preserved'},
              },
            ),
          );

          await store.saveState(next);
          final matchRow = await GameMatch.db.findFirstRow(
            session,
            where: (table) => table.publicId.equals(initial.match.id),
          );
          expect(matchRow, isNotNull);
          final matchRowId = matchRow!.id!;
          final snapshots = await GameSnapshot.db.find(
            session,
            where: (table) => table.matchId.equals(matchRowId),
          );
          expect(snapshots, hasLength(1));
          expect(snapshots.single.offset, 1);
          expect(snapshots.single.snapshot.toJson(), next.snapshot.toJson());

          await expectLater(
            store.saveState(initial),
            throwsA(isA<StateError>()),
          );
          final afterStaleWrite = await GameSnapshot.db.find(
            session,
            where: (table) => table.matchId.equals(matchRowId),
          );
          expect(afterStaleWrite, hasLength(1));
          expect(afterStaleWrite.single.offset, 1);
          expect(
            afterStaleWrite.single.snapshot.toJson(),
            next.snapshot.toJson(),
          );
        },
      );

      test('creates, joins, starts, and loads a persisted match', () async {
        final owner = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'owner-user@example.test',
          displayName: 'Owner Nick',
        );
        final guest = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'guest-user@example.test',
          displayName: 'Guest Nick',
        );
        final stranger = await _accountSession(
          sessionBuilder,
          endpoints,
          email: 'stranger-user@example.test',
          displayName: 'Stranger Nick',
        );
        final request = CreateMatchRequest(
          name: 'Endpoint smoke',
          mapName: 'myranth',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        );

        final created = await endpoints.multiplayer.createMatch(
          owner.session,
          request,
        );
        expect(created.ownerUserId, owner.userIdentifier);
        expect(created.players.map((player) => player.userId), [
          owner.userIdentifier,
        ]);
        expect(created.players.map((player) => player.name), ['Owner Nick']);
        expect(created.state, 'open');
        final ownerPublicId = created.players.single.id;

        final listed = await endpoints.multiplayer.listMatches(guest.session);
        expect(listed.map((match) => match.id), contains(created.id));

        final joined = await endpoints.multiplayer.joinMatch(
          guest.session,
          created.id,
        );
        final guestPublicId = joined.players
            .singleWhere((player) => player.userId == guest.userIdentifier)
            .id;
        expect(joined.players.map((player) => player.userId), [
          ownerPublicId,
          guest.userIdentifier,
        ]);
        expect(joined.ownerUserId, ownerPublicId);
        expect(joined.players.map((player) => player.name), [
          'Owner Nick',
          'Guest Nick',
        ]);

        final started = await endpoints.multiplayer.startMatch(
          owner.session,
          created.id,
        );
        expect(started.state, 'running');
        expect(started.turn, 1);
        expect(started.players.map((player) => player.userId), [
          owner.userIdentifier,
          guestPublicId,
        ]);

        final loaded = await endpoints.multiplayer.loadMatch(
          guest.session,
          created.id,
        );
        expect(loaded.state, 'running');
        expect(loaded.players.map((player) => player.userId), [
          ownerPublicId,
          guest.userIdentifier,
        ]);
        expect(loaded.ownerUserId, ownerPublicId);

        final guestRunningMatches = await endpoints.multiplayer.listMatches(
          guest.session,
        );
        final strangerRunningMatches = await endpoints.multiplayer.listMatches(
          stranger.session,
        );
        expect(
          guestRunningMatches.map((match) => match.id),
          contains(created.id),
        );
        expect(
          strangerRunningMatches.map((match) => match.id),
          isNot(contains(created.id)),
        );

        final snapshot = await endpoints.multiplayer.loadSnapshot(
          owner.session,
          created.id,
        );
        expect(snapshot.matchId, created.id);
        expect(snapshot.offset, 0);
        expect(snapshot.save, isNotEmpty);
        expect(snapshot.state, isNotEmpty);

        final databaseSession = sessionBuilder.build();
        final persistedMatch = await GameMatch.db.findFirstRow(
          databaseSession,
          where: (table) => table.publicId.equals(created.id),
        );
        expect(persistedMatch, isNotNull);
        final matchRowId = persistedMatch!.id!;
        final initialSnapshotRows = await GameSnapshot.db.find(
          databaseSession,
          where: (table) => table.matchId.equals(matchRowId),
        );
        expect(initialSnapshotRows, hasLength(1));
        final snapshotRowId = initialSnapshotRows.single.id;

        final events = await endpoints.multiplayer.listEvents(
          owner.session,
          created.id,
          0,
        );
        expect(events, isEmpty);

        final ownerPlayer = started.players.firstWhere(
          (player) => player.userId == owner.userIdentifier,
        );
        final input = StreamController<MultiplayerClientMessage>();
        final initialMessage = Completer<MultiplayerServerMessage>();
        final ackMessages = <MultiplayerServerMessage>[];
        final ackMessagesSeen = Completer<List<MultiplayerServerMessage>>();
        final subscription = endpoints.multiplayer
            .connect(owner.session, created.id, 0, input.stream)
            .listen(
              (message) {
                if (message.snapshot != null && !initialMessage.isCompleted) {
                  initialMessage.complete(message);
                }
                if (message.ack != null) {
                  ackMessages.add(message);
                  if (ackMessages.length == 2 && !ackMessagesSeen.isCompleted) {
                    ackMessagesSeen.complete(List.unmodifiable(ackMessages));
                  }
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!initialMessage.isCompleted) {
                  initialMessage.completeError(error, stackTrace);
                }
                if (!ackMessagesSeen.isCompleted) {
                  ackMessagesSeen.completeError(error, stackTrace);
                }
              },
            );
        final initial = await initialMessage.future.timeout(_streamTimeout);
        expect(initial.snapshot?.matchId, created.id);
        expect(initial.snapshot?.offset, 0);

        final retryMessage = MultiplayerClientMessage(
          clientMessageId: 'submit-turn-1',
          lastSeenOffset: 0,
          requestSnapshot: false,
          command: WireCommand(
            matchId: created.id,
            tick: 1,
            turn: 1,
            actorPlayerId: ownerPlayer.id,
            command: GameCommandSerializer.toJson(
              SubmitTurnCommand(ownerPlayer.id),
            ),
          ),
        );
        input
          ..add(retryMessage)
          ..add(retryMessage);

        final acks = await ackMessagesSeen.future.timeout(_streamTimeout);
        expect(acks.map((message) => message.ack?.accepted), [true, true]);
        expect(acks.map((message) => message.ack?.offset).toSet(), {1});

        final persistedEvents = await endpoints.multiplayer.listEvents(
          owner.session,
          created.id,
          0,
        );
        expect(persistedEvents, hasLength(1));
        expect(persistedEvents.single.offset, acks.first.ack?.offset);

        final persistedSnapshots = await GameSnapshot.db.find(
          databaseSession,
          where: (table) => table.matchId.equals(matchRowId),
        );
        expect(persistedSnapshots, hasLength(1));
        expect(persistedSnapshots.single.id, snapshotRowId);
        expect(persistedSnapshots.single.offset, persistedEvents.single.offset);
        final canonicalState = PersistentGameState.fromJson(
          persistedSnapshots.single.snapshot.state,
        );
        final projectedState = PersistentGameState.fromJson(
          acks.first.ack!.snapshot.state,
        );
        expect(acks.first.ack!.snapshot.matchId, created.id);
        expect(
          acks.first.ack!.snapshot.offset,
          persistedSnapshots.single.offset,
        );
        expect(
          canonicalState.units.any(
            (unit) => unit.ownerPlayerId == guestPublicId,
          ),
          isTrue,
        );
        expect(
          projectedState.units.every(
            (unit) => unit.ownerPlayerId == ownerPlayer.id,
          ),
          isTrue,
        );
        expect(projectedState.fogOfWar.players.keys, {ownerPlayer.id});

        final guestPlayer = started.players.firstWhere(
          (player) => player.id == guestPublicId,
        );
        final guestAck = await _sendClientCommand(
          endpoints,
          session: guest.session,
          matchId: created.id,
          afterOffset: persistedEvents.single.offset,
          message: MultiplayerClientMessage(
            clientMessageId: 'submit-turn-guest',
            lastSeenOffset: persistedEvents.single.offset,
            requestSnapshot: false,
            command: WireCommand(
              matchId: created.id,
              tick: 2,
              turn: 1,
              actorPlayerId: guestPlayer.id,
              command: GameCommandSerializer.toJson(
                SubmitTurnCommand(guestPlayer.id),
              ),
            ),
          ),
        );
        expect(guestAck.accepted, isTrue);
        expect(GameSave.fromJson(guestAck.snapshot.save).turn, 2);

        final reloadedAfterTurn = await endpoints.multiplayer.loadMatch(
          owner.session,
          created.id,
        );
        expect(reloadedAfterTurn.turn, 2);

        await input.close();
        await subscription.cancel();
      });

      test(
        'reconnects clients to the latest snapshot without duplicate replay',
        () async {
          final owner = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'owner-reconnect@example.test',
            displayName: 'Owner Reconnect',
          );
          final guest = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'guest-reconnect@example.test',
            displayName: 'Guest Reconnect',
          );
          final started = await _startTwoPlayerMatch(
            endpoints,
            ownerSession: owner.session,
            guestSession: guest.session,
          );

          final guestBeforeInput = StreamController<MultiplayerClientMessage>();
          final guestBeforeMessages = await _connectUntilInitialSnapshot(
            endpoints.multiplayer.connect(
              guest.session,
              started.id,
              0,
              guestBeforeInput.stream,
            ),
            guestBeforeInput,
          );
          expect(guestBeforeMessages.single.snapshot?.offset, 0);

          final ownerPlayer = started.players.firstWhere(
            (player) => player.userId == owner.userIdentifier,
          );
          final ownerInput = StreamController<MultiplayerClientMessage>();
          final ownerInitialMessage = Completer<MultiplayerServerMessage>();
          final ownerAckMessage = Completer<MultiplayerServerMessage>();
          final ownerSubscription = endpoints.multiplayer
              .connect(owner.session, started.id, 0, ownerInput.stream)
              .listen(
                (message) {
                  if (message.snapshot != null &&
                      !ownerInitialMessage.isCompleted) {
                    ownerInitialMessage.complete(message);
                  }
                  if (message.ack != null && !ownerAckMessage.isCompleted) {
                    ownerAckMessage.complete(message);
                  }
                },
                onError: (Object error, StackTrace stackTrace) {
                  if (!ownerInitialMessage.isCompleted) {
                    ownerInitialMessage.completeError(error, stackTrace);
                  }
                  if (!ownerAckMessage.isCompleted) {
                    ownerAckMessage.completeError(error, stackTrace);
                  }
                },
              );
          final ownerInitial = await ownerInitialMessage.future.timeout(
            _streamTimeout,
          );

          ownerInput.add(
            MultiplayerClientMessage(
              clientMessageId: 'submit-turn-reconnect',
              lastSeenOffset: ownerInitial.offset,
              requestSnapshot: false,
              command: WireCommand(
                matchId: started.id,
                tick: 1,
                turn: started.turn,
                actorPlayerId: ownerPlayer.id,
                command: GameCommandSerializer.toJson(
                  SubmitTurnCommand(ownerPlayer.id),
                ),
              ),
            ),
          );

          final ackMessage = await ownerAckMessage.future.timeout(
            _streamTimeout,
          );
          await ownerInput.close();
          await ownerSubscription.cancel();
          final ack = ackMessage.ack;
          expect(ack, isNotNull);
          expect(ack!.accepted, isTrue);
          expect(ack.offset, 1);
          expect(ack.snapshot.offset, 1);

          final guestReconnectInput =
              StreamController<MultiplayerClientMessage>();
          final guestReconnectMessages = await _connectUntilInitialSnapshot(
            endpoints.multiplayer.connect(
              guest.session,
              started.id,
              0,
              guestReconnectInput.stream,
            ),
            guestReconnectInput,
          );

          expect(guestReconnectMessages.single.offset, ack.offset);
          expect(guestReconnectMessages.single.snapshot?.offset, ack.offset);
          expect(guestReconnectMessages.single.snapshot?.matchId, started.id);
          expect(
            guestReconnectMessages.where((message) => message.event != null),
            isEmpty,
          );
          expect(
            guestReconnectMessages.where((message) => message.ack != null),
            isEmpty,
          );

          final persistedEvents = await endpoints.multiplayer.listEvents(
            guest.session,
            started.id,
            0,
          );
          expect(persistedEvents, hasLength(1));
          expect(persistedEvents.single.offset, ack.offset);
        },
      );

      test(
        'quickplay enforces seats, countdown, country conflicts, and capacity',
        () async {
          final owner = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'quick-owner@example.test',
            displayName: 'Quick Owner',
          );
          final guest = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'quick-guest@example.test',
            displayName: 'Quick Guest',
          );
          final conflict = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'quick-conflict@example.test',
            displayName: 'Quick Conflict',
          );
          final third = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'quick-third@example.test',
            displayName: 'Quick Third',
          );
          final fourth = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'quick-fourth@example.test',
            displayName: 'Quick Fourth',
          );
          final overflow = await _accountSession(
            sessionBuilder,
            endpoints,
            email: 'quick-overflow@example.test',
            displayName: 'Quick Overflow',
          );

          final waiting = await endpoints.multiplayer.quickplay(
            owner.session,
            _quickplayRequest(PlayerCountry.poland),
          );
          expect(waiting.quickplay, isTrue);
          expect(waiting.maxPlayers, 4);
          expect(waiting.minPlayers, 2);
          expect(waiting.state, 'open');
          expect(waiting.autoStartAt, isNull);
          expect(waiting.players.single.country, PlayerCountry.poland);

          await endpoints.emailIdp.updateDisplayName(
            owner.session,
            displayName: 'Quick Owner Renamed',
          );
          final requeued = await endpoints.multiplayer.quickplay(
            owner.session,
            _quickplayRequest(PlayerCountry.china),
          );
          expect(requeued.id, waiting.id);
          expect(requeued.players, hasLength(1));
          expect(requeued.players.single.name, 'Quick Owner Renamed');
          expect(requeued.players.single.country, PlayerCountry.china);

          final countingDown = await endpoints.multiplayer.quickplay(
            guest.session,
            _quickplayRequest(PlayerCountry.france),
          );
          expect(countingDown.id, waiting.id);
          expect(countingDown.state, 'open');
          expect(countingDown.autoStartAt, isNotNull);
          expect(countingDown.players.map((player) => player.country), [
            PlayerCountry.china,
            PlayerCountry.france,
          ]);

          await expectLater(
            endpoints.multiplayer.quickplay(
              conflict.session,
              _quickplayRequest(PlayerCountry.france),
            ),
            throwsA(
              isA<MultiplayerException>().having(
                (error) => error.code,
                'code',
                'country_unavailable',
              ),
            ),
          );

          final threePlayers = await endpoints.multiplayer.quickplay(
            third.session,
            _quickplayRequest(PlayerCountry.germany),
          );
          expect(threePlayers.id, waiting.id);
          expect(threePlayers.state, 'open');
          expect(threePlayers.players, hasLength(3));
          expect(threePlayers.autoStartAt, countingDown.autoStartAt);

          final started = await endpoints.multiplayer.quickplay(
            fourth.session,
            _quickplayRequest(PlayerCountry.japan),
          );
          expect(started.id, waiting.id);
          expect(started.state, 'running');
          expect(started.turn, 1);
          expect(started.autoStartAt, isNull);
          expect(started.players, hasLength(4));
          expect(started.players.map((player) => player.country), [
            PlayerCountry.china,
            PlayerCountry.france,
            PlayerCountry.germany,
            PlayerCountry.japan,
          ]);

          final nextLobby = await endpoints.multiplayer.quickplay(
            overflow.session,
            _quickplayRequest(PlayerCountry.italy),
          );
          expect(nextLobby.id, isNot(started.id));
          expect(nextLobby.state, 'open');
          expect(nextLobby.players.single.country, PlayerCountry.italy);
        },
      );
    },
    rollbackDatabase: RollbackDatabase.afterEach,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

const _streamTimeout = Duration(seconds: 5);
const _backlogFlushDelay = Duration(milliseconds: 250);

final class _AccountSession {
  const _AccountSession({required this.session, required this.userIdentifier});

  final TestSessionBuilder session;
  final String userIdentifier;
}

Future<_AccountSession> _accountSession(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints, {
  required String email,
  required String displayName,
}) async {
  _ensureAuthServices();
  final auth = await endpoints.emailIdp.createAccount(
    sessionBuilder,
    email: email,
    password: 'long-password',
    displayName: displayName,
  );
  final userIdentifier = auth.authUserId.uuid;
  return _AccountSession(
    session: _authenticatedSession(sessionBuilder, userIdentifier),
    userIdentifier: userIdentifier,
  );
}

void _ensureAuthServices() {
  try {
    auth_core.AuthServices.instance;
  } on StateError {
    auth_core.AuthServices.set(
      tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    );
  }
}

TestSessionBuilder _authenticatedSession(
  TestSessionBuilder sessionBuilder,
  String userIdentifier,
) {
  return sessionBuilder.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      userIdentifier,
      const {},
    ),
  );
}

Future<WireMatch> _startTwoPlayerMatch(
  TestEndpoints endpoints, {
  required TestSessionBuilder ownerSession,
  required TestSessionBuilder guestSession,
}) async {
  final created = await endpoints.multiplayer.createMatch(
    ownerSession,
    CreateMatchRequest(
      name: 'Reconnect smoke',
      mapName: 'myranth',
      maxPlayers: 2,
      minPlayers: 2,
      private: false,
    ),
  );
  await endpoints.multiplayer.joinMatch(guestSession, created.id);
  return endpoints.multiplayer.startMatch(ownerSession, created.id);
}

CreateMatchRequest _quickplayRequest(PlayerCountry country) {
  return CreateMatchRequest(
    name: 'Ignored quickplay name',
    mapName: 'myranth',
    maxPlayers: 2,
    minPlayers: 1,
    private: true,
    countryId: country.name,
  );
}

Future<List<MultiplayerServerMessage>> _connectUntilInitialSnapshot(
  Stream<MultiplayerServerMessage> stream,
  StreamController<MultiplayerClientMessage> input,
) async {
  final messages = <MultiplayerServerMessage>[];
  final snapshotSeen = Completer<void>();
  Object? postSnapshotError;
  StackTrace? postSnapshotStackTrace;
  late final StreamSubscription<MultiplayerServerMessage> subscription;
  subscription = stream.listen(
    (message) {
      messages.add(message);
      if (message.snapshot != null && !snapshotSeen.isCompleted) {
        snapshotSeen.complete();
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!snapshotSeen.isCompleted) {
        snapshotSeen.completeError(error, stackTrace);
      }
      postSnapshotError = error;
      postSnapshotStackTrace = stackTrace;
    },
  );

  try {
    await snapshotSeen.future.timeout(_streamTimeout);
    await Future<void>.delayed(_backlogFlushDelay);
    final error = postSnapshotError;
    if (error != null) {
      Error.throwWithStackTrace(
        error,
        postSnapshotStackTrace ?? StackTrace.current,
      );
    }
    if (!input.isClosed) await input.close();
    return messages;
  } finally {
    await subscription.cancel();
  }
}

Future<WireCommandAck> _sendClientCommand(
  TestEndpoints endpoints, {
  required TestSessionBuilder session,
  required String matchId,
  required int afterOffset,
  required MultiplayerClientMessage message,
}) async {
  final input = StreamController<MultiplayerClientMessage>();
  final initialSnapshot = Completer<void>();
  final ackMessage = Completer<WireCommandAck>();
  late final StreamSubscription<MultiplayerServerMessage> subscription;
  subscription = endpoints.multiplayer
      .connect(session, matchId, afterOffset, input.stream)
      .listen(
        (serverMessage) {
          if (serverMessage.snapshot != null && !initialSnapshot.isCompleted) {
            initialSnapshot.complete();
          }
          final ack = serverMessage.ack;
          if (ack != null && !ackMessage.isCompleted) {
            ackMessage.complete(ack);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!initialSnapshot.isCompleted) {
            initialSnapshot.completeError(error, stackTrace);
          }
          if (!ackMessage.isCompleted) {
            ackMessage.completeError(error, stackTrace);
          }
        },
      );

  try {
    await initialSnapshot.future.timeout(_streamTimeout);
    input.add(message);
    return await ackMessage.future.timeout(_streamTimeout);
  } finally {
    await input.close();
    await subscription.cancel();
  }
}
