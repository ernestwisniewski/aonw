part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubQueryListingsScenarios() {
  test('retires incompatible matches and noncanonical player ids', () async {
    final hub = RealtimeMatchHub();
    final store = TestMatchStore();
    final noncanonical = await hub.createMatch(
      store: store,
      userIdentifier: 'embedded-account-owner',
      request: CreateMatchRequest(
        name: 'Noncanonical identifiers',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final stale = await hub.createMatch(
      store: store,
      userIdentifier: 'stale-owner',
      request: CreateMatchRequest(
        name: 'Stale protocol',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final noncanonicalState = (await store.findState(noncanonical.id))!;
    await store.saveState(
      noncanonicalState.copyWith(
        match: noncanonicalState.match.copyWith(
          quickplay: true,
          players: [
            noncanonicalState.match.players.single.copyWith(
              id: 'player-1-embedded-account-owner',
            ),
          ],
        ),
      ),
    );
    final staleState = (await store.findState(stale.id))!;
    await store.saveState(
      staleState.copyWith(
        match: staleState.match.copyWith(v: kProtocolVersion - 1),
        snapshot: staleState.snapshot.copyWith(v: kSnapshotEventVersion - 1),
      ),
    );

    expect(
      await hub.listMatches(
        store: store,
        userIdentifier: 'embedded-account-owner',
      ),
      isEmpty,
    );
    for (final entry in [
      (matchId: noncanonical.id, userId: 'embedded-account-owner'),
      (matchId: stale.id, userId: 'stale-owner'),
    ]) {
      await expectLater(
        hub.loadSnapshot(
          store: store,
          userIdentifier: entry.userId,
          matchId: entry.matchId,
        ),
        throwsA(_multiplayerError('unsupported_match_protocol')),
      );
    }

    final replacement = await hub.quickplay(
      store: store,
      userIdentifier: 'replacement-owner',
      request: CreateMatchRequest(
        name: 'Replacement quickplay',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    expect(replacement.id, isNot(noncanonical.id));
    final retired = (await store.findState(noncanonical.id))!;
    expect(retired.match.state, 'abandoned');
    expect(retired.snapshot.state['reason'], 'protocol_upgrade');
  });
}
