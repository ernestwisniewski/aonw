part of 'multiplayer_endpoint.dart';

extension RealtimeMatchHubApi on RealtimeMatchHub {
  Future<List<ProjectedWireMatch>> listMatches({
    required MultiplayerMatchStore store,
    required String userIdentifier,
  }) => _queries.listMatches(store: store, userIdentifier: userIdentifier);

  Future<ProjectedWireMatch> quickplay({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final match = await _matchmaking.quickplay(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      request: request,
      snapshotFactory: snapshotFactory,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<ProjectedWireMatch> createMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
  }) async {
    final match = await _matchmaking.createMatch(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      request: request,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<ProjectedWireMatch> joinMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String matchId,
    String? countryId,
  }) async {
    final validatedMatchId = _inputValidator.matchId(matchId);
    final match = await _matchmaking.joinMatch(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      matchId: validatedMatchId,
      countryId: countryId,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<ProjectedWireMatch> joinPrivateMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required String inviteCode,
    String? countryId,
  }) async {
    final validatedInviteCode = _inputValidator.inviteCode(inviteCode);
    final match = await _matchmaking.joinPrivateMatch(
      store: store,
      userIdentifier: userIdentifier,
      displayName: displayName,
      inviteCode: validatedInviteCode,
      countryId: countryId,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<ProjectedWireMatch> loadMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final validatedMatchId = _inputValidator.matchId(matchId);
    final match = await _lifecycle.loadMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: validatedMatchId,
      snapshotFactory: snapshotFactory,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<ProjectedWireSnapshot> loadSnapshot({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return _queries.loadSnapshot(
      store: store,
      userIdentifier: userIdentifier,
      matchId: _inputValidator.matchId(matchId),
    );
  }

  Future<List<ProjectedWireEvent>> listEvents({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
  }) {
    return _queries.listEvents(
      store: store,
      userIdentifier: userIdentifier,
      matchId: _inputValidator.matchId(matchId),
      afterOffset: _inputValidator.afterOffset(afterOffset),
    );
  }

  Future<ProjectedWireMatch> startMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    InitialMultiplayerSnapshotFactory snapshotFactory =
        const InitialMultiplayerSnapshotFactory(),
  }) async {
    final validatedMatchId = _inputValidator.matchId(matchId);
    final match = await _lifecycle.startMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: validatedMatchId,
      snapshotFactory: snapshotFactory,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<ProjectedWireMatch> resignMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) async {
    final validatedMatchId = _inputValidator.matchId(matchId);
    final match = await _lifecycle.resignMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: validatedMatchId,
    );
    return _viewProjector.matchFor(match, userIdentifier: userIdentifier);
  }

  Future<void> leaveMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
  }) {
    return _lifecycle.leaveMatch(
      store: store,
      userIdentifier: userIdentifier,
      matchId: _inputValidator.matchId(matchId),
    );
  }

  Future<List<MatchTimeoutSweepFailure>> advanceTimedOutTurns({
    required MultiplayerMatchStore store,
  }) => _commands.advanceTimedOutTurns(store: store);

  Future<List<LobbyPresenceSweepFailure>> expireLobbyPresence({
    required MultiplayerMatchStore store,
  }) => _lifecycle.expireLobbyPresence(store: store);

  Stream<MultiplayerServerMessage> connect({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
    required Stream<MultiplayerClientMessage> input,
  }) {
    return _connectionRegistry.connect(
      store: store,
      userIdentifier: userIdentifier,
      matchId: _inputValidator.matchId(matchId),
      afterOffset: _inputValidator.afterOffset(afterOffset),
      input: input,
      authorize: _commands.authorizeConnection,
      participantConnected:
          ({
            required store,
            required matchId,
            required userIdentifier,
            required connectionGeneration,
          }) => _lifecycle.participantConnected(
            store: store,
            matchId: matchId,
            userIdentifier: userIdentifier,
            connectionGeneration: connectionGeneration,
          ),
      participantDisconnected:
          ({
            required store,
            required matchId,
            required userIdentifier,
            required connectionGeneration,
          }) => _lifecycle.participantDisconnected(
            store: store,
            matchId: matchId,
            userIdentifier: userIdentifier,
            connectionGeneration: connectionGeneration,
          ),
      renewPresence:
          ({
            required store,
            required matchId,
            required userIdentifier,
            required connectionGeneration,
          }) => _lifecycle.renewParticipantPresence(
            store: store,
            matchId: matchId,
            userIdentifier: userIdentifier,
            connectionGeneration: connectionGeneration,
          ),
      handleClientMessage: _commands.handleClientMessage,
      createMessage: _broadcaster.message,
    );
  }
}
