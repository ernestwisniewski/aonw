part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubTurnMovementHistoryTests() {
  test(
    'timeout persists and broadcasts recipient-safe turn movements',
    _timeoutPersistsAndBroadcastsTurnMovements,
  );
  test(
    'projects stored turn movements without reconnect replay',
    _projectsStoredTurnMovementsWithoutReconnectReplay,
  );
  test(
    'fails closed for stored movement chains with missing audience',
    _failsClosedForStoredMovementWithoutAudience,
  );
}

Future<void> _timeoutPersistsAndBroadcastsTurnMovements() async {
  final fixture = await _startTurnMovementFixture(turnTimeout: Duration.zero);
  final clients = await _TurnMovementClients.connect(fixture);
  try {
    final ownerEvent = clients.ownerStream.firstWhere(
      (message) => message.event != null,
    );
    final secondOwnerEvent = clients.secondOwnerStream.firstWhere(
      (message) => message.event != null,
    );
    final observerEvent = clients.observerStream.firstWhere(
      (message) => message.event != null,
    );

    await fixture.hub.advanceTimedOutTurns(store: fixture.store);
    final messages = await Future.wait([
      ownerEvent,
      secondOwnerEvent,
      observerEvent,
    ]);

    expect(
      _turnMovementSnapshots(messages[0].event!.movementExecutions),
      _expectedOwnerTurnMovements(),
    );
    expect(
      _turnMovementSnapshots(messages[1].event!.movementExecutions),
      _expectedOwnerTurnMovements(),
    );
    expect(messages[2].event!.movementExecutions.isEmpty, isTrue);
    expect(
      messages
          .map(
            (message) => message.event!.events
                .map(GameEventSerializer.fromJson)
                .whereType<UnitMovedEvent>()
                .length,
          )
          .toList(),
      [2, 2, 0],
    );
    for (final message in messages) {
      expect(
        message.event!.toJson().toString(),
        isNot(contains('_serverAudiencePlayerIds')),
      );
    }
    final stored = await fixture.store.listEvents(fixture.match.id, 0);
    expect(stored, hasLength(1));
    expect(
      _turnMovementSnapshots(stored.single.movementExecutions),
      _expectedStoredTurnMovements(fixture),
    );
    expect(clients.ownerAcks, isEmpty);
    expect(clients.secondOwnerAcks, isEmpty);
    expect(clients.observerAcks, isEmpty);
    expect(clients.ownerEvents, hasLength(1));
    expect(clients.secondOwnerEvents, hasLength(1));
    expect(clients.observerEvents, hasLength(1));
  } finally {
    await clients.close();
  }
}

