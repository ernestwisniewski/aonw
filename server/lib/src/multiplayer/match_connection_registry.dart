import 'dart:async';

import 'package:aonw_core/protocol.dart';

import '../generated/protocol.dart';
import '../observability/server_operational_event_sink.dart';
import 'client_message_guard.dart';
import 'multiplayer_errors.dart';
import 'multiplayer_match_store.dart';
import 'player_match_view_projector.dart';

part 'match_connection_registry_connect.dart';
part 'match_connection_registry_projection.dart';

typedef MatchServerMessageSink =
    void Function(MultiplayerServerMessage message);

final class MatchMessageTarget {
  const MatchMessageTarget._({
    required this.recipient,
    required MatchServerMessageSink sink,
    required void Function(Object error, StackTrace stackTrace) errorSink,
    required ServerOperationalEventSink operationalEvents,
  }) : _sink = sink,
       _errorSink = errorSink,
       _operationalEvents = operationalEvents;

  final MatchRecipient recipient;
  final MatchServerMessageSink _sink;
  final void Function(Object error, StackTrace stackTrace) _errorSink;
  final ServerOperationalEventSink _operationalEvents;
}

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
      required MatchMessageTarget caller,
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
  MatchConnectionRegistry({
    PlayerMatchViewProjector viewProjector = const PlayerMatchViewProjector(),
  }) : _viewProjector = viewProjector;

  final PlayerMatchViewProjector _viewProjector;
  PlayerMatchViewProjector get viewProjector => _viewProjector;

  final Map<String, List<MatchMessageTarget>> _subscribers = {};
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
    MatchMessageTarget? caller;
    var connectionRegistered = false;
    var disconnected = false;

    void emit(MultiplayerServerMessage message) {
      final currentCaller = caller;
      if (currentCaller == null) {
        controller.addError(
          StateError('Match message emitted before recipient authorization.'),
        );
        return;
      }
      sendTo(currentCaller, message);
    }

    Future<void> disconnect({bool cancelInput = true}) async {
      if (disconnected) return;
      disconnected = true;
      final currentCaller = caller;
      if (currentCaller != null) _unsubscribe(matchId, currentCaller);
      if (cancelInput) await inputSubscription?.cancel();
      if (!connectionRegistered) return;
      final remaining = _releaseConnection(matchId, userIdentifier);
      store.operationalEvents.streamDisconnected(matchId: matchId);
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
          setRecipient: (recipient) {
            caller = MatchMessageTarget._(
              recipient: recipient,
              sink: (message) {
                if (!controller.isClosed) controller.add(message);
              },
              errorSink: (error, stackTrace) {
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
              },
              operationalEvents: store.operationalEvents,
            );
          },
          requireCaller: () =>
              caller ??
              (throw StateError('Match recipient was not authorized.')),
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

  Future<void> _enqueueMatch(
    String matchId,
    Future<void> Function() action,
  ) async {
    final previous = _matchQueues[matchId] ?? Future<void>.value();
    final barrier = previous.then<void>((_) {}, onError: (_, _) {});
    final next = barrier.then((_) => action());
    late final Future<void> tracked;
    void clearQueue() {
      if (identical(_matchQueues[matchId], tracked)) {
        _matchQueues.remove(matchId);
      }
    }

    tracked = next.then<void>(
      (_) => clearQueue(),
      onError: (_, _) => clearQueue(),
    );
    _matchQueues[matchId] = tracked;
    await next;
  }

  void _subscribe(String matchId, MatchMessageTarget target) {
    _subscribers.putIfAbsent(matchId, () => []).add(target);
  }

  void _unsubscribe(String matchId, MatchMessageTarget target) {
    final subscribers = _subscribers[matchId];
    if (subscribers == null) return;
    subscribers.remove(target);
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
