part of '../realtime_match_hub_test.dart';

const _turnMovementClientMessageId = 'turn-movement-final-submit';

Future<TileData> _makeMovementVisibleToGuest({
  required _MemoryMatchStore store,
  required StoredMatchState stored,
  required PersistentGameState state,
  required GameUnit ownerUnit,
  required String guestId,
}) async {
  final occupied = {for (final unit in state.units) '${unit.col}:${unit.row}'};
  final target = _testMap().tiles.firstWhere(
    (tile) =>
        !occupied.contains('${tile.col}:${tile.row}') &&
        (tile.col - ownerUnit.col).abs() <= 1 &&
        (tile.row - ownerUnit.row).abs() <= 1 &&
        (tile.col != ownerUnit.col || tile.row != ownerUnit.row),
  );
  final plan = UnitMovementPathfinder(
    mapData: _testMap(),
    units: state.units,
  ).plan(unit: ownerUnit, targetTile: target);
  if (plan == null) {
    throw StateError('Expected the movement fixture target to be reachable.');
  }
  final visibleHexes = {
    for (final step in plan.steps) HexCoordinate(col: step.col, row: step.row),
  };
  final visibleState = state.copyWith(
    fogOfWar: state.fogOfWar.updatePlayer(
      state.fogOfWar.fogForPlayer(guestId).withVisibleHexes(visibleHexes),
    ),
  );
  await store.saveState(
    stored.copyWith(
      snapshot: stored.snapshot.copyWith(state: visibleState.toJson()),
    ),
  );
  return target;
}

void _expectGuestObservedMovement(
  MultiplayerServerMessage message,
  GameUnit ownerUnit,
  TileData target,
) {
  expect(
    message.event!.events.map(GameEventSerializer.fromJson).toList(),
    isEmpty,
  );
  final movement = message.event!.movementExecutions.values.single;
  expect(movement.unitId, ownerUnit.id);
  expect(movement.steps.last.col, target.col);
  expect(movement.steps.last.row, target.row);
}

void _registerRealtimeMatchHubTurnMovementTests() {
  _registerRealtimeMatchHubTurnMovementHistoryTests();
  test(
    'persists and reuses recipient-safe turn movement evidence',
    _persistsAndReusesTurnMovementEvidence,
  );
}

Future<void> _persistsAndReusesTurnMovementEvidence() async {
  final fixture = await _startTurnMovementFixture();
  final clients = await _TurnMovementClients.connect(fixture);
  try {
    final secondOwnerEvent = clients.secondOwnerStream.firstWhere(
      (message) => message.event != null,
    );
    final observerEvent = clients.observerStream.firstWhere(
      (message) => message.event != null,
    );
    final message = _turnMovementMessage(fixture);

    final firstAck = await clients.sendOwner(message);
    final secondOwnerMessage = await secondOwnerEvent;
    final observerMessage = await observerEvent;
    final retryAck = await clients.sendOwner(message);

    _expectInitialAndRetryDeliveries(
      fixture: fixture,
      clients: clients,
      firstAck: firstAck,
      retryAck: retryAck,
      secondOwnerMessage: secondOwnerMessage,
      observerMessage: observerMessage,
    );
    await _expectStoredTurnMovement(fixture);

    final conflictAck = await clients.sendOwner(
      _turnMovementMessage(fixture, conflict: true),
    );

    expect(conflictAck.ack?.accepted, isFalse);
    expect(conflictAck.ack?.reason, 'client_message_id_conflict');
    expect(conflictAck.ack?.movementExecutions.isEmpty, isTrue);
    expect(await fixture.store.listEvents(fixture.match.id, 0), hasLength(1));
    expect(clients.ownerEvents, isEmpty);
    expect(clients.secondOwnerEvents, hasLength(1));
    expect(clients.observerEvents, hasLength(1));
  } finally {
    await clients.close();
  }
}

void _expectInitialAndRetryDeliveries({
  required _TurnMovementFixture fixture,
  required _TurnMovementClients clients,
  required MultiplayerServerMessage firstAck,
  required MultiplayerServerMessage retryAck,
  required MultiplayerServerMessage secondOwnerMessage,
  required MultiplayerServerMessage observerMessage,
}) {
  expect(firstAck.ack?.accepted, isTrue);
  expect(retryAck.ack?.accepted, isTrue);
  expect(firstAck.ack?.offset, retryAck.ack?.offset);
  expect(
    _turnMovementSnapshots(firstAck.ack!.movementExecutions),
    _expectedOwnerTurnMovements(),
  );
  expect(retryAck.ack!.movementExecutions, firstAck.ack!.movementExecutions);
  expect(
    _turnMovementSnapshots(secondOwnerMessage.event!.movementExecutions),
    _expectedOwnerTurnMovements(),
  );
  expect(observerMessage.event!.movementExecutions.isEmpty, isTrue);
  for (final plan in [
    firstAck.ack!.movementExecutions,
    retryAck.ack!.movementExecutions,
    secondOwnerMessage.event!.movementExecutions,
    observerMessage.event!.movementExecutions,
  ]) {
    expect(plan.toJson().toString(), isNot(contains('_serverAudience')));
  }
  expect(clients.ownerAcks, hasLength(2));
  expect(clients.ownerEvents, isEmpty);
  expect(clients.secondOwnerAcks, isEmpty);
  expect(clients.secondOwnerEvents, hasLength(1));
  expect(clients.observerAcks, isEmpty);
  expect(clients.observerEvents, hasLength(1));
}

