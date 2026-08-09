part of 'lobby_presence_lifecycle_test.dart';

void _registerLobbyPresenceExpiryEdgeCases() {
  test(
    'wraps an exhausted durable presence cursor to the first page',
    () async {
      final now = DateTime.utc(2026, 8, 8, 15, 30);
      final cursor = ExpiredPresenceLeaseCursor(expiresAt: now, rowId: 64);
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore()
        ..scriptedExpiredPresencePages.add(
          ExpiredPresenceLeasePage(candidates: const [], nextCursor: cursor),
        );

      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      store.scriptedExpiredPresencePages.addAll([
        ExpiredPresenceLeasePage(candidates: const [], nextCursor: null),
        ExpiredPresenceLeasePage(candidates: const [], nextCursor: null),
      ]);

      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      expect(store.expiredPresenceCursorRequests, [null, cursor, null]);
    },
  );

  test(
    'reports one failed presence candidate without aborting the sweep',
    () async {
      final now = DateTime.utc(2026, 8, 8, 16);
      final failure = StateError('presence transaction failed');
      final lease = _expiredPresenceLease(now, userIdentifier: 'failed-user');
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore()
        ..scriptedExpiredPresencePages.add(
          ExpiredPresenceLeasePage(
            candidates: [
              ExpiredPresenceLeaseCandidate(
                rowId: 1,
                matchId: 'failed-match',
                lease: lease,
              ),
            ],
            nextCursor: null,
          ),
        )
        ..transactionFailures.add(failure);

      final failures = await hub.expireLobbyPresence(store: store);

      expect(failures, hasLength(1));
      expect(failures.single.matchId, 'failed-match');
      expect(failures.single.userIdentifier, 'failed-user');
      expect(failures.single.error, same(failure));
      expect(failures.single.stackTrace, isNotNull);
    },
  );

  test('removes an expired lease from a terminal match', () async {
    final now = DateTime.utc(2026, 8, 8, 16, 30);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _LobbyPresenceStore();
    await store.createState(
      _presenceSweepState(
        matchId: 'terminal-match',
        now: now,
        state: 'abandoned',
        leaseUserIdentifier: 'owner-user',
        players: [_presencePlayer('owner-user')],
      ),
    );

    expect(await hub.expireLobbyPresence(store: store), isEmpty);
    expect((await store.findState('terminal-match'))!.presenceLeases, isEmpty);
  });

  test(
    'expires missing, offline, and connected running participants',
    () async {
      final now = DateTime.utc(2026, 8, 8, 17);
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore();
      await store.createState(
        _presenceSweepState(
          matchId: 'missing-running-player',
          now: now,
          state: 'running',
          leaseUserIdentifier: 'missing-user',
          players: const [],
        ),
      );
      await store.createState(
        _presenceSweepState(
          matchId: 'offline-running-player',
          now: now,
          state: 'running',
          leaseUserIdentifier: 'offline-user',
          players: [
            _presencePlayer(
              'offline-user',
              connectionState: WirePlayerConnectionState.offline,
            ),
          ],
        ),
      );
      await store.createState(
        _presenceSweepState(
          matchId: 'connected-running-player',
          now: now,
          state: 'running',
          leaseUserIdentifier: 'connected-user',
          players: [_presencePlayer('connected-user')],
        ),
      );

      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      for (final matchId in [
        'missing-running-player',
        'offline-running-player',
        'connected-running-player',
      ]) {
        expect((await store.findState(matchId))!.presenceLeases, isEmpty);
      }
      expect(
        (await store.findState(
          'connected-running-player',
        ))!.match.players.single.connectionState,
        WirePlayerConnectionState.offline,
      );
    },
  );
}

StoredMatchPresenceLease _expiredPresenceLease(
  DateTime now, {
  required String userIdentifier,
}) {
  return StoredMatchPresenceLease(
    userIdentifier: userIdentifier,
    connectionGeneration: 'expired-generation-$userIdentifier',
    expiresAt: now.subtract(const Duration(seconds: 1)),
    updatedAt: now.subtract(const Duration(minutes: 1)),
  );
}

WirePlayer _presencePlayer(
  String userIdentifier, {
  WirePlayerConnectionState connectionState =
      WirePlayerConnectionState.connected,
}) {
  return WirePlayer(
    id: 'player-$userIdentifier',
    userId: userIdentifier,
    name: userIdentifier,
    colorValue: 0,
    country: PlayerCountry.poland,
    kind: WirePlayerKind.human,
    connectionState: connectionState,
  );
}

StoredMatchState _presenceSweepState({
  required String matchId,
  required DateTime now,
  required String state,
  required String leaseUserIdentifier,
  required List<WirePlayer> players,
}) {
  final terminal = state == 'abandoned';
  return StoredMatchState(
    match: WireMatch(
      id: matchId,
      ownerUserId: 'owner-user',
      name: 'Presence sweep',
      mapName: 'verdantia',
      players: players,
      maxPlayers: 4,
      minPlayers: 2,
      quickplay: false,
      turn: state == 'running' ? 1 : 0,
      state: state,
      createdAt: now.subtract(const Duration(hours: 1)),
      endedAt: terminal ? now : null,
    ),
    snapshot: WireSnapshot(
      matchId: matchId,
      offset: 0,
      save: const {},
      state: {
        'phase': terminal ? 'abandoned' : state,
        if (terminal) 'reason': 'owner_left',
        if (state == 'running')
          'lastHumanActivityAt': now
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
      },
    ),
    presenceLeases: {
      leaseUserIdentifier: _expiredPresenceLease(
        now,
        userIdentifier: leaseUserIdentifier,
      ),
    },
  );
}
