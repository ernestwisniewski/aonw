part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubLobbyErrorScenarios() {
  test(
    'throws typed multiplayer exceptions for rejected lobby actions',
    () async {
      final hub = RealtimeMatchHub();
      final store = _MemoryMatchStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Tiny match',
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
        userIdentifier: 'filler-user',
        matchId: match.id,
      );

      await expectLater(
        hub.joinMatch(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
        ),
        throwsA(_multiplayerError('match_full')),
      );
      await expectLater(
        hub.joinPrivateMatch(
          store: store,
          userIdentifier: 'guest-user',
          inviteCode: 'missing',
        ),
        throwsA(_multiplayerError('private_match_not_found')),
      );
      await expectLater(
        hub.startMatch(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
        ),
        throwsA(_multiplayerError('not_match_owner')),
      );
      await expectLater(
        hub.loadMatch(
          store: store,
          userIdentifier: 'owner-user',
          matchId: 'missing-match',
        ),
        throwsA(_multiplayerError('match_not_found')),
      );
      await expectLater(
        hub.loadMatch(
          store: store,
          userIdentifier: 'stranger-user',
          matchId: match.id,
        ),
        throwsA(_multiplayerError('not_match_player')),
      );
    },
  );

  test('rejects joins for private and non-open matches', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final publicMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'public-owner',
      request: CreateMatchRequest(
        name: 'Public lobby',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: false,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'public-owner',
      matchId: publicMatch.id,
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'public-guest',
      matchId: publicMatch.id,
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'public-guest',
      matchId: publicMatch.id,
    );
    final runningPublic = await hub.startMatch(
      store: store,
      userIdentifier: 'public-owner',
      matchId: publicMatch.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );

    await expectLater(
      hub.joinMatch(
        store: store,
        userIdentifier: 'late-public-guest',
        matchId: runningPublic.id,
      ),
      throwsA(_multiplayerError('match_not_open')),
    );

    final privateMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'private-owner',
      request: CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: true,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'private-owner',
      matchId: privateMatch.id,
    );
    await expectLater(
      hub.joinMatch(
        store: store,
        userIdentifier: 'public-id-guest',
        matchId: privateMatch.id,
      ),
      throwsA(_multiplayerError('match_not_found')),
    );
    await hub.joinPrivateMatch(
      store: store,
      userIdentifier: 'private-guest',
      inviteCode: privateMatch.inviteCode!,
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'private-guest',
      matchId: privateMatch.id,
    );
    final runningPrivate = await hub.startMatch(
      store: store,
      userIdentifier: 'private-owner',
      matchId: privateMatch.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );

    await expectLater(
      hub.joinPrivateMatch(
        store: store,
        userIdentifier: 'late-private-guest',
        inviteCode: runningPrivate.inviteCode!,
      ),
      throwsA(_multiplayerError('match_not_open')),
    );
  });

  test('private match creation retries an existing invite code', () async {
    const firstCode = 'ABCDEFGHJKLMN';
    const secondCode = 'PQRSTUVWXYZ23';
    final inviteCodeGenerator = _SequenceInviteCodeGenerator([
      firstCode,
      firstCode,
      secondCode,
    ]);
    final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);
    final store = _MemoryMatchStore();
    final request = CreateMatchRequest(
      name: 'Private lobby',
      mapName: 'verdantia',
      maxPlayers: 3,
      minPlayers: 2,
      private: true,
    );

    final first = await hub.createMatch(
      store: store,
      userIdentifier: 'first-owner',
      request: request,
    );
    final second = await hub.createMatch(
      store: store,
      userIdentifier: 'second-owner',
      request: request,
    );

    expect(first.inviteCode, firstCode);
    expect(second.inviteCode, secondCode);
    expect(inviteCodeGenerator.calls, 3);
  });

  test('private match creation retries a concurrent code conflict', () async {
    const firstCode = 'ABCDEFGHJKLMN';
    const secondCode = 'PQRSTUVWXYZ23';
    final inviteCodeGenerator = _SequenceInviteCodeGenerator([
      firstCode,
      secondCode,
    ]);
    final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);
    final store = _CreateConflictOnceMatchStore();

    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: true,
      ),
    );

    expect(match.inviteCode, secondCode);
    expect(inviteCodeGenerator.calls, 2);
  });

  test(
    'private match creation fails after bounded collision retries',
    () async {
      const inviteCode = 'ABCDEFGHJKLMN';
      final inviteCodeGenerator = _SequenceInviteCodeGenerator([inviteCode]);
      final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);
      final store = _MemoryMatchStore();
      final request = CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: true,
      );
      await hub.createMatch(
        store: store,
        userIdentifier: 'first-owner',
        request: request,
      );

      await expectLater(
        hub.createMatch(
          store: store,
          userIdentifier: 'second-owner',
          request: request,
        ),
        throwsA(_multiplayerError('invite_code_unavailable')),
      );
      expect(inviteCodeGenerator.calls, 17);
    },
  );
}
