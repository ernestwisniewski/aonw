part of '../realtime_match_hub_test.dart';

final class _PartialTurnTimeoutFixture {
  const _PartialTurnTimeoutFixture({
    required this.hub,
    required this.store,
    required this.started,
    required this.running,
    required this.ownerPlayerId,
    required this.guestPlayerId,
    required this.advanceClock,
    required this.now,
  });

  final RealtimeMatchHub hub;
  final TestMatchStore store;
  final WireMatch started;
  final StoredMatchState running;
  final String ownerPlayerId;
  final String guestPlayerId;
  final void Function() advanceClock;
  final DateTime Function() now;
}

Future<_PartialTurnTimeoutFixture> _partialTurnTimeoutFixture() async {
  final mapCatalog = TestMapCatalog(testMap());
  var now = DateTime.utc(2026, 6, 30, 12);
  final hub = RealtimeMatchHub(
    commandReducer: ServerCommandReducer(
      mapCatalog: mapCatalog,
      turnTimeout: const Duration(seconds: 10),
    ),
    nowUtc: () => now,
  );
  final store = TestMatchStore();
  final match = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user',
    request: CreateMatchRequest(
      name: 'Timeout match',
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
    matchId: match.id,
  );
  await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-user',
    matchId: match.id,
  );
  await _connectTestParticipant(
    hub: hub,
    store: store,
    userIdentifier: 'guest-user',
    matchId: match.id,
  );
  final started = await hub.startMatch(
    store: store,
    userIdentifier: 'owner-user',
    matchId: match.id,
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
  final running = (await store.findState(started.id))!;
  final ownerPlayerId = running.match.players
      .firstWhere((player) => player.userId == 'owner-user')
      .id;
  final guestPlayerId = running.match.players
      .firstWhere((player) => player.userId == 'guest-user')
      .id;
  await store.saveState(
    _partialTurnState(
      running,
      ownerPlayerId: ownerPlayerId,
      guestPlayerId: guestPlayerId,
      now: now,
    ),
  );
  return _PartialTurnTimeoutFixture(
    hub: hub,
    store: store,
    started: started,
    running: running,
    ownerPlayerId: ownerPlayerId,
    guestPlayerId: guestPlayerId,
    advanceClock: () => now = now.add(const Duration(seconds: 11)),
    now: () => now,
  );
}

StoredMatchState _partialTurnState(
  StoredMatchState running, {
  required String ownerPlayerId,
  required String guestPlayerId,
  required DateTime now,
}) {
  final save = GameSave.fromJson(running.snapshot.save);
  final state = CanonicalGameSnapshotCodec.decodeDomainState(
    running.snapshot.state,
  );
  return running.copyWith(
    snapshot: running.snapshot.copyWith(
      save: save
          .copyWith(
            playerStates: {
              ...save.playerStates,
              ownerPlayerId: PlayerTurnState.finished,
            },
          )
          .toJson(),
      state: state
          .copyWith(
            playerGold: {ownerPlayerId: 111, guestPlayerId: 999},
            units: state.units
                .where((unit) => unit.ownerPlayerId != guestPlayerId)
                .toList(),
            cities: state.cities
                .where((city) => city.ownerPlayerId != guestPlayerId)
                .toList(),
            submittedPlayerIds: {ownerPlayerId},
            turnStartedAt: now,
          )
          .toJson(),
    ),
  );
}
