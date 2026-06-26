import 'dart:async';

import 'package:aonw_core/protocol.dart';

import '../generated/protocol.dart';
import 'multiplayer_match_store.dart';

typedef MatchServerMessageSink =
    void Function(MultiplayerServerMessage message);

typedef MatchServerMessageFactory =
    MultiplayerServerMessage Function({
      required String matchId,
      required int offset,
      WireMatch? match,
      WireSnapshot? snapshot,
      WireEvent? event,
      WireCommandAck? ack,
    });

typedef MatchConnectionAuthorizer =
    Future<MatchConnectionAuthorization> Function({
      required MultiplayerMatchStore store,
      required String matchId,
      required String userIdentifier,
    });

typedef MatchConnectionStateUpdater =
    Future<StoredMatchState> Function({
      required MultiplayerMatchStore store,
      required String matchId,
      required String userIdentifier,
      required WirePlayerConnectionState connectionState,
    });

typedef MatchClientMessageHandler =
    Future<void> Function({
      required MultiplayerMatchStore store,
      required String matchId,
      required String userIdentifier,
      required MultiplayerClientMessage message,
      required MatchServerMessageSink emitToCaller,
    });

final class MatchConnectionAuthorization {
  const MatchConnectionAuthorization({
    required this.state,
    required this.participant,
  });

  final StoredMatchState state;
  final WirePlayer participant;
}

final class MatchConnectionRegistry {
  final Map<String, List<MatchServerMessageSink>> _subscribers = {};
  final Map<String, Future<void>> _matchQueues = {};
  final Map<String, Map<String, int>> _connectionCounts = {};

  Stream<MultiplayerServerMessage> connect({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
    required Stream<MultiplayerClientMessage> input,
    required MatchConnectionAuthorizer authorize,
    required MatchConnectionStateUpdater updateConnectionState,
    required MatchClientMessageHandler handleClientMessage,
    required MatchServerMessageFactory createMessage,
  }) {
    StreamSubscription<MultiplayerClientMessage>? inputSubscription;
    final controller = StreamController<MultiplayerServerMessage>();
    var connectionRegistered = false;
    var disconnected = false;

    void emit(MultiplayerServerMessage message) {
      if (!controller.isClosed) controller.add(message);
    }

    Future<void> disconnect({bool cancelInput = true}) async {
      if (disconnected) return;
      disconnected = true;
      _unsubscribe(matchId, emit);
      if (cancelInput) await inputSubscription?.cancel();
      if (!connectionRegistered) return;
      final remaining = _releaseConnection(matchId, userIdentifier);
      if (remaining > 0) return;
      try {
        await updateConnectionState(
          store: store,
          matchId: matchId,
          userIdentifier: userIdentifier,
          connectionState: WirePlayerConnectionState.offline,
        );
      } catch (_) {
        // The match may already be gone or terminal; disconnect cleanup should
        // not surface as a stream error after the client has left.
      }
    }

    controller.onListen = () {
      unawaited(
        _connect(
          store: store,
          userIdentifier: userIdentifier,
          matchId: matchId,
          afterOffset: afterOffset,
          input: input,
          emit: emit,
          controller: controller,
          setInputSubscription: (subscription) {
            inputSubscription = subscription;
          },
          registerConnection: () {
            _retainConnection(matchId, userIdentifier);
            connectionRegistered = true;
          },
          disconnect: disconnect,
          authorize: authorize,
          updateConnectionState: updateConnectionState,
          handleClientMessage: handleClientMessage,
          createMessage: createMessage,
        ),
      );
    };

    controller.onCancel = () => disconnect();

    return controller.stream;
  }

  void broadcast(
    MultiplayerServerMessage update, {
    MatchServerMessageSink? except,
  }) {
    for (final subscriber in List.of(
      _subscribers[update.matchId] ?? const <MatchServerMessageSink>[],
    )) {
      if (identical(subscriber, except)) continue;
      subscriber(update);
    }
  }

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
    } catch (error, stackTrace) {
      await disconnect();
      controller.addError(error, stackTrace);
      await controller.close();
    }
  }

  Future<void> _enqueueMatch(
    String matchId,
    Future<void> Function() action,
  ) async {
    final previous = _matchQueues[matchId] ?? Future<void>.value();
    final barrier = previous.then<void>((_) {}, onError: (_, _) {});
    final next = barrier.then((_) => action());
    _matchQueues[matchId] = next.whenComplete(() {
      if (identical(_matchQueues[matchId], next)) {
        _matchQueues.remove(matchId);
      }
    });
    await next;
  }

  void _subscribe(String matchId, MatchServerMessageSink emit) {
    _subscribers.putIfAbsent(matchId, () => []).add(emit);
  }

  void _unsubscribe(String matchId, MatchServerMessageSink emit) {
    final subscribers = _subscribers[matchId];
    if (subscribers == null) return;
    subscribers.remove(emit);
    if (subscribers.isEmpty) {
      _subscribers.remove(matchId);
    }
  }

  void _retainConnection(String matchId, String userIdentifier) {
    final matchConnections = _connectionCounts.putIfAbsent(
      matchId,
      () => <String, int>{},
    );
    matchConnections[userIdentifier] =
        (matchConnections[userIdentifier] ?? 0) + 1;
  }

  int _releaseConnection(String matchId, String userIdentifier) {
    final matchConnections = _connectionCounts[matchId];
    if (matchConnections == null) return 0;
    final current = matchConnections[userIdentifier] ?? 0;
    if (current <= 1) {
      matchConnections.remove(userIdentifier);
    } else {
      matchConnections[userIdentifier] = current - 1;
    }
    if (matchConnections.isEmpty) {
      _connectionCounts.remove(matchId);
    }
    return matchConnections[userIdentifier] ?? 0;
  }
}
