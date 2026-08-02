part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubCommandIdempotencyScenarios() {
  test(
    'reconnects an offline client to the latest authoritative snapshot',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final store = _MemoryMatchStore();
      final openMatch = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Reconnect smoke',
          mapName: 'verdantia',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      final joined = await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: openMatch.id,
      );
      final match = await hub.startMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: joined.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      final owner = match.players.first;
      final guest = match.players.last;

      final guestInitialInput = StreamController<MultiplayerClientMessage>();
      final guestInitialStream = hub
          .connect(
            store: store,
            userIdentifier: 'guest-user',
            matchId: match.id,
            afterOffset: 0,
            input: guestInitialInput.stream,
          )
          .asBroadcastStream();
      final guestInitial = await guestInitialStream.first;
      expect(guestInitial.snapshot?.offset, 0);
      await guestInitialInput.close();

      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerStream = hub
          .connect(
            store: store,
            userIdentifier: owner.userId,
            matchId: match.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .asBroadcastStream();
      expect((await ownerStream.first).snapshot?.offset, 0);
      final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
      ownerInput.add(
        MultiplayerClientMessage(
          clientMessageId: 'owner-submit-1',
          lastSeenOffset: 0,
          requestSnapshot: false,
          command: WireCommand(
            matchId: match.id,
            tick: 1,
            turn: 1,
            actorPlayerId: owner.id,
            command: DomainCommandCodec.toJson(SubmitTurnCommand(owner.id)),
          ),
        ),
      );

      final ackMessage = await ownerAck;
      expect(ackMessage.ack?.accepted, isTrue);

      final authoritative = await store.findState(match.id);
      final reconnectInput = StreamController<MultiplayerClientMessage>();
      final reconnectStream = hub
          .connect(
            store: store,
            userIdentifier: 'guest-user',
            matchId: match.id,
            afterOffset: guestInitial.offset,
            input: reconnectInput.stream,
          )
          .asBroadcastStream();
      final reconnectMessage = await reconnectStream.first;

      expect(reconnectMessage.offset, ackMessage.offset);
      expect(
        reconnectMessage.snapshot?.toJson(),
        isNot(authoritative!.snapshot.toJson()),
      );
      expect(
        CanonicalGameSnapshotCodec.decodeDomainState(
          reconnectMessage.snapshot!.state,
        ).playerGold.keys,
        everyElement(guest.id),
      );
      await expectLater(
        reconnectStream
            .firstWhere((message) => message.event != null)
            .timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );

      await ownerInput.close();
      await reconnectInput.close();
    },
  );
  test('acknowledges retried client messages without applying twice', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final openMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Retry smoke',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final joined = await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: openMatch.id,
    );
    final match = await hub.startMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: joined.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final owner = match.players.first;
    final guest = match.players.last;
    final stored = (await store.findState(match.id))!;
    final canonicalState = CanonicalGameSnapshotCodec.decodeDomainState(
      stored.snapshot.state,
    );
    await store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(
          state: canonicalState
              .copyWith(playerGold: {owner.id: 111, guest.id: 999})
              .toJson(),
        ),
      ),
    );
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    expect((await ownerStream.first).snapshot?.offset, 0);

    final acks = ownerStream
        .where((message) => message.ack != null)
        .take(2)
        .toList();
    final retryMessage = MultiplayerClientMessage(
      clientMessageId: 'owner-submit-retry',
      lastSeenOffset: 0,
      requestSnapshot: false,
      command: WireCommand(
        matchId: match.id,
        tick: 1,
        turn: 1,
        actorPlayerId: owner.id,
        command: DomainCommandCodec.toJson(SubmitTurnCommand(owner.id)),
      ),
    );
    ownerInput
      ..add(retryMessage)
      ..add(retryMessage);

    final ackMessages = await acks;

    expect(ackMessages.map((message) => message.ack?.accepted), [true, true]);
    expect(ackMessages.map((message) => message.ack?.offset).toSet(), {1});
    for (final message in ackMessages) {
      expect(message.ack!.events, isEmpty);
      expect(
        CanonicalGameSnapshotCodec.decodeDomainState(
          message.ack!.snapshot.state,
        ).playerGold.keys,
        [owner.id],
      );
    }
    expect(await store.listEvents(match.id, 0), hasLength(1));
    expect((await store.findState(match.id))!.offset, 1);

    await ownerInput.close();
  });
  test('rejects a reused client message id for another command', () async {
    final fixture = await _startRunningMatch('message-id-conflict');
    final owner = fixture.match.players.first;
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: owner.userId,
          matchId: fixture.match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    expect((await ownerStream.first).snapshot?.offset, 0);

    final acks = ownerStream
        .where((message) => message.ack != null)
        .take(2)
        .toList();
    const clientMessageId = 'owner-reused-command-id';
    ownerInput
      ..add(
        MultiplayerClientMessage(
          clientMessageId: clientMessageId,
          lastSeenOffset: 0,
          requestSnapshot: false,
          command: WireCommand(
            matchId: fixture.match.id,
            tick: 1,
            turn: 1,
            actorPlayerId: owner.id,
            command: DomainCommandCodec.toJson(SubmitTurnCommand(owner.id)),
          ),
        ),
      )
      ..add(
        MultiplayerClientMessage(
          clientMessageId: clientMessageId,
          lastSeenOffset: 0,
          requestSnapshot: false,
          command: WireCommand(
            matchId: fixture.match.id,
            tick: 1,
            turn: 1,
            actorPlayerId: owner.id,
            command: DomainCommandCodec.toJson(EndTurnCommand(owner.id)),
          ),
        ),
      );

    final ackMessages = await acks;

    expect(ackMessages.map((message) => message.ack?.accepted), [true, false]);
    expect(ackMessages.map((message) => message.ack?.offset), [1, 1]);
    expect(ackMessages.last.ack?.reason, 'client_message_id_conflict');
    expect(ackMessages.last.ack?.movementExecutions.isEmpty, isTrue);
    expect(await fixture.store.listEvents(fixture.match.id, 0), hasLength(1));
    expect((await fixture.store.findState(fixture.match.id))!.offset, 1);

    await ownerInput.close();
  });
  test('deduplicates retry bursts under duplicate delivery patterns', () async {
    for (final duplicateCount in [2, 3, 5, 8]) {
      final fixture = await _startRunningMatch('retry-burst-$duplicateCount');
      final owner = fixture.match.players.first;
      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerStream = fixture.hub
          .connect(
            store: fixture.store,
            userIdentifier: owner.userId,
            matchId: fixture.match.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .asBroadcastStream();
      expect((await ownerStream.first).snapshot?.offset, 0);

      final acks = ownerStream
          .where((message) => message.ack != null)
          .take(duplicateCount)
          .toList();
      final retryMessage = MultiplayerClientMessage(
        clientMessageId: 'owner-submit-retry-burst-$duplicateCount',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: fixture.match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: DomainCommandCodec.toJson(SubmitTurnCommand(owner.id)),
        ),
      );

      for (var i = 0; i < duplicateCount; i++) {
        ownerInput.add(retryMessage);
      }

      final ackMessages = await acks.timeout(const Duration(seconds: 1));

      expect(
        ackMessages.map((message) => message.ack?.accepted),
        everyElement(isTrue),
      );
      expect(ackMessages.map((message) => message.ack?.offset).toSet(), {1});
      expect(
        ackMessages.map((message) => message.ack!.events),
        everyElement(isEmpty),
      );
      expect(await fixture.store.listEvents(fixture.match.id, 0), hasLength(1));
      expect((await fixture.store.findState(fixture.match.id))!.offset, 1);

      await ownerInput.close();
    }
  });
}
