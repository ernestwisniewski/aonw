import 'dart:async';

import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/client_message_guard.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:serverpod/serverpod.dart';

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

typedef MatchParticipantConnected =
    Future<StoredMatchState> Function({
      required MultiplayerMatchStore store,
      required String matchId,
      required String userIdentifier,
      required String connectionGeneration,
    });

typedef MatchParticipantDisconnected =
    Future<void> Function({
      required MultiplayerMatchStore store,
      required String matchId,
      required String userIdentifier,
      required String connectionGeneration,
    });

typedef MatchPresenceRenewer =
    Future<void> Function({
      required MultiplayerMatchStore store,
      required String matchId,
      required String userIdentifier,
      required String connectionGeneration,
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
    String Function()? connectionGenerationGenerator,
  }) : _viewProjector = viewProjector,
       _connectionGenerationGenerator =
           connectionGenerationGenerator ?? _newConnectionGeneration;

  final PlayerMatchViewProjector _viewProjector;
  final String Function() _connectionGenerationGenerator;
  PlayerMatchViewProjector get viewProjector => _viewProjector;

  final Map<String, List<MatchMessageTarget>> _subscribers = {};
  final Map<String, Future<void>> _matchQueues = {};
  final Map<String, Map<String, int>> _connectionCounts = {};
  final Map<String, Map<String, String>> _connectionGenerations = {};

  Stream<MultiplayerServerMessage> connect({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    required String matchId,
    required int afterOffset,
    required Stream<MultiplayerClientMessage> input,
    required MatchConnectionAuthorizer authorize,
    required MatchParticipantConnected participantConnected,
    required MatchParticipantDisconnected participantDisconnected,
    required MatchPresenceRenewer renewPresence,
    required MatchClientMessageHandler handleClientMessage,
    required MatchServerMessageFactory createMessage,
  }) {
    final connectionGeneration = _connectionGenerationGenerator();
    StreamSubscription<MultiplayerClientMessage>? inputSubscription;
    final controller = StreamController<MultiplayerServerMessage>();
    MatchMessageTarget? caller;
    var connectionRegistered = false;
    var disconnectRequested = false;

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
      if (disconnectRequested) return;
      disconnectRequested = true;
      final currentCaller = caller;
      if (currentCaller != null) _unsubscribe(matchId, currentCaller);
      if (cancelInput) await inputSubscription?.cancel();
      if (!connectionRegistered) return;
      final remaining = _releaseConnection(matchId, userIdentifier);
      store.operationalEvents.streamDisconnected(matchId: matchId);
      if (remaining > 0) return;
      await _enqueueMatch(matchId, () async {
        if (_connectionCount(matchId, userIdentifier) > 0) return;
        final currentGeneration =
            _connectionGeneration(matchId, userIdentifier) ??
            connectionGeneration;
        try {
          await participantDisconnected(
            store: store,
            matchId: matchId,
            userIdentifier: userIdentifier,
            connectionGeneration: currentGeneration,
          );
        } catch (_) {
          // The match may already be gone or terminal; disconnect cleanup
          // should not surface as a stream error after the client has left.
        } finally {
          _clearConnectionGeneration(
            matchId,
            userIdentifier,
            currentGeneration,
          );
        }
      });
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
          activateConnectionGeneration: () => _activateConnectionGeneration(
            matchId,
            userIdentifier,
            connectionGeneration,
          ),
          disconnectRequested: () => disconnectRequested,
          currentConnectionGeneration: () =>
              _connectionGeneration(matchId, userIdentifier) ??
              connectionGeneration,
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
          participantConnected: participantConnected,
          renewPresence: renewPresence,
          connectionGeneration: connectionGeneration,
          handleClientMessage: handleClientMessage,
          createMessage: createMessage,
        ),
      );
    };

    return (controller..onCancel = () => disconnect()).stream;
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
        unawaited(_matchQueues.remove(matchId));
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

  void _activateConnectionGeneration(
    String matchId,
    String userIdentifier,
    String connectionGeneration,
  ) {
    _connectionGenerations.putIfAbsent(
      matchId,
      () => <String, String>{},
    )[userIdentifier] = connectionGeneration;
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

  int _connectionCount(String matchId, String userIdentifier) =>
      _connectionCounts[matchId]?[userIdentifier] ?? 0;

  String? _connectionGeneration(String matchId, String userIdentifier) =>
      _connectionGenerations[matchId]?[userIdentifier];

  void _clearConnectionGeneration(
    String matchId,
    String userIdentifier,
    String expectedGeneration,
  ) {
    if (_connectionCount(matchId, userIdentifier) > 0) return;
    final matchGenerations = _connectionGenerations[matchId];
    if (matchGenerations?[userIdentifier] != expectedGeneration) return;
    matchGenerations!.remove(userIdentifier);
    if (matchGenerations.isEmpty) _connectionGenerations.remove(matchId);
  }
}

String _newConnectionGeneration() => const Uuid().v4();
