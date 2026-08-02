import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';

final matchStoreFixtureCreatedAt = DateTime.utc(2026, 8, 1, 12);

WirePlayer matchStorePlayer({
  String id = 'player-1',
  String userId = 'user-1',
  String name = 'Player one',
  bool ready = true,
}) => WirePlayer(
  id: id,
  userId: userId,
  name: name,
  colorValue: 0xFF123456,
  kind: WirePlayerKind.human,
  connectionState: WirePlayerConnectionState.connected,
  ready: ready,
);

WireMatch matchStoreMatch({
  String id = 'match-1',
  String ownerUserId = 'user-1',
  String state = 'open',
  DateTime? createdAt,
  List<WirePlayer>? players,
  int maxPlayers = 4,
  String? inviteCode,
}) => WireMatch(
  id: id,
  ownerUserId: ownerUserId,
  name: 'Fixture match $id',
  mapName: 'verdantia',
  players: players ?? [matchStorePlayer()],
  maxPlayers: maxPlayers,
  minPlayers: 2,
  quickplay: true,
  turn: 3,
  state: state,
  createdAt: createdAt ?? matchStoreFixtureCreatedAt,
  inviteCode: inviteCode,
);

GamePlayer matchStorePlayerRow({
  int id = 11,
  int matchId = 7,
  String publicPlayerId = 'player-1',
  String userIdentifier = 'user-1',
  String countryId = 'poland',
  int seatOrder = 0,
}) => GamePlayer(
  id: id,
  matchId: matchId,
  publicPlayerId: publicPlayerId,
  userIdentifier: userIdentifier,
  displayName: 'Player $publicPlayerId',
  colorValue: 0xFF123456,
  countryId: countryId,
  kind: WirePlayerKind.human.name,
  connectionState: WirePlayerConnectionState.connected.name,
  ready: true,
  seatOrder: seatOrder,
);

GameMatch matchStoreRow({
  int id = 7,
  String publicId = 'match-1',
  String ownerUserIdentifier = 'user-1',
  String state = 'open',
  DateTime? createdAt,
  List<GamePlayer>? players,
  List<GameSnapshot>? snapshots,
  int maxPlayers = 4,
  String? inviteCode,
}) => GameMatch(
  id: id,
  publicId: publicId,
  ownerUserIdentifier: ownerUserIdentifier,
  name: 'Fixture match $publicId',
  mapName: 'verdantia',
  state: state,
  turn: 3,
  maxPlayers: maxPlayers,
  minPlayers: 2,
  private: inviteCode != null,
  quickplay: true,
  createdAt: createdAt ?? matchStoreFixtureCreatedAt,
  inviteCode: inviteCode,
  players: players,
  snapshots: snapshots,
);

WireSnapshot matchStoreSnapshot({int offset = 4, String matchId = 'match-1'}) =>
    WireSnapshot(
      matchId: matchId,
      offset: offset,
      save: const {'turn': 3},
      state: const {'phase': 'running'},
    );

GameSnapshot matchStoreSnapshotRow({
  int id = 17,
  int matchId = 7,
  int offset = 4,
  WireSnapshot? snapshot,
}) => GameSnapshot(
  id: id,
  matchId: matchId,
  offset: offset,
  snapshot: snapshot ?? matchStoreSnapshot(offset: offset),
  createdAt: matchStoreFixtureCreatedAt,
);

WireEvent matchStoreEvent({int offset = 5}) => WireEvent(
  matchId: 'match-1',
  offset: offset,
  timestamp: matchStoreFixtureCreatedAt,
  actorPlayerId: 'player-1',
  tick: offset,
  turn: 3,
  command: const {'type': 'endTurn'},
  movementExecutions: WireMovementExecutionList([]),
);

GameEvent matchStoreEventRow({int offset = 5}) => GameEvent(
  id: 20 + offset,
  matchId: 7,
  offset: offset,
  actorPlayerId: 'player-1',
  clientMessageId: 'message-$offset',
  event: matchStoreEvent(offset: offset),
  createdAt: matchStoreFixtureCreatedAt,
);
