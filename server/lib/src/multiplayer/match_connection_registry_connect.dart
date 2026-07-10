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
    required void Function(MatchRecipient recipient) setRecipient,
    required MatchMessageTarget Function() requireCaller,
    required Future<void> Function({bool cancelInput}) disconnect,
    required MatchConnectionAuthorizer authorize,
    required MatchConnectionStateUpdater updateConnectionState,
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
        var state = authorization.state;
        final player = authorization.participant;
        final participantIsAuthorized =
            player.userId == userIdentifier &&
            state.match.players.any(
              (candidate) =>
                  candidate.id == player.id &&
                  candidate.userId == userIdentifier,
            );
        if (!participantIsAuthorized) {
          throw multiplayerException(
            'authorization_mismatch',
            'Authenticated player does not match the authorized participant.',
          );
        }
        setRecipient(
          MatchRecipient(userIdentifier: userIdentifier, playerId: player.id),
        );
        registerConnection();
        if (player.connectionState != WirePlayerConnectionState.connected) {
          state = await updateConnectionState(
            store: store,
            matchId: matchId,
            userIdentifier: userIdentifier,
            connectionState: WirePlayerConnectionState.connected,
          );
        }
        final backlogAfterOffset = afterOffset > state.offset
            ? afterOffset
            : state.offset;
        final backlog = await store.listEvents(matchId, backlogAfterOffset);
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
                      () => handleClientMessage(
                        store: store,
                        matchId: matchId,
                        userIdentifier: userIdentifier,
                        message: message,
                        caller: requireCaller(),
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
        _subscribe(matchId, requireCaller());
        emit(
          createMessage(
            matchId: matchId,
            offset: state.offset,
            match: state.match,
            snapshot: state.snapshot,
          ),
        );
        for (final event in backlog) {
          emit(
            createMessage(matchId: matchId, offset: event.offset, event: event),
          );
        }
      });
    } catch (error, stackTrace) {
      await disconnect();
      controller.addError(error, stackTrace);
      await controller.close();
    }
  }
}
