part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubLifecycleScenarios() {
  test(
    'leaveMatch keeps a running match resumable while another player is active',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final store = _MemoryMatchStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Abandoned match',
          mapName: 'verdantia',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: match.id,
      );
      final started = await hub.startMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: match.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );

      await hub.leaveMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
      );

      final state = await store.findState(started.id);
      expect(state!.match.state, 'running');
      expect(state.snapshot.state['phase'], isNot('abandoned'));
      expect(
        state.match.players
            .firstWhere((player) => player.userId == 'guest-user')
            .connectionState,
        WirePlayerConnectionState.offline,
      );
      expect(
        state.match.players
            .firstWhere((player) => player.userId == 'owner-user')
            .connectionState,
        WirePlayerConnectionState.connected,
      );

      final resumed = await hub.loadMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      expect(resumed.state, 'running');
      expect(resumed.id, started.id);
    },
  );

  test(
    'leaveMatch keeps a fully offline running match resumable until expiry',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final store = _MemoryMatchStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Abandoned match',
          mapName: 'verdantia',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: match.id,
      );
      final started = await hub.startMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: match.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      final running = (await store.findState(started.id))!;
      await store.saveState(
        running.copyWith(
          match: running.match.copyWith(
            players: [
              for (final player in running.match.players)
                player.userId == 'owner-user'
                    ? player.copyWith(
                        connectionState: WirePlayerConnectionState.offline,
                      )
                    : player,
            ],
          ),
        ),
      );

      await hub.leaveMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
      );

      final state = await store.findState(started.id);
      expect(state!.match.state, 'running');
      expect(state.snapshot.state['lastHumanActivityAt'], isNotNull);
      const offline = WirePlayerConnectionState.offline;
      expect(state.match.players[0].connectionState, offline);
      expect(state.match.players[1].connectionState, offline);
      expect(state.match.autoStartAt, isNull);
    },
  );

  test('emits no lifecycle update when transaction commit fails', () async {
    final hub = RealtimeMatchHub();
    final store = _CommitFailingMatchStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-lifecycle-commit-failure',
      request: CreateMatchRequest(
        name: 'Lifecycle commit failure',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final input = StreamController<MultiplayerClientMessage>();
    final initial = Completer<void>();
    final messages = <MultiplayerServerMessage>[];
    var recordMessages = false;
    final subscription = hub
        .connect(
          store: store,
          userIdentifier: match.ownerUserId,
          matchId: match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .listen((message) {
          if (message.snapshot != null && !initial.isCompleted) {
            initial.complete();
          } else if (recordMessages) {
            messages.add(message);
          }
        });
    await initial.future.timeout(const Duration(seconds: 1));

    recordMessages = true;
    store.failNextCommit();
    await expectLater(
      hub.resignMatch(
        store: store,
        userIdentifier: match.ownerUserId,
        matchId: match.id,
      ),
      throwsA(isA<StateError>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(messages.where((message) => message.match != null), isEmpty);
    expect((await store.findState(match.id))!.match.state, 'open');

    await subscription.cancel();
    await input.close();
  });
}
