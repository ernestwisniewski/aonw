part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubConnectionScenarios() {
  test(
    'keeps a running match resumable when stream clients disconnect',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final logs = <String>[];
      final store = _MemoryMatchStore(
        operationalEvents: _recordingOperationalEvents(logs),
      );
      final openMatch = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Presence match',
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

      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerInitial = Completer<void>();
      final guestOffline = Completer<WireMatch>();
      final guestConnectedAgain = Completer<WireMatch>();
      final ownerSubscription = hub
          .connect(
            store: store,
            userIdentifier: owner.userId,
            matchId: match.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .listen((message) {
            if (message.snapshot != null && !ownerInitial.isCompleted) {
              ownerInitial.complete();
            }
            final match = message.match;
            if (match == null) return;
            final guestPlayer = match.players.firstWhere(
              (player) => player.userId == guest.userId,
            );
            if (guestPlayer.connectionState ==
                    WirePlayerConnectionState.offline &&
                !guestOffline.isCompleted) {
              guestOffline.complete(match);
              return;
            }
            if (guestOffline.isCompleted &&
                guestPlayer.connectionState ==
                    WirePlayerConnectionState.connected &&
                !guestConnectedAgain.isCompleted) {
              guestConnectedAgain.complete(match);
            }
          });
      await ownerInitial.future.timeout(const Duration(seconds: 1));

      Future<StreamSubscription<MultiplayerServerMessage>> connectGuest(
        StreamController<MultiplayerClientMessage> input,
      ) async {
        final initial = Completer<void>();
        final subscription = hub
            .connect(
              store: store,
              userIdentifier: 'guest-user',
              matchId: match.id,
              afterOffset: 0,
              input: input.stream,
            )
            .listen((message) {
              if (message.snapshot != null && !initial.isCompleted) {
                initial.complete();
              }
            });
        await initial.future.timeout(const Duration(seconds: 1));
        return subscription;
      }

      final guestInputA = StreamController<MultiplayerClientMessage>();
      final guestInputB = StreamController<MultiplayerClientMessage>();
      final guestSubscriptionA = await connectGuest(guestInputA);
      final guestSubscriptionB = await connectGuest(guestInputB);

      await guestSubscriptionA.cancel();
      await guestInputA.close();
      final stillConnected = (await store.findState(
        match.id,
      ))!.match.players.firstWhere((player) => player.id == guest.id);
      expect(
        stillConnected.connectionState,
        WirePlayerConnectionState.connected,
      );

      await guestSubscriptionB.cancel();
      await guestInputB.close();
      final offlineMatch = await guestOffline.future.timeout(
        const Duration(seconds: 1),
      );
      expect(
        offlineMatch.players
            .firstWhere((player) => player.userId == guest.userId)
            .connectionState,
        WirePlayerConnectionState.offline,
      );

      final guestInputC = StreamController<MultiplayerClientMessage>();
      final guestSubscriptionC = await connectGuest(guestInputC);
      final connectedMatch = await guestConnectedAgain.future.timeout(
        const Duration(seconds: 1),
      );
      expect(
        connectedMatch.players
            .firstWhere((player) => player.userId == guest.userId)
            .connectionState,
        WirePlayerConnectionState.connected,
      );

      await guestSubscriptionC.cancel();
      await guestInputC.close();
      await ownerSubscription.cancel();
      await ownerInput.close();

      final disconnected = (await store.findState(match.id))!;
      expect(disconnected.match.state, 'running');
      expect(disconnected.snapshot.state['phase'], isNot('abandoned'));
      expect(
        disconnected.match.players.map((player) => player.connectionState),
        everyElement(WirePlayerConnectionState.offline),
      );
      expect(
        logs,
        contains('event=multiplayer_stream_reconnected match_id=${match.id}'),
      );
      expect(
        logs,
        contains('event=multiplayer_stream_disconnected match_id=${match.id}'),
      );
      expect(logs.join(' '), isNot(contains('guest-user')));
      expect(logs.join(' '), isNot(contains('owner-user')));

      final resumed = await hub.loadMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: match.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      expect(resumed.state, 'running');
    },
  );

  test('rejects a forged connection authorization before emitting', () async {
    final fixture = await _startRunningMatch('forged-authorization');
    final stored = (await fixture.store.findState(fixture.match.id))!;
    final victim = stored.match.players.last;
    final registry = MatchConnectionRegistry();
    final broadcaster = MatchBroadcaster(registry);
    final input = StreamController<MultiplayerClientMessage>();
    final messages = <MultiplayerServerMessage>[];
    final error = Completer<Object>();
    final done = Completer<void>();

    final subscription = registry
        .connect(
          store: fixture.store,
          userIdentifier: 'owner-user-forged-authorization',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: input.stream,
          authorize:
              ({
                required MultiplayerMatchStore store,
                required String matchId,
                required String userIdentifier,
              }) async => MatchConnectionAuthorization(
                state: stored,
                participant: victim,
              ),
          updateConnectionState:
              ({
                required MultiplayerMatchStore store,
                required String matchId,
                required String userIdentifier,
                required WirePlayerConnectionState connectionState,
              }) async => stored,
          handleClientMessage:
              ({
                required MultiplayerMatchStore store,
                required String matchId,
                required String userIdentifier,
                required MultiplayerClientMessage message,
                required MatchMessageTarget caller,
              }) async {},
          createMessage: broadcaster.message,
        )
        .listen(
          messages.add,
          onError: (Object value) {
            if (!error.isCompleted) error.complete(value);
          },
          onDone: done.complete,
        );

    await done.future.timeout(const Duration(seconds: 1));
    expect(await error.future, _multiplayerError('authorization_mismatch'));
    expect(messages, isEmpty);

    await subscription.cancel();
    unawaited(input.close());
  });

  test('projects rejected command acknowledgements for the caller', () async {
    final logs = <String>[];
    final fixture = await _startRunningMatch(
      'rejected-ack',
      operationalEvents: _recordingOperationalEvents(logs),
    );
    final owner = fixture.match.players.first;
    final guest = fixture.match.players.last;
    final stored = (await fixture.store.findState(fixture.match.id))!;
    final canonicalState = CanonicalGameSnapshotCodec.decodeDomainState(
      stored.snapshot.state,
    );
    await fixture.store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(
          state: canonicalState
              .copyWith(playerGold: {owner.id: 111, guest.id: 999})
              .toJson(),
        ),
      ),
    );
    final input = StreamController<MultiplayerClientMessage>();
    final stream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'owner-user-rejected-ack',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    await stream.first;
    final acknowledgement = stream.firstWhere((message) => message.ack != null);

    input.add(
      MultiplayerClientMessage(
        clientMessageId: 'forged-actor-command',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: fixture.match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: guest.id,
          command: DomainCommandCodec.toJson(SubmitTurnCommand(guest.id)),
        ),
      ),
    );
    final ack = (await acknowledgement).ack!;

    expect(ack.accepted, isFalse);
    expect(ack.events, isEmpty);
    expect(ack.movementExecutions.isEmpty, isTrue);
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        ack.snapshot.state,
      ).playerGold,
      {owner.id: 111},
    );
    expect(await fixture.store.listEvents(fixture.match.id, 0), isEmpty);
    expect(
      logs,
      contains(
        'event=multiplayer_command_rejected '
        'match_id=${fixture.match.id} reason=actor_mismatch',
      ),
    );
    expect(logs.join(' '), isNot(contains('forged-actor-command')));

    await input.close();
  });

  test('moves units through the authoritative server reducer', () async {
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
        mapName: 'myranth',
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
    final initialState = CanonicalGameSnapshotCodec.decodeDomainState(
      stored.snapshot.state,
    );
    final ownerUnit = initialState.units.firstWhere(
      (unit) => unit.ownerPlayerId == owner.id,
    );
    final target = await _makeMovementVisibleToGuest(
      store: store,
      stored: stored,
      state: initialState,
      ownerUnit: ownerUnit,
      guestId: guest.id,
    );

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

    final initialMessages = await Future.wait([
      ownerStream.first,
      guestStream.first,
    ]);
    expect(initialMessages.map((message) => message.snapshot?.offset), [0, 0]);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
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
          command: DomainCommandCodec.toJson(
            MoveUnitCommand(ownerUnit.id, target.col, target.row),
          ),
        ),
      ),
    );

    final ackMessage = await ownerAck;
    final guestMessage = await guestEvent;
    final nextState = CanonicalGameSnapshotCodec.decodeDomainState(
      ackMessage.ack!.snapshot.state,
    );
    final moved = nextState.units.firstWhere((unit) => unit.id == ownerUnit.id);

    expect(ackMessage.ack?.accepted, isTrue);
    expect(moved.col, target.col);
    expect(moved.row, target.row);
    expect(ackMessage.ack!.events.map(GameEventSerializer.fromJson).toList(), [
      isA<UnitMovedEvent>(),
    ]);
    final movement = ackMessage.ack!.movementExecutions.values.single;
    expect(
      (movement.unitId, movement.fromCol, movement.fromRow),
      (ownerUnit.id, ownerUnit.col, ownerUnit.row),
    );
    expect(movement.steps.last.col, target.col);
    expect(movement.steps.last.row, target.row);
    _expectGuestObservedMovement(guestMessage, ownerUnit, target);

    await ownerInput.close();
    await guestInput.close();
  });
}
