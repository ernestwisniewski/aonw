part of '../realtime_match_hub_test.dart';

Future<WireMatch> _startRunningMatchInStore({
  required RealtimeMatchHub hub,
  required _MemoryMatchStore store,
  required String suffix,
  required _FakeMapCatalog mapCatalog,
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
  final joined = await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-user-$suffix',
    matchId: openMatch.id,
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

MapData _realtimeMatchHubFixtureMap() {
  return MapData(
    cols: 6,
    rows: 6,
    tiles: [
      for (var col = 0; col < 6; col++)
        for (var row = 0; row < 6; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}