Future<void> _expectStoredTurnMovement(_TurnMovementFixture fixture) async {
  final events = await fixture.store.listEvents(fixture.match.id, 0);
  expect(events, hasLength(1));
  expect(
    _turnMovementSnapshots(events.single.movementExecutions),
    _expectedStoredTurnMovements(fixture),
  );
  expect(
    events.single.movementExecutions.toJson().toString(),
    contains('_serverAudiencePlayerIds'),
  );
}

Future<_TurnMovementFixture> _startTurnMovementFixture({
  Duration? turnTimeout,
}) async {
  final mapCatalog = _FakeMapCatalog(_turnMovementMap());
  final commandReducer = turnTimeout == null
      ? ServerCommandReducer(mapCatalog: mapCatalog)
      : ServerCommandReducer(mapCatalog: mapCatalog, turnTimeout: turnTimeout);
  final hub = RealtimeMatchHub(commandReducer: commandReducer);
  final store = _MemoryMatchStore();
  final open = await hub.createMatch(
    store: store,
    userIdentifier: 'turn-movement-owner',
    request: CreateMatchRequest(
      name: 'Turn movement transport',
      mapName: 'verdantia',
      maxPlayers: 3,
      minPlayers: 3,
      private: false,
    ),
  );
  final withUnitB = await hub.joinMatch(
    store: store,
    userIdentifier: 'turn-movement-unit-b',
    matchId: open.id,
  );
  final full = await hub.joinMatch(
    store: store,
    userIdentifier: 'turn-movement-observer',
    matchId: withUnitB.id,
  );
  final match = await hub.startMatch(
    store: store,
    userIdentifier: 'turn-movement-owner',
    matchId: full.id,
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
  final fixture = _TurnMovementFixture(
    hub: hub,
    store: store,
    match: match,
    owner: match.players[0],
    unitBPlayer: match.players[1],
    observer: match.players[2],
  );
  await _seedTurnMovementState(fixture);
  return fixture;
}

Future<void> _seedTurnMovementState(_TurnMovementFixture fixture) async {
  final stored = (await fixture.store.findState(fixture.match.id))!;
  final save = GameSave.fromJson(stored.snapshot.save).copyWith(
    playerStates: {
      fixture.owner.id: PlayerTurnState.active,
      fixture.unitBPlayer.id: PlayerTurnState.finished,
      fixture.observer.id: PlayerTurnState.finished,
    },
  );
  final state = PersistentGameState(
    playerColors: {
      for (final player in fixture.match.players) player.id: player.colorValue,
    },
    units: [
      _queuedTurnMovementTestUnit(
        id: 'unit-a',
        ownerPlayerId: fixture.owner.id,
        type: GameUnitType.scout,
        row: 0,
        posture: UnitPosture.autoExploring,
      ),
      _queuedTurnMovementTestUnit(
        id: 'unit-b',
        ownerPlayerId: fixture.unitBPlayer.id,
        type: GameUnitType.warrior,
        row: 1,
      ),
    ],
    fogOfWar: FogOfWarState(
      players: {
        fixture.owner.id: _turnMovementOriginFog(fixture.owner.id, row: 0),
        fixture.unitBPlayer.id: _turnMovementOriginFog(
          fixture.unitBPlayer.id,
          row: 1,
        ),
        fixture.observer.id: PlayerFogOfWar(playerId: fixture.observer.id),
      },
    ),
    runtimeState: GameRuntimeState(
      submittedPlayerIds: {fixture.unitBPlayer.id, fixture.observer.id},
    ),
  );
  await fixture.store.saveState(
    stored.copyWith(
      snapshot: stored.snapshot.copyWith(
        save: save.toJson(),
        state: state.toJson(),
      ),
    ),
  );
}

GameUnit _queuedTurnMovementTestUnit({
  required String id,
  required String ownerPlayerId,
  required GameUnitType type,
  required int row,
  UnitPosture posture = UnitPosture.active,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: id,
    col: 0,
    row: row,
    movementPoints: 0,
    posture: posture,
  ).copyWithQueuedPath(
    QueuedMovePath(
      targetCol: 1,
      targetRow: row,
      steps: [
        UnitMovementStep(col: 0, row: row, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: row, enterCost: 1, cumulativeCost: 1),
      ],
    ),
  );
}

PlayerFogOfWar _turnMovementOriginFog(String playerId, {required int row}) {
  final origin = HexCoordinate(col: 0, row: row);
  return PlayerFogOfWar(
    playerId: playerId,
    discoveredHexes: {origin},
    visibleHexes: {origin},
  );
}

MapData _turnMovementMap() {
  return MapData(
    cols: 6,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 6; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

MultiplayerClientMessage _turnMovementMessage(
  _TurnMovementFixture fixture, {
  bool conflict = false,
}) {
  final command = conflict
      ? EndTurnCommand(fixture.owner.id)
      : SubmitTurnCommand(fixture.owner.id);
  return MultiplayerClientMessage(
    clientMessageId: _turnMovementClientMessageId,
    lastSeenOffset: 0,
    requestSnapshot: false,
    command: WireCommand(
      matchId: fixture.match.id,
      tick: 7,
      turn: 1,
      actorPlayerId: fixture.owner.id,
      command: GameCommandSerializer.toJson(command),
    ),
  );
}

List<String> _turnMovementSnapshots(WireMovementExecutionList plan) {
  return [
    for (final execution in plan.values)
      '${execution.unitId}:${execution.fromCol},${execution.fromRow}'
          '->${execution.steps.map((step) => '${step.col},${step.row}'
              ';enter=${step.enterCost};total=${step.cumulativeCost}').join('|')}'
          ';audience=${execution.serverAudiencePlayerIds?.join(',') ?? 'public'}',
  ];
}

final class _TurnMovementFixture {
  const _TurnMovementFixture({
    required this.hub,
    required this.store,
    required this.match,
    required this.owner,
    required this.unitBPlayer,
    required this.observer,
  });

  final RealtimeMatchHub hub;
  final _MemoryMatchStore store;
  final WireMatch match;
  final WirePlayer owner;
  final WirePlayer unitBPlayer;
  final WirePlayer observer;
}

final class _TurnMovementClients {
  _TurnMovementClients._({
    required this.ownerInput,
    required this.secondOwnerInput,
    required this.observerInput,
    required this.ownerStream,
    required this.secondOwnerStream,
    required this.observerStream,
  });

  static Future<_TurnMovementClients> connect(
    _TurnMovementFixture fixture,
  ) async {
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final secondOwnerInput = StreamController<MultiplayerClientMessage>();
    final observerInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: fixture.owner.userId,
          matchId: fixture.match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    final secondOwnerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: fixture.owner.userId,
          matchId: fixture.match.id,
          afterOffset: 0,
          input: secondOwnerInput.stream,
        )
        .asBroadcastStream();
    final observerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'turn-movement-observer',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: observerInput.stream,
        )
        .asBroadcastStream();
    await Future.wait([
      ownerStream.first,
      secondOwnerStream.first,
      observerStream.first,
    ]);
    return _TurnMovementClients._(
      ownerInput: ownerInput,
      secondOwnerInput: secondOwnerInput,
      observerInput: observerInput,
      ownerStream: ownerStream,
      secondOwnerStream: secondOwnerStream,
      observerStream: observerStream,
    ).._recordMessages();
  }

  final StreamController<MultiplayerClientMessage> ownerInput;
  final StreamController<MultiplayerClientMessage> secondOwnerInput;
  final StreamController<MultiplayerClientMessage> observerInput;
  final Stream<MultiplayerServerMessage> ownerStream;
  final Stream<MultiplayerServerMessage> secondOwnerStream;
  final Stream<MultiplayerServerMessage> observerStream;
  final List<MultiplayerServerMessage> ownerAcks = [];
  final List<MultiplayerServerMessage> ownerEvents = [];
  final List<MultiplayerServerMessage> secondOwnerAcks = [];
  final List<MultiplayerServerMessage> secondOwnerEvents = [];
  final List<MultiplayerServerMessage> observerAcks = [];
  final List<MultiplayerServerMessage> observerEvents = [];
  final List<StreamSubscription<MultiplayerServerMessage>> _subscriptions = [];

  void _recordMessages() {
    _subscriptions
      ..add(
        ownerStream
            .where((message) => message.ack != null)
            .listen(ownerAcks.add),
      )
      ..add(
        ownerStream
            .where((message) => message.event != null)
            .listen(ownerEvents.add),
      )
      ..add(
        secondOwnerStream
            .where((message) => message.ack != null)
            .listen(secondOwnerAcks.add),
      )
      ..add(
        secondOwnerStream
            .where((message) => message.event != null)
            .listen(secondOwnerEvents.add),
      )
      ..add(
        observerStream
            .where((message) => message.ack != null)
            .listen(observerAcks.add),
      )
      ..add(
        observerStream
            .where((message) => message.event != null)
            .listen(observerEvents.add),
      );
  }

  Future<MultiplayerServerMessage> sendOwner(MultiplayerClientMessage message) {
    final acknowledgement = ownerStream.firstWhere(
      (serverMessage) => serverMessage.ack != null,
    );
    ownerInput.add(message);
    return acknowledgement;
  }

  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await ownerInput.close();
    await secondOwnerInput.close();
    await observerInput.close();
  }
}
