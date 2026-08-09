part of '../realtime_match_hub_test.dart';

const _drawOutcomeSuffix = 'draw-outcome';
const _drawOutcomeTurn = GameLengthConfig.standard60TurnLimit;

typedef _DrawOutcomeClients = ({
  StreamController<MultiplayerClientMessage> ownerInput,
  StreamController<MultiplayerClientMessage> guestInput,
  Stream<MultiplayerServerMessage> ownerStream,
  Stream<MultiplayerServerMessage> guestStream,
});

typedef _DrawOutcomeMessages = ({
  MultiplayerServerMessage caller,
  MultiplayerServerMessage peer,
});

typedef _TerminalMatchMetadata = ({
  int turn,
  String state,
  DateTime? endedAt,
  String? outcomeCondition,
  String? winnerPlayerId,
});

typedef _NaturalOutcomeFixture = ({
  DateTime endedAt,
  RealtimeMatchHub hub,
  TestMatchStore store,
  WireMatch match,
  WirePlayer owner,
  WirePlayer guest,
});

typedef _NaturalOutcomeClient = ({
  StreamController<MultiplayerClientMessage> input,
  Stream<MultiplayerServerMessage> stream,
});

void _registerRealtimeMatchHubOutcomeTests() {
  test(
    'broadcasts identical draw terminal metadata to caller and peer',
    _verifyDrawTerminalMetadata,
  );

  test(
    'persists a natural outcome and closes its stale presence stream',
    _verifyNaturalOutcomePersistence,
  );
}

Future<void> _verifyNaturalOutcomePersistence() async {
  final fixture = await _startNaturalOutcomeFixture();
  await _seedNaturalOutcome(fixture);
  final client = await _connectNaturalOutcomeClient(fixture);
  try {
    final authoritative = await _finishNaturalOutcome(
      fixture: fixture,
      client: client,
    );
    await _expectNaturalOutcomeStreamClosed(
      client: client,
      authoritativeOffset: authoritative.offset,
    );
    await _expectNaturalOutcomeSurvivesLeave(fixture);
  } finally {
    await client.input.close();
  }
}

Future<_NaturalOutcomeFixture> _startNaturalOutcomeFixture() async {
  final endedAt = DateTime.utc(2026, 7, 12, 17);
  final mapCatalog = TestMapCatalog(testMap());
  final hub = RealtimeMatchHub(
    commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    nowUtc: () => endedAt,
  );
  final store = TestMatchStore();
  final open = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user',
    request: CreateMatchRequest(
      name: 'Natural outcome',
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
    matchId: open.id,
  );
  final joined = await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-user',
    matchId: open.id,
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
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
  return (
    endedAt: endedAt,
    hub: hub,
    store: store,
    match: match,
    owner: match.players.first,
    guest: match.players.last,
  );
}

Future<void> _seedNaturalOutcome(_NaturalOutcomeFixture fixture) async {
  final stored = (await fixture.store.findState(fixture.match.id))!;
  final state = CanonicalGameSnapshotCodec.decodeDomainState(
    stored.snapshot.state,
  );
  await fixture.store.saveState(
    stored.copyWith(
      snapshot: stored.snapshot.copyWith(
        state: state
            .copyWith(
              units: state.units
                  .where((unit) => unit.ownerPlayerId != fixture.guest.id)
                  .toList(),
              cities: state.cities
                  .where((city) => city.ownerPlayerId != fixture.guest.id)
                  .toList(),
            )
            .toJson(),
      ),
    ),
  );
}

Future<_NaturalOutcomeClient> _connectNaturalOutcomeClient(
  _NaturalOutcomeFixture fixture,
) async {
  final input = StreamController<MultiplayerClientMessage>();
  final stream = fixture.hub
      .connect(
        store: fixture.store,
        userIdentifier: fixture.owner.userId,
        matchId: fixture.match.id,
        afterOffset: 0,
        input: input.stream,
      )
      .asBroadcastStream();
  await stream.first;
  return (input: input, stream: stream);
}

