part of 'serverpod_multiplayer_smoke.dart';

extension _CurrentMultiplayerEndpoint on sp.EndpointMultiplayer {
  Future<List<WireMatch>> listCurrentMatches() =>
      listMatches(multiplayerVersion: kCurrentMultiplayerVersion);

  Future<WireMatch> createCurrentMatch(sp.CreateMatchRequest request) =>
      createMatch(request, multiplayerVersion: kCurrentMultiplayerVersion);

  Future<WireMatch> quickplayCurrent(sp.CreateMatchRequest request) =>
      quickplay(request, multiplayerVersion: kCurrentMultiplayerVersion);

  Future<WireMatch> joinCurrentMatch(String matchId) =>
      joinMatch(matchId, multiplayerVersion: kCurrentMultiplayerVersion);

  Future<WireMatch> loadCurrentMatch(String matchId) =>
      loadMatch(matchId, multiplayerVersion: kCurrentMultiplayerVersion);

  Future<WireMatch> startCurrentMatch(String matchId) =>
      startMatch(matchId, multiplayerVersion: kCurrentMultiplayerVersion);

  Future<void> leaveCurrentMatch(String matchId) =>
      leaveMatch(matchId, multiplayerVersion: kCurrentMultiplayerVersion);

  Future<List<WireEvent>> listCurrentEvents(String matchId, int afterOffset) =>
      listEvents(
        matchId,
        afterOffset,
        multiplayerVersion: kCurrentMultiplayerVersion,
      );

  Stream<sp.MultiplayerServerMessage> connectCurrent(
    String matchId,
    int afterOffset,
    Stream<sp.MultiplayerClientMessage> input,
  ) => connect(
    matchId,
    afterOffset,
    input,
    multiplayerVersion: kCurrentMultiplayerVersion,
  );
}

extension _RuntimeSmokeQuickplayPresence on _RuntimeSmoke {
  Future<({WireMatch waiting, _OpenStream ownerPresence})>
  _createQuickplayOwner(sp.Client ownerClient, String ownerUserId) async {
    final waiting = await _quickplay(ownerClient, PlayerCountry.russia);
    final owner = waiting.players.firstWhere(
      (player) => player.userId == ownerUserId,
      orElse: () => throw StateError(
        'Quickplay match has no player for owner $ownerUserId.',
      ),
    );
    _RuntimeSmoke._expect(
      waiting.quickplay &&
          waiting.mapName == MapPlayerCapacityRules.quickplayLobbyMapName &&
          waiting.maxPlayers == 4 &&
          waiting.minPlayers == 2 &&
          waiting.state == 'open' &&
          waiting.autoStartAt == null,
      'Expected server-owned open quickplay lobby with 4/2 seats.',
    );
    _RuntimeSmoke._expect(
      owner.country == PlayerCountry.russia,
      'Expected quickplay owner country Russia, got ${owner.country.name}.',
    );
    final ownerPresence = await _openPresence(ownerClient, waiting.id);
    final requeued = await _quickplay(ownerClient, PlayerCountry.china);
    _RuntimeSmoke._expect(
      requeued.id == waiting.id &&
          requeued.players.single.country == PlayerCountry.china,
      'Expected owner quickplay requeue to update country to China.',
    );
    return (waiting: waiting, ownerPresence: ownerPresence);
  }

  Future<({WireMatch countdown, _OpenStream guestPresence})>
  _connectSecondQuickplayPlayer({
    required sp.Client guestClient,
    required sp.Client conflictClient,
    required String matchId,
  }) async {
    final joining = await _quickplay(
      guestClient,
      PlayerCountry.france,
      mapName: config.mapName == 'myranth' ? 'terenos' : 'myranth',
    );
    _RuntimeSmoke._expect(
      joining.autoStartAt == null,
      'A connecting quickplay guest must not start the countdown.',
    );
    final guestPresence = await _openPresence(guestClient, matchId);
    final countdown = await guestClient.multiplayer
        .loadCurrentMatch(matchId)
        .timeout(config.requestTimeout);
    _RuntimeSmoke._expect(
      countdown.id == matchId &&
          countdown.state == 'open' &&
          countdown.autoStartAt != null &&
          countdown.players.length == 2,
      'Expected second quickplay player to start countdown.',
    );
    await _expectQuickplayCountryUnavailable(
      conflictClient,
      PlayerCountry.france,
    );
    return (countdown: countdown, guestPresence: guestPresence);
  }

