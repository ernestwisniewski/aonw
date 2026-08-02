part of '../realtime_match_hub_test.dart';

final class _DiplomacyMatchFixture {
  const _DiplomacyMatchFixture({
    required this.hub,
    required this.store,
    required this.match,
    required this.owner,
    required this.guest,
  });

  final RealtimeMatchHub hub;
  final _MemoryMatchStore store;
  final WireMatch match;
  final WirePlayer owner;
  final WirePlayer guest;
}

Future<_DiplomacyMatchFixture> _createDiplomacyMatchFixture() async {
  final mapCatalog = _FakeMapCatalog(_testMap());
  final hub = RealtimeMatchHub(
    commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
  );
  final store = _MemoryMatchStore();
  final openMatch = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user',
    request: CreateMatchRequest(
      name: 'Diplomacy match',
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
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
  final owner = match.players.first;
  final guest = match.players.last;
  final stored = (await store.findState(match.id))!;
  final baseState = CanonicalGameSnapshotCodec.decodeDomainState(
    stored.snapshot.state,
  );
  final patchedState = baseState.copyWith(
    playerGold: {owner.id: 20, guest.id: 0},
    diplomacy: DiplomacyState.empty.addContact(owner.id, guest.id),
  );
  await store.saveState(
    stored.copyWith(
      snapshot: stored.snapshot.copyWith(
        state: CanonicalGameSnapshotCodec.encodeDomainState(patchedState),
      ),
    ),
  );
  return _DiplomacyMatchFixture(
    hub: hub,
    store: store,
    match: match,
    owner: owner,
    guest: guest,
  );
}
