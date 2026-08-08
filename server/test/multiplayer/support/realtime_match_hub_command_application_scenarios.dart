part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubCommandApplicationScenarios() {
  _registerRealtimeMatchHubOutcomeTests();
  test('routes diplomacy commands through the authoritative hub', () async {
    final fixture = await _createDiplomacyMatchFixture();
    final hub = fixture.hub;
    final store = fixture.store;
    final match = fixture.match;
    final owner = fixture.owner;
    final guest = fixture.guest;

    final ownerInput = StreamController<MultiplayerClientMessage>();
    final secondOwnerInput = StreamController<MultiplayerClientMessage>();
    final guestInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    final guestStream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .asBroadcastStream();
    final secondOwnerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: secondOwnerInput.stream,
        )
        .asBroadcastStream();

    expect((await ownerStream.first).snapshot?.offset, 0);
    expect((await guestStream.first).snapshot?.offset, 0);
    expect((await secondOwnerStream.first).snapshot?.offset, 0);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
    final guestEvent = guestStream.firstWhere(
      (message) => message.event != null,
    );
    final secondOwnerEvent = secondOwnerStream.firstWhere(
      (message) => message.event != null,
    );

    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-diplomacy-1',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: DomainCommandCodec.toJson(
            SendGoldGiftCommand(
              playerId: owner.id,
              targetPlayerId: guest.id,
              amount: 10,
            ),
          ),
        ),
      ),
    );

    final ackMessage = await ownerAck;
    final eventMessage = await guestEvent;
    final secondOwnerEventMessage = await secondOwnerEvent;
    final nextState = CanonicalGameSnapshotCodec.decodeDomainState(
      ackMessage.ack!.snapshot.state,
    );

    expect(ackMessage.ack?.accepted, isTrue);
    expect(nextState.playerGold[owner.id], 10);
    expect(nextState.playerGold, isNot(contains(guest.id)));
    expect(nextState.diplomacy.relationScoreBetween(owner.id, guest.id), 2);
    expect(ackMessage.ack!.events.map(GameEventSerializer.fromJson).toList(), [
      isA<DiplomaticScoreChangedEvent>(),
    ]);
    expect(eventMessage.event?.command, isNull);
    expect(eventMessage.event?.turn, 1);
    expect(
      eventMessage.event!.events.map(GameEventSerializer.fromJson).toList(),
      [isA<DiplomaticScoreChangedEvent>()],
    );
    expect(secondOwnerEventMessage.event?.actorPlayerId, owner.id);
    expect(secondOwnerEventMessage.event?.turn, 1);
    expect(secondOwnerEventMessage.event?.command, isNotNull);
    expect(
      secondOwnerEventMessage.event!.events
          .map(GameEventSerializer.fromJson)
          .toList(),
      [isA<DiplomaticScoreChangedEvent>()],
    );
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        eventMessage.snapshot!.state,
      ).playerGold,
      {guest.id: 10},
    );

    await ownerInput.close();
    await secondOwnerInput.close();
    await guestInput.close();
  });
  test('broadcasts accepted commands with one authoritative offset', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final openMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Test match',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: openMatch.id,
    );
    final joined = await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: openMatch.id,
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'guest-user',
      matchId: joined.id,
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

    final ownerInput = StreamController<MultiplayerClientMessage>();
    final guestInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    final guestStream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .asBroadcastStream();

    expect((await ownerStream.first).snapshot?.offset, 0);
    expect((await guestStream.first).snapshot?.offset, 0);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
    final ownerAckMessages = <MultiplayerServerMessage>[];
    final guestEventMessages = <MultiplayerServerMessage>[];
    final ownerAckSubscription = ownerStream
        .where((message) => message.ack != null)
        .listen(ownerAckMessages.add);
    final guestEventSubscription = guestStream
        .where((message) => message.event != null)
        .listen(guestEventMessages.add);
    final ownerBroadcastEvent = ownerStream
        .firstWhere((message) => message.event != null)
        .timeout(const Duration(milliseconds: 100));
    final guestEvent = guestStream.firstWhere(
      (message) => message.event != null,
    );

    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-1',
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
    final eventMessage = await guestEvent;

    expect(ackMessage.ack?.accepted, isTrue);
    expect(ackMessage.offset, eventMessage.offset);
    expect(ackMessage.ack?.offset, eventMessage.event?.offset);
    expect(eventMessage.event?.actorPlayerId, isNull);
    expect(eventMessage.event?.command, isNull);
    expect(eventMessage.event?.events, isEmpty);
    expect(ownerAckMessages, [same(ackMessage)]);
    expect(guestEventMessages, [same(eventMessage)]);
    expect((await store.findState(match.id))!.offset, ackMessage.offset);
    await expectLater(ownerBroadcastEvent, throwsA(isA<TimeoutException>()));

    final reconnectInput = StreamController<MultiplayerClientMessage>();
    final reconnectStream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
          afterOffset: 0,
          input: reconnectInput.stream,
        )
        .asBroadcastStream();
    expect((await reconnectStream.first).snapshot?.offset, eventMessage.offset);
    await expectLater(
      reconnectStream
          .firstWhere((message) => message.event != null)
          .timeout(const Duration(milliseconds: 50)),
      throwsA(isA<TimeoutException>()),
    );

    await ownerAckSubscription.cancel();
    await guestEventSubscription.cancel();
    await ownerInput.close();
    await guestInput.close();
    await reconnectInput.close();
  });
  test('emits no command messages when transaction commit fails', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _CommitFailingMatchStore();
    final match = await _startRunningMatchInStore(
      hub: hub,
      store: store,
      suffix: 'command-commit-failure',
      mapCatalog: mapCatalog,
    );
    final owner = match.players.first;
    final guestInput = StreamController<MultiplayerClientMessage>();
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final guestInitial = Completer<void>();
    final ownerInitial = Completer<void>();
    final ownerError = Completer<Object>();
    final guestMessages = <MultiplayerServerMessage>[];
    final callerMessages = <MultiplayerServerMessage>[];
    final guestSubscription = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user-command-commit-failure',
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .listen((message) {
          if (message.snapshot != null && !guestInitial.isCompleted) {
            guestInitial.complete();
          } else {
            guestMessages.add(message);
          }
        });
    final ownerSubscription = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .listen(
          (message) {
            if (message.snapshot != null && !ownerInitial.isCompleted) {
              ownerInitial.complete();
            } else {
              callerMessages.add(message);
            }
          },
          onError: (Object error) {
            if (!ownerError.isCompleted) ownerError.complete(error);
          },
        );
    await Future.wait([
      guestInitial.future,
      ownerInitial.future,
    ]).timeout(const Duration(seconds: 1));

    store.failNextCommit();
    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-commit-failure',
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
    expect(
      await ownerError.future.timeout(const Duration(seconds: 1)),
      isA<StateError>(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(callerMessages, isEmpty);
    expect(guestMessages.where((message) => message.event != null), isEmpty);
    expect((await store.findState(match.id))!.offset, 0);
    expect(await store.listEvents(match.id, 0), isEmpty);

    await guestSubscription.cancel();
    await ownerSubscription.cancel();
    await guestInput.close();
    await ownerInput.close();
  });
}