Future<void> _projectsStoredTurnMovementsWithoutReconnectReplay() async {
  final fixture = await _startTurnMovementFixture();
  final clients = await _TurnMovementClients.connect(fixture);
  try {
    final acknowledgement = await clients.sendOwner(
      _turnMovementMessage(fixture),
    );
    expect(acknowledgement.ack?.accepted, isTrue);
  } finally {
    await clients.close();
  }

  final ownerHistory = await fixture.hub.listEvents(
    store: fixture.store,
    userIdentifier: fixture.owner.userId,
    matchId: fixture.match.id,
    afterOffset: 0,
  );
  final unitBHistory = await fixture.hub.listEvents(
    store: fixture.store,
    userIdentifier: 'turn-movement-unit-b',
    matchId: fixture.match.id,
    afterOffset: 0,
  );
  final observerHistory = await fixture.hub.listEvents(
    store: fixture.store,
    userIdentifier: 'turn-movement-observer',
    matchId: fixture.match.id,
    afterOffset: 0,
  );

  expect(
    _turnMovementSnapshots(ownerHistory.single.movementExecutions),
    _expectedOwnerTurnMovements(),
  );
  expect(_turnMovementSnapshots(unitBHistory.single.movementExecutions), [
    'unit-a:0,0->1,0;enter=2;total=2;audience=public',
    'unit-b:0,1->1,1;enter=2;total=2;audience=public',
    'unit-a:1,0->2,0;enter=2;total=2|3,0;enter=2;total=4;audience=public',
  ]);
  expect(observerHistory.single.movementExecutions.isEmpty, isTrue);
  for (final history in [ownerHistory, unitBHistory, observerHistory]) {
    expect(
      history.single.toJson().toString(),
      isNot(contains('_serverAudiencePlayerIds')),
    );
  }

  for (final afterOffset in [0, ownerHistory.single.offset]) {
    final input = StreamController<MultiplayerClientMessage>();
    final messages = <MultiplayerServerMessage>[];
    final initialSnapshot = Completer<MultiplayerServerMessage>();
    final barrierSnapshot = Completer<MultiplayerServerMessage>();
    final subscription = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'turn-movement-observer',
          matchId: fixture.match.id,
          afterOffset: afterOffset,
          input: input.stream,
        )
        .listen((message) {
          messages.add(message);
          if (message.snapshot == null) return;
          if (!initialSnapshot.isCompleted) {
            initialSnapshot.complete(message);
          } else if (!barrierSnapshot.isCompleted) {
            barrierSnapshot.complete(message);
          }
        });
    final initial = await initialSnapshot.future.timeout(
      const Duration(seconds: 1),
    );
    expect(initial.snapshot?.offset, ownerHistory.single.offset);
    expect(initial.event, isNull);
    input.add(
      MultiplayerClientMessage(
        clientMessageId: 'reconnect-history-barrier-$afterOffset',
        lastSeenOffset: initial.offset,
        requestSnapshot: true,
      ),
    );
    await barrierSnapshot.future.timeout(const Duration(seconds: 1));
    expect(messages.where((message) => message.event != null), isEmpty);
    await subscription.cancel();
    await input.close();
  }
}

Future<void> _failsClosedForStoredMovementWithoutAudience() async {
  final fixture = await _startTurnMovementFixture();
  final state = (await fixture.store.findState(fixture.match.id))!;
  final canonical = WireEvent(
    matchId: fixture.match.id,
    offset: 1,
    timestamp: DateTime.utc(2026, 7, 25),
    actorPlayerId: fixture.owner.id,
    tick: 1,
    turn: 1,
    command: const {'type': 'stored-movement-canary'},
    movementExecutions: WireMovementExecutionList([
      WireMovementExecution(
        unitId: 'unit-a',
        fromCol: 0,
        fromRow: 0,
        steps: const [
          WireMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
        serverAudiencePlayerIds: [fixture.owner.id],
      ),
      WireMovementExecution(
        unitId: 'unit-a',
        fromCol: 1,
        fromRow: 0,
        steps: const [
          WireMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      ),
    ]),
  );
  await fixture.store.appendEvent(
    state.copyWith(snapshot: state.snapshot.copyWith(offset: 1)),
    canonical,
    actorPlayerId: fixture.owner.id,
    clientMessageId: 'stored-movement-canary',
  );

  final history = await fixture.hub.listEvents(
    store: fixture.store,
    userIdentifier: fixture.owner.userId,
    matchId: fixture.match.id,
    afterOffset: 0,
  );

  expect(canonical.movementExecutions.isEmpty, isFalse);
  expect(history.single.movementExecutions.isEmpty, isTrue);
  expect(history.single.toJson().toString(), isNot(contains('unit-a')));
}

List<String> _expectedOwnerTurnMovements() => const [
  'unit-a:0,0->1,0;enter=2;total=2;audience=public',
  'unit-a:1,0->2,0;enter=2;total=2|3,0;enter=2;total=4;audience=public',
];

List<String> _expectedStoredTurnMovements(_TurnMovementFixture fixture) => [
  'unit-a:0,0->1,0;enter=2;total=2;audience=${fixture.owner.id},${fixture.unitBPlayer.id}',
  'unit-b:0,1->1,1;enter=2;total=2'
      ';audience=${fixture.unitBPlayer.id}',
  'unit-a:1,0->2,0;enter=2;total=2|3,0;enter=2;total=4'
      ';audience=${fixture.owner.id},${fixture.unitBPlayer.id}',
];
