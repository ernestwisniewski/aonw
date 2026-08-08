part of 'match_connection_registry.dart';

extension MatchConnectionRegistryConnect on MatchConnectionRegistry {
  Future<void> _connect({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
    required Stream<MultiplayerClientMessage> input,
    required MatchServerMessageSink emit,
    required StreamController<MultiplayerServerMessage> controller,
    required void Function(StreamSubscription<MultiplayerClientMessage>)
    setInputSubscription,
    required void Function() registerConnection,
    required void Function() activateConnectionGeneration,
    required bool Function() disconnectRequested,
    required String Function() currentConnectionGeneration,
    required void Function(MatchRecipient recipient) setRecipient,
    required MatchMessageTarget Function() requireCaller,
    required Future<void> Function({bool cancelInput}) disconnect,
    required MatchConnectionAuthorizer authorize,
    required MatchParticipantConnected participantConnected,
    required MatchPresenceRenewer renewPresence,
    required String connectionGeneration,
    required MatchClientMessageHandler handleClientMessage,
    required MatchServerMessageFactory createMessage,
  }) async {
    final messageGuard = ClientMessageGuard(expectedMatchId: matchId);
    var inputRejected = false;

    void rejectInput(Object error, StackTrace stackTrace) {
      if (inputRejected || controller.isClosed) return;
      inputRejected = true;
      controller.addError(error, stackTrace);
      unawaited(
        disconnect().whenComplete(() async {
          if (!controller.isClosed) await controller.close();
        }),
      );
    }

    try {
      await _enqueueMatch(matchId, () async {
        final authorization = await authorize(
          store: store,
          matchId: matchId,
          userIdentifier: userIdentifier,
        );
        if (disconnectRequested()) return;
        var state = authorization.state;
        final player = authorization.participant;
        _requireAuthorizedParticipant(
          state: state,
          player: player,
          userIdentifier: userIdentifier,
        );
        if (disconnectRequested()) return;
        final reconnect =
            afterOffset > 0 ||
            player.connectionState == WirePlayerConnectionState.offline ||
            player.connectionState == WirePlayerConnectionState.reconnecting;
        setRecipient(
          MatchRecipient(userIdentifier: userIdentifier, playerId: player.id),
        );
        registerConnection();
        state = await participantConnected(
          store: store,
          matchId: matchId,
          userIdentifier: userIdentifier,
          connectionGeneration: connectionGeneration,
        );
        activateConnectionGeneration();
        if (disconnectRequested()) return;
        final backlogAfterOffset = afterOffset > state.offset
            ? afterOffset
            : state.offset;
        final backlog = await store.listEvents(matchId, backlogAfterOffset);
        if (disconnectRequested()) return;
        setInputSubscription(
          input.listen(
            (message) {
              if (inputRejected) return;
              try {
                messageGuard.admit(message);
              } catch (error, stackTrace) {
                rejectInput(error, stackTrace);
                return;
              }
              unawaited(
                _enqueueMatch(
                      matchId,
                      () => _handleAdmittedInput(
                        store: store,
                        matchId: matchId,
                        userIdentifier: userIdentifier,
                        message: message,
                        disconnectRequested: disconnectRequested,
                        currentConnectionGeneration:
                            currentConnectionGeneration,
                        renewPresence: renewPresence,
                        rejectPresence: rejectInput,
                        handleClientMessage: handleClientMessage,
                        requireCaller: requireCaller,
                      ),
                    )
                    .catchError((Object error, StackTrace stackTrace) {
                      if (!controller.isClosed) {
                        controller.addError(error, stackTrace);
                      }
                    })
                    .whenComplete(messageGuard.release),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              rejectInput(error, stackTrace);
            },
            onDone: () async {
              await disconnect(cancelInput: false);
              await controller.close();
            },
          ),
        );
        if (disconnectRequested()) return;
        _subscribe(matchId, requireCaller());
        store.operationalEvents.streamConnected(
          matchId: state.match.id,
          reconnect: reconnect,
        );
        _emitInitialConnectionState(
          state: state,
          backlog: backlog,
          emit: emit,
          createMessage: createMessage,
        );
      });
    } catch (error, stackTrace) {
      await disconnect();
      controller.addError(error, stackTrace);
      await controller.close();
    }
  }

  Future<void> _handleAdmittedInput({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required MultiplayerClientMessage message,
    required bool Function() disconnectRequested,
    required String Function() currentConnectionGeneration,
    required MatchPresenceRenewer renewPresence,
    required void Function(Object error, StackTrace stackTrace) rejectPresence,
    required MatchClientMessageHandler handleClientMessage,
    required MatchMessageTarget Function() requireCaller,
  }) async {
    if (disconnectRequested()) return;
    final renewed = await _renewPresenceOrReject(
      store: store,
      matchId: matchId,
      userIdentifier: userIdentifier,
      connectionGeneration: currentConnectionGeneration(),
      renewPresence: renewPresence,
      rejectPresence: rejectPresence,
    );
    if (!renewed || disconnectRequested()) return;
    await handleClientMessage(
      store: store,
      matchId: matchId,
      userIdentifier: userIdentifier,
      message: message,
      caller: requireCaller(),
    );
  }

  Future<bool> _renewPresenceOrReject({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
    required MatchPresenceRenewer renewPresence,
    required void Function(Object error, StackTrace stackTrace) rejectPresence,
  }) async {
    try {
      await renewPresence(
        store: store,
        matchId: matchId,
        userIdentifier: userIdentifier,
        connectionGeneration: connectionGeneration,
      );
      return true;
    } catch (error, stackTrace) {
      rejectPresence(error, stackTrace);
      return false;
    }
  }

  void _requireAuthorizedParticipant({
    required StoredMatchState state,
    required WirePlayer player,
    required String userIdentifier,
  }) {
    final authorized =
        player.userId == userIdentifier &&
        state.match.players.any(
          (candidate) =>
              candidate.id == player.id && candidate.userId == userIdentifier,
        );
    if (authorized) return;
    throw multiplayerException(
      'authorization_mismatch',
      'Authenticated player does not match the authorized participant.',
    );
  }

  void _emitInitialConnectionState({
    required StoredMatchState state,
    required List<WireEvent> backlog,
    required MatchServerMessageSink emit,
    required MatchServerMessageFactory createMessage,
  }) {
    emit(
      createMessage(
        matchId: state.match.id,
        offset: state.offset,
        match: state.match,
        snapshot: state.snapshot,
      ),
    );
    for (final event in backlog) {
      emit(
        createMessage(
          matchId: state.match.id,
          offset: event.offset,
          event: event,
        ),
      );
    }
  }
}