Future<StoredMatchState> _finishNaturalOutcome({
  required _NaturalOutcomeFixture fixture,
  required _NaturalOutcomeClient client,
}) async {
  final finishedAck = client.stream.firstWhere(
    (message) => message.ack != null,
  );
  final finishingCommand = _naturalOutcomeCommand(fixture);
  client.input.add(finishingCommand);
  final finishMessage = await finishedAck;
  final authoritative = (await fixture.store.findState(fixture.match.id))!;

  expect(finishMessage.ack!.accepted, isTrue);
  expect(finishMessage.match?.state, 'finished');
  expect(authoritative.match.state, 'finished');
  expect(authoritative.match.endedAt, fixture.endedAt);
  expect(authoritative.match.outcomeCondition, 'conquest');
  expect(authoritative.match.winnerPlayerId, fixture.owner.id);
  expect(authoritative.snapshot.state['phase'], 'finished');
  return authoritative;
}

MultiplayerClientMessage _naturalOutcomeCommand(
  _NaturalOutcomeFixture fixture,
) {
  return MultiplayerClientMessage(
    clientMessageId: 'natural-outcome-command',
    lastSeenOffset: 0,
    requestSnapshot: false,
    command: WireCommand(
      matchId: fixture.match.id,
      tick: 1,
      turn: 1,
      actorPlayerId: fixture.owner.id,
      command: DomainCommandCodec.toJson(SubmitTurnCommand(fixture.owner.id)),
    ),
  );
}

Future<void> _expectNaturalOutcomeStreamClosed({
  required _NaturalOutcomeClient client,
  required int authoritativeOffset,
}) async {
  final error = Completer<Object>();
  final done = Completer<void>();
  final messages = <MultiplayerServerMessage>[];
  final monitor = client.stream.listen(
    messages.add,
    onError: (Object value) {
      if (!error.isCompleted) error.complete(value);
    },
    onDone: done.complete,
  );
  client.input.add(
    MultiplayerClientMessage(
      clientMessageId: 'heartbeat-after-finish',
      lastSeenOffset: authoritativeOffset,
      requestSnapshot: true,
    ),
  );

  expect(
    await error.future.timeout(const Duration(seconds: 1)),
    _multiplayerError('not_match_player'),
  );
  await done.future.timeout(const Duration(seconds: 1));
  expect(messages, isEmpty);
  await monitor.cancel();
}

Future<void> _expectNaturalOutcomeSurvivesLeave(
  _NaturalOutcomeFixture fixture,
) async {
  await fixture.hub.leaveMatch(
    store: fixture.store,
    userIdentifier: fixture.owner.userId,
    matchId: fixture.match.id,
  );
  final afterLeave = (await fixture.store.findState(fixture.match.id))!.match;

  expect(afterLeave.state, 'finished');
  expect(afterLeave.outcomeCondition, 'conquest');
  expect(afterLeave.winnerPlayerId, fixture.owner.id);
}

Future<void> _verifyDrawTerminalMetadata() async {
  final fixture = await _startRunningMatch(_drawOutcomeSuffix);
  final owner = fixture.match.players.first;
  final guest = fixture.match.players.last;
  await _seedDrawOutcome(fixture: fixture, owner: owner, guest: guest);
  final clients = await _connectDrawOutcomeClients(fixture);
  try {
    final messages = await _finishDrawOutcome(
      fixture: fixture,
      owner: owner,
      clients: clients,
    );
    await _expectDrawTerminalMetadata(fixture: fixture, messages: messages);
  } finally {
    await clients.ownerInput.close();
    await clients.guestInput.close();
  }
}

Future<void> _seedDrawOutcome({
  required _RunningMatchFixture fixture,
  required WirePlayer owner,
  required WirePlayer guest,
}) async {
  final stored = (await fixture.store.findState(fixture.match.id))!;
  final save = GameSave.fromJson(stored.snapshot.save);
  final domain = const LosslessMatchSnapshotDecoder()
      .decode(stored.snapshot)
      .canonical
      .domain;
  await fixture.store.saveState(
    stored.copyWith(
      match: stored.match.copyWith(turn: _drawOutcomeTurn),
      snapshot: stored.snapshot.copyWith(
        save: save
            .copyWith(
              turn: _drawOutcomeTurn,
              matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
            )
            .toJson(),
        state: _drawOutcomeState(
          source: domain,
          owner: owner,
          guest: guest,
        ).toJson(),
      ),
    ),
  );
}

