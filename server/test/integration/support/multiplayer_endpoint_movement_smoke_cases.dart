part of '../multiplayer_endpoint_smoke.dart';

const _movementMatchId = 'postgres-movement-history';
const _movementOwnerUserId = 'postgres-movement-owner-user';
const _movementOwnerPlayerId = 'postgres-movement-owner-player';
const _movementHiddenUserId = 'postgres-movement-hidden-user';
const _movementHiddenPlayerId = 'postgres-movement-hidden-player';

void _registerMultiplayerEndpointMovementSmokeTests(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) {
  test(
    'round-trips canonical movement and projects recipient-safe history',
    () async {
      final canonical = await _persistCanonicalMovement(sessionBuilder);
      await _expectCanonicalMovementRoundTrip(sessionBuilder, canonical);
      await _expectOwnerMovementHistory(sessionBuilder, endpoints);
      await _expectHiddenMovementHistory(sessionBuilder, endpoints);
    },
  );
}

StoredMatchState _movementHistoryState() {
  return StoredMatchState(
    match: WireMatch(
      id: _movementMatchId,
      ownerUserId: _movementOwnerUserId,
      name: 'PostgreSQL movement history',
      mapName: 'verdantia',
      players: const [
        WirePlayer(
          id: _movementOwnerPlayerId,
          userId: _movementOwnerUserId,
          name: 'Movement owner',
          colorValue: 0,
          kind: WirePlayerKind.human,
          connectionState: WirePlayerConnectionState.connected,
        ),
        WirePlayer(
          id: _movementHiddenPlayerId,
          userId: _movementHiddenUserId,
          name: 'Hidden observer',
          colorValue: 1,
          kind: WirePlayerKind.human,
          connectionState: WirePlayerConnectionState.connected,
        ),
      ],
      maxPlayers: 2,
      minPlayers: 2,
      turn: 1,
      state: 'running',
      createdAt: DateTime.utc(2026, 7, 25),
    ),
    snapshot: const WireSnapshot(
      matchId: _movementMatchId,
      offset: 0,
      save: {},
      state: {},
    ),
  );
}

WireEvent _canonicalMovementHistoryEvent() {
  return WireEvent(
    matchId: _movementMatchId,
    offset: 1,
    timestamp: DateTime.utc(2026, 7, 25, 12),
    actorPlayerId: _movementOwnerPlayerId,
    tick: 1,
    turn: 1,
    command: const {'type': 'postgres-movement-history'},
    movementExecutions: WireMovementExecutionList([
      for (final (fromCol, toCol) in const [(0, 1), (1, 2)])
        WireMovementExecution(
          unitId: 'unit-a',
          fromCol: fromCol,
          fromRow: 0,
          steps: [
            WireMovementStep(
              col: toCol,
              row: 0,
              enterCost: 1,
              cumulativeCost: 1,
            ),
          ],
          serverAudiencePlayerIds: const [_movementOwnerPlayerId],
        ),
    ]),
  );
}

Future<WireEvent> _persistCanonicalMovement(
  TestSessionBuilder sessionBuilder,
) async {
  final initial = _movementHistoryState();
  final canonical = _canonicalMovementHistoryEvent();
  final store = ServerpodMultiplayerMatchStore(sessionBuilder.build());
  await store.createState(initial);
  await store.appendEvent(
    initial.copyWith(
      snapshot: initial.snapshot.copyWith(offset: canonical.offset),
    ),
    canonical,
    actorPlayerId: _movementOwnerPlayerId,
    clientMessageId: _movementMatchId,
  );
  return canonical;
}

Future<void> _expectCanonicalMovementRoundTrip(
  TestSessionBuilder sessionBuilder,
  WireEvent canonical,
) async {
  final store = ServerpodMultiplayerMatchStore(sessionBuilder.build());
  expect((await store.findState(_movementMatchId))!.offset, canonical.offset);
  final roundTripped = (await store.listEvents(_movementMatchId, 0)).single;
  expect(roundTripped, canonical);
  expect(
    roundTripped.movementExecutions.values.map(
      (execution) => execution.serverAudiencePlayerIds,
    ),
    const [
      [_movementOwnerPlayerId],
      [_movementOwnerPlayerId],
    ],
  );
}

Future<void> _expectOwnerMovementHistory(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) async {
  final history = await endpoints.multiplayer.listEvents(
    _authenticatedSession(sessionBuilder, _movementOwnerUserId),
    _movementMatchId,
    0,
  );
  final movements = history.single.movementExecutions;
  expect(movements.values.map(_movementExecutionCoordinates), const [
    'unit-a:0,0->1,0',
    'unit-a:1,0->2,0',
  ]);
  expect(
    movements.values.every(
      (execution) => execution.serverAudiencePlayerIds == null,
    ),
    isTrue,
  );
  expect(
    history.single.toJson().toString(),
    isNot(contains('_serverAudiencePlayerIds')),
  );
}

Future<void> _expectHiddenMovementHistory(
  TestSessionBuilder sessionBuilder,
  TestEndpoints endpoints,
) async {
  final history = await endpoints.multiplayer.listEvents(
    _authenticatedSession(sessionBuilder, _movementHiddenUserId),
    _movementMatchId,
    0,
  );
  expect(history.single.movementExecutions.isEmpty, isTrue);
  expect(
    history.single.toJson(),
    containsPair('movementExecutions', <Object>[]),
  );
  expect(
    history.single.toJson().toString(),
    isNot(contains('_serverAudiencePlayerIds')),
  );
}

String _movementExecutionCoordinates(WireMovementExecution execution) {
  final steps = execution.steps
      .map((step) => '${step.col},${step.row}')
      .join('|');
  return '${execution.unitId}:${execution.fromCol},${execution.fromRow}'
      '->$steps';
}

Map<String, ({int col, int row})> _unitPositionsFor(
  PersistentGameState state,
  String playerId,
) {
  return {
    for (final unit in state.units)
      if (unit.ownerPlayerId == playerId)
        unit.id: (col: unit.col, row: unit.row),
  };
}
