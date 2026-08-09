part of '../realtime_match_hub_test.dart';

abstract interface class TestMatchConnectionView {
  StreamController<MultiplayerClientMessage> get input;
  Stream<MultiplayerServerMessage> get stream;
  MultiplayerServerMessage get initialMessage;
  Future<void> close();
}

final class _TestMatchConnection implements TestMatchConnectionView {
  _TestMatchConnection({
    required this.input,
    required this.stream,
    required this.initialMessage,
  });

  @override
  final StreamController<MultiplayerClientMessage> input;
  @override
  final Stream<MultiplayerServerMessage> stream;
  @override
  final MultiplayerServerMessage initialMessage;
  var _closed = false;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await input.close();
  }
}

Future<TestMatchConnectionView> connectTestParticipantForTest({
  required RealtimeMatchHub hub,
  required MultiplayerMatchStore store,
  required String userIdentifier,
  required String matchId,
  int afterOffset = 0,
}) {
  return _connectTestParticipant(
    hub: hub,
    store: store,
    userIdentifier: userIdentifier,
    matchId: matchId,
    afterOffset: afterOffset,
  );
}

Future<WorldTile> makeMovementVisibleToGuestForTest({
  required TestMatchStore store,
  required StoredMatchState stored,
  required DomainState state,
  required GameUnit ownerUnit,
  required String guestId,
}) => _makeMovementVisibleToGuest(
  store: store,
  stored: stored,
  state: state,
  ownerUnit: ownerUnit,
  guestId: guestId,
);

void expectGuestObservedMovementForTest(
  MultiplayerServerMessage message,
  GameUnit ownerUnit,
  WorldTile target,
) => _expectGuestObservedMovement(message, ownerUnit, target);

Future<_TestMatchConnection> _connectTestParticipant({
  required RealtimeMatchHub hub,
  required MultiplayerMatchStore store,
  required String userIdentifier,
  required String matchId,
  int afterOffset = 0,
}) async {
  final input = StreamController<MultiplayerClientMessage>();
  final stream = hub
      .connect(
        store: store,
        userIdentifier: userIdentifier,
        matchId: matchId,
        afterOffset: afterOffset,
        input: input.stream,
      )
      .asBroadcastStream();
  final initialMessage = await stream.first.timeout(const Duration(seconds: 1));
  final connection = _TestMatchConnection(
    input: input,
    stream: stream,
    initialMessage: initialMessage,
  );
  addTearDown(connection.close);
  return connection;
}

extension _DomainStateTestJson on DomainState {
  Map<String, dynamic> toJson() =>
      CanonicalGameSnapshotCodec.encodeDomainState(this);
}

final class _CreateConflictOnceMatchStore extends TestMatchStore {
  var _conflictPending = true;

  @override
  Future<StoredMatchState> createState(StoredMatchState state) {
    if (_conflictPending && state.match.inviteCode != null) {
      _conflictPending = false;
      throw const InviteCodeConflictException();
    }
    return super.createState(state);
  }
}

final class _SequenceInviteCodeGenerator implements InviteCodeGenerator {
  _SequenceInviteCodeGenerator(this._codes);

  final List<String> _codes;
  var calls = 0;

  @override
  String generate() {
    final code = _codes[calls.clamp(0, _codes.length - 1)];
    calls += 1;
    return code;
  }
}

bool _isActiveMatch(WireMatch match) =>
    match.state == 'open' || match.state == 'running';

bool _isAfterRunningCursor(WireMatch match, RunningMatchCursor? cursor) {
  if (cursor == null) return true;
  final createdAtOrder = match.createdAt.compareTo(cursor.createdAt);
  return createdAtOrder > 0 ||
      (createdAtOrder == 0 && match.id.compareTo(cursor.publicId) > 0);
}

int _compareTestMatchesNewestFirst(WireMatch first, WireMatch second) {
  final createdAtOrder = second.createdAt.compareTo(first.createdAt);
  if (createdAtOrder != 0) return createdAtOrder;
  return second.id.compareTo(first.id);
}

class TestMapCatalog implements MultiplayerMapCatalog {
  const TestMapCatalog(this.mapData);

  final WorldMap mapData;

  @override
  Future<WorldMap> loadAssetMap(String mapName) async => mapData;
}

WorldMap testMap() => _realtimeMatchHubFixtureMap();

Future<WireMatch> startRunningTestMatch({
  required RealtimeMatchHub hub,
  required TestMatchStore store,
  required String suffix,
  required TestMapCatalog mapCatalog,
}) async {
  final openMatch = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    request: CreateMatchRequest(
      name: 'Running match $suffix',
      mapName: 'verdantia',
      maxPlayers: 2,
      minPlayers: 2,
      private: false,
    ),
  );
  await _connectTestParticipant(
    hub: hub,
    store: store,
    userIdentifier: 'owner-user-$suffix',
    matchId: openMatch.id,
  );
  final joined = await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-user-$suffix',
    matchId: openMatch.id,
  );
  await _connectTestParticipant(
    hub: hub,
    store: store,
    userIdentifier: 'guest-user-$suffix',
    matchId: joined.id,
  );
  return hub.startMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    matchId: joined.id,
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
}

String _clientMessageKey(
  String matchId,
  String actorPlayerId,
  String clientMessageId,
) => '$matchId:$actorPlayerId:$clientMessageId';

WorldMap _realtimeMatchHubFixtureMap() {
  return WorldMap(
    cols: 6,
    rows: 6,
    tiles: [
      for (var col = 0; col < 6; col++)
        for (var row = 0; row < 6; row++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}
