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
    required Future<void> Function({bool cancelInput}) disconnect,
    required MatchConnectionAuthorizer authorize,
    required MatchConnectionStateUpdater updateConnectionState,
    required MatchClientMessageHandler handleClientMessage,
    required MatchServerMessageFactory createMessage,
  }) async {
    try {
      await _enqueueMatch(matchId, () async {
        final authorization = await authorize(
          store: store,
          matchId: matchId,
          userIdentifier: userIdentifier,
        );
        var state = authorization.state;
        final player = authorization.participant;
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
              unawaited(
                _enqueueMatch(
                  matchId,
                  () => handleClientMessage(
                    store: store,
                    matchId: matchId,
                    userIdentifier: userIdentifier,
                    message: message,
                    emitToCaller: emit,
                  ),
                ).catchError((Object error, StackTrace stackTrace) {
                  if (!controller.isClosed) {
                    controller.addError(error, stackTrace);
                  }
                }),
              );
            },
            onError: controller.addError,
            onDone: () async {
              await disconnect(cancelInput: false);
              await controller.close();
            },
          ),
        );
        _subscribe(matchId, emit);
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
