part of '../realtime_match_hub_test.dart';

const _turnMovementClientMessageId = 'turn-movement-final-submit';

Future<WorldTile> _makeMovementVisibleToGuest({
  required _MemoryMatchStore store,
  required StoredMatchState stored,
  required DomainState state,
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
      snapshot: stored.snapshot.copyWith(
        state: CanonicalGameSnapshotCodec.encodeDomainState(visibleState),
      ),
    ),
  );
  return target;
}

void _expectGuestObservedMovement(
  MultiplayerServerMessage message,
  GameUnit ownerUnit,
  WorldTile target,
) {
  final coarseMovement = message.event!.events
      .map(GameEventSerializer.fromJson)
      .whereType<UnitMovedEvent>()
      .single;
  expect(coarseMovement.unitId, ownerUnit.id);
  expect(
    (coarseMovement.fromCol, coarseMovement.fromRow),
    (ownerUnit.col, ownerUnit.row),
  );
  expect(
    (coarseMovement.toCol, coarseMovement.toRow),
    (target.col, target.row),
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
  test(
    'streams the movement event when an exact-path unit leaves the view',
    _streamsMovementEventForExactPathLeavingView,
  );
}

Future<void> _streamsMovementEventForExactPathLeavingView() async {
  final fixture = await _startTurnMovementFixture(
    observerSeesOwnerPathBefore: true,
  );
  final before = await fixture.hub.loadSnapshot(
    store: fixture.store,
    userIdentifier: 'turn-movement-observer',
    matchId: fixture.match.id,
  );
  expect(
    CanonicalGameSnapshotCodec.decodeDomainState(
      before.state,
    ).units.byId('unit-a'),
    isNotNull,
  );

  final clients = await _TurnMovementClients.connect(fixture);
  try {
    final observerEvent = clients.observerStream.firstWhere(
      (message) => message.event != null,
    );
    final acknowledgement = await clients.sendOwner(
      _turnMovementMessage(fixture),
    );
    final streamed = await observerEvent;

    expect(acknowledgement.ack?.accepted, isTrue);
    final after = CanonicalGameSnapshotCodec.decodeDomainState(
      streamed.snapshot!.state,
    );
    expect(after.units.byId('unit-a'), isNull);
    final streamedMovements = streamed.event!.events
        .map(GameEventSerializer.fromJson)
        .whereType<UnitMovedEvent>()
        .toList(growable: false);
    expect(
      streamedMovements
          .map(
            (event) =>
                '${event.unitId}:${event.fromCol},${event.fromRow}'
                '->${event.toCol},${event.toRow}',
          )
          .toList(),
      ['unit-a:0,0->3,0', 'unit-a:1,0->3,0'],
    );
    expect(
      _turnMovementSnapshots(streamed.event!.movementExecutions),
      _expectedOwnerTurnMovements(),
    );
    expect(
      streamed.event!.toJson().toString(),
      isNot(contains('_serverAudiencePlayerIds')),
    );

    final canonical = (await fixture.store.listEvents(
      fixture.match.id,
      0,
    )).single;
    final unitAEvents = canonical.events
        .where((event) {
          final decoded = GameEventSerializer.fromJson(event);
          return decoded is UnitMovedEvent && decoded.unitId == 'unit-a';
        })
        .toList(growable: false);
    expect(unitAEvents, hasLength(2));
    expect(
      unitAEvents.every(
        (event) => (event['_serverAudiencePlayerIds']! as List<Object?>)
            .contains(fixture.observer.id),
      ),
      isTrue,
    );
    expect(
      canonical.movementExecutions.values
          .where((execution) => execution.unitId == 'unit-a')
          .every(
            (execution) => execution.serverAudiencePlayerIds!.contains(
              fixture.observer.id,
            ),
          ),
      isTrue,
    );
  } finally {
    await clients.close();
  }
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
  bool observerSeesOwnerPathBefore = false,
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
  await _seedTurnMovementState(
    fixture,
    observerSeesOwnerPathBefore: observerSeesOwnerPathBefore,
  );
  return fixture;
}

Future<void> _seedTurnMovementState(
  _TurnMovementFixture fixture, {
  required bool observerSeesOwnerPathBefore,
}) async {
  final stored = (await fixture.store.findState(fixture.match.id))!;
  final source = const LosslessMatchSnapshotDecoder()
      .decode(stored.snapshot)
      .canonical
      .domain;
  final save = GameSave.fromJson(stored.snapshot.save).copyWith(
    playerStates: {
      fixture.owner.id: PlayerTurnState.active,
      fixture.unitBPlayer.id: PlayerTurnState.finished,
      fixture.observer.id: PlayerTurnState.finished,
    },
  );
  final state = source.copyWith(
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
        fixture.observer.id: observerSeesOwnerPathBefore
            ? PlayerFogOfWar(
                playerId: fixture.observer.id,
                discoveredHexes: {
                  for (var col = 0; col <= 3; col++)
                    HexCoordinate(col: col, row: 0),
                },
                visibleHexes: {
                  for (var col = 0; col <= 3; col++)
                    HexCoordinate(col: col, row: 0),
                },
              )
            : PlayerFogOfWar(playerId: fixture.observer.id),
      },
    ),

    submittedPlayerIds: {fixture.unitBPlayer.id, fixture.observer.id},
  );
  await fixture.store.saveState(
    stored.copyWith(
      snapshot: stored.snapshot.copyWith(
        save: save.toJson(),
        state: CanonicalGameSnapshotCodec.encodeDomainState(state),
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

WorldMap _turnMovementMap() {
  return WorldMap(
    cols: 6,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 6; col++)
          WorldTile(
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
      command: DomainCommandCodec.toJson(command),
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