DomainState _drawOutcomeState({
  required DomainState source,
  required WirePlayer owner,
  required WirePlayer guest,
}) {
  return source.copyWith(
    units: [
      GameUnit(
        id: 'draw_owner_unit',
        ownerPlayerId: owner.id,
        type: GameUnitType.warrior,
        name: 'Owner unit',
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'draw_guest_unit',
        ownerPlayerId: guest.id,
        type: GameUnitType.warrior,
        name: 'Guest unit',
        col: 1,
        row: 0,
      ),
    ],
  );
}

Future<_DrawOutcomeClients> _connectDrawOutcomeClients(
  _RunningMatchFixture fixture,
) async {
  final ownerInput = StreamController<MultiplayerClientMessage>();
  final guestInput = StreamController<MultiplayerClientMessage>();
  final ownerStream = fixture.hub
      .connect(
        store: fixture.store,
        userIdentifier: 'owner-user-$_drawOutcomeSuffix',
        matchId: fixture.match.id,
        afterOffset: 0,
        input: ownerInput.stream,
      )
      .asBroadcastStream();
  final guestStream = fixture.hub
      .connect(
        store: fixture.store,
        userIdentifier: 'guest-user-$_drawOutcomeSuffix',
        matchId: fixture.match.id,
        afterOffset: 0,
        input: guestInput.stream,
      )
      .asBroadcastStream();
  await Future.wait([ownerStream.first, guestStream.first]);
  return (
    ownerInput: ownerInput,
    guestInput: guestInput,
    ownerStream: ownerStream,
    guestStream: guestStream,
  );
}

Future<_DrawOutcomeMessages> _finishDrawOutcome({
  required _RunningMatchFixture fixture,
  required WirePlayer owner,
  required _DrawOutcomeClients clients,
}) async {
  final callerTerminal = clients.ownerStream.firstWhere(
    (message) => message.ack?.accepted == true && message.match != null,
  );
  final peerTerminal = clients.guestStream.firstWhere(
    (message) => message.event != null && message.match != null,
  );
  clients.ownerInput.add(
    MultiplayerClientMessage(
      clientMessageId: 'draw-outcome-command',
      lastSeenOffset: 0,
      requestSnapshot: false,
      command: WireCommand(
        matchId: fixture.match.id,
        tick: 1,
        turn: _drawOutcomeTurn,
        actorPlayerId: owner.id,
        command: DomainCommandCodec.toJson(
          const SkipUnitTurnCommand('draw_owner_unit'),
        ),
      ),
    ),
  );
  final messages = await Future.wait([callerTerminal, peerTerminal]);
  return (caller: messages.first, peer: messages.last);
}

Future<void> _expectDrawTerminalMetadata({
  required _RunningMatchFixture fixture,
  required _DrawOutcomeMessages messages,
}) async {
  final callerMatch = messages.caller.match!;
  final peerMatch = messages.peer.match!;
  final authoritative = (await fixture.store.findState(fixture.match.id))!;
  final callerMetadata = _terminalMetadata(callerMatch);

  expect(callerMatch.state, 'finished');
  expect(callerMatch.outcomeCondition, 'draw');
  expect(callerMatch.winnerPlayerId, isNull);
  expect(callerMatch.endedAt, isNotNull);
  expect(_terminalMetadata(peerMatch), callerMetadata);
  expect(_terminalMetadata(authoritative.match), callerMetadata);
  expect(messages.caller.ack!.snapshot.state['phase'], 'finished');
  expect(messages.peer.snapshot!.state['phase'], 'finished');
}

_TerminalMatchMetadata _terminalMetadata(WireMatch match) {
  return (
    turn: match.turn,
    state: match.state,
    endedAt: match.endedAt,
    outcomeCondition: match.outcomeCondition,
    winnerPlayerId: match.winnerPlayerId,
  );
}