  Future<
    ({WireMatch started, _OpenStream thirdPresence, _OpenStream fourthPresence})
  >
  _completeQuickplayLobby({
    required sp.Client thirdClient,
    required sp.Client fourthClient,
    required String matchId,
    required DateTime previousCountdown,
  }) async {
    final thirdJoining = await _quickplay(thirdClient, PlayerCountry.germany);
    _RuntimeSmoke._expect(
      thirdJoining.id == matchId &&
          thirdJoining.state == 'open' &&
          thirdJoining.players.length == 3 &&
          thirdJoining.autoStartAt == null,
      'Expected a connecting third quickplay player to reset the countdown.',
    );
    final thirdPresence = await _openPresence(thirdClient, matchId);
    final threePlayers = await thirdClient.multiplayer
        .loadCurrentMatch(matchId)
        .timeout(config.requestTimeout);
    _RuntimeSmoke._expect(
      threePlayers.autoStartAt != null &&
          threePlayers.autoStartAt!.isAfter(previousCountdown),
      'Expected connected third quickplay player to restart the countdown.',
    );
    final fourthJoining = await _quickplay(fourthClient, PlayerCountry.japan);
    _RuntimeSmoke._expect(
      fourthJoining.state == 'open',
      'A connecting fourth quickplay player must not start the match.',
    );
    final fourthPresence = await _openPresence(fourthClient, matchId);
    final started = await fourthClient.multiplayer
        .loadCurrentMatch(matchId)
        .timeout(config.requestTimeout);
    _RuntimeSmoke._expect(
      started.id == matchId &&
          started.state == 'running' &&
          started.players.length == 4 &&
          started.autoStartAt == null,
      'Expected fourth quickplay player to start the match immediately.',
    );
    return (
      started: started,
      thirdPresence: thirdPresence,
      fourthPresence: fourthPresence,
    );
  }

  Future<
    ({WireMatch started, _OpenStream ownerPresence, _OpenStream guestPresence})
  >
  _createAndStartHostedMatch({
    required sp.Client ownerClient,
    required sp.Client guestClient,
    required int seed,
  }) async {
    final created = await ownerClient.multiplayer
        .createCurrentMatch(
          sp.CreateMatchRequest(
            name: 'Runtime smoke $seed',
            mapName: config.mapName,
            maxPlayers: 2,
            minPlayers: 2,
            private: false,
          ),
        )
        .timeout(config.requestTimeout);
    final ownerPresence = await _openPresence(ownerClient, created.id);
    final publicMatches = await guestClient.multiplayer
        .listCurrentMatches()
        .timeout(config.requestTimeout);
    _RuntimeSmoke._expect(
      publicMatches.any((match) => match.id == created.id),
      'Expected newly created public match ${created.id} in lobby discovery.',
    );
    await guestClient.multiplayer
        .joinCurrentMatch(created.id)
        .timeout(config.requestTimeout);
    final guestPresence = await _openPresence(guestClient, created.id);
    final started = await ownerClient.multiplayer
        .startCurrentMatch(created.id)
        .timeout(config.requestTimeout);
    return (
      started: started,
      ownerPresence: ownerPresence,
      guestPresence: guestPresence,
    );
  }

  Future<_OpenStream> _openPresence(sp.Client client, String matchId) {
    final input = StreamController<sp.MultiplayerClientMessage>();
    return _openUntilInitialSnapshot(
      client.multiplayer.connectCurrent(matchId, 0, input.stream),
      input,
    );
  }
}
