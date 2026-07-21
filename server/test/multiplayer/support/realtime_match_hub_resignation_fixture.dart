part of '../realtime_match_hub_test.dart';

Future<WireMatch> _startRunningFfaMatchInStore({
  required RealtimeMatchHub hub,
  required _MemoryMatchStore store,
  required String suffix,
  required _FakeMapCatalog mapCatalog,
}) async {
  final openMatch = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    request: CreateMatchRequest(
      name: 'Running FFA $suffix',
      mapName: 'verdantia',
      maxPlayers: 3,
      minPlayers: 3,
      private: false,
    ),
  );
  await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-one-$suffix',
    matchId: openMatch.id,
  );
  final joined = await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-two-$suffix',
    matchId: openMatch.id,
  );
  return hub.startMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    matchId: joined.id,
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
}

Future<void> _eliminatePlayersInStoredMatch({
  required _MemoryMatchStore store,
  required String matchId,
  required Set<String> playerIds,
}) async {
  final stored = (await store.findState(matchId))!;
  final state = PersistentGameState.fromJson(stored.snapshot.state);
  await store.saveState(
    stored.copyWith(
      snapshot: stored.snapshot.copyWith(
        state: state
            .copyWith(
              units: state.units
                  .where((unit) => !playerIds.contains(unit.ownerPlayerId))
                  .toList(),
              cities: state.cities
                  .where((city) => !playerIds.contains(city.ownerPlayerId))
                  .toList(),
            )
            .toJson(),
      ),
    ),
  );
}

Future<_ResignationFixture> _createResignationFixture(
  String suffix, {
  DateTime? endedAt,
}) async {
  final mapCatalog = _FakeMapCatalog(_testMap());
  final effectiveEndedAt = endedAt ?? DateTime.utc(2026, 7, 21, 12);
  final hub = RealtimeMatchHub(
    commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    nowUtc: () => effectiveEndedAt,
  );
  final store = _ResignationMatchStore();
  final match = await _startRunningFfaMatchInStore(
    hub: hub,
    store: store,
    suffix: suffix,
    mapCatalog: mapCatalog,
  );
  final canonicalMatch = (await store.findState(match.id))!.match;
  return _ResignationFixture(
    suffix: suffix,
    endedAt: effectiveEndedAt,
    hub: hub,
    store: store,
    match: canonicalMatch,
  );
}

final class _ResignationFixture {
  const _ResignationFixture({
    required this.suffix,
    required this.endedAt,
    required this.hub,
    required this.store,
    required this.match,
  });

  final String suffix;
  final DateTime endedAt;
  final RealtimeMatchHub hub;
  final _ResignationMatchStore store;
  final WireMatch match;

  WirePlayer player(String role) =>
      match.players.firstWhere((player) => player.userId == '$role-$suffix');

  Future<StoredMatchState> state() async => (await store.findState(match.id))!;

  Future<WireMatch> resign(WirePlayer player) => hub.resignMatch(
    store: store,
    userIdentifier: player.userId,
    matchId: match.id,
  );
}

final class _ResignationMatchStore extends _MemoryMatchStore {
  int saveStateCalls = 0;

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) async {
    saveStateCalls++;
    return super.saveState(state);
  }
}
