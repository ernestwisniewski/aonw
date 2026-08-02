import 'dart:async';
import 'dart:collection';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session_refresh_coordinator.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/session/serverpod_multiplayer_failure_mapper.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/foundation.dart';

export 'package:aonw/api/transport/live_server_event.dart';

part 'live_event_subscription_echo_guard.dart';

const _defaultReconnectDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

typedef MultiplayerStreamConnector =
    Stream<sp.MultiplayerServerMessage> Function({
      required String matchId,
      required AuthToken token,
      required int afterOffset,
      required Stream<sp.MultiplayerClientMessage> input,
    });
typedef MultiplayerAuthTokenReader = Future<AuthToken> Function();
typedef ServerpodMultiplayerStreamConnection = ({
  Stream<sp.MultiplayerServerMessage> messages,
  void Function() close,
});
typedef ServerpodMultiplayerStreamConnectionFactory =
    ServerpodMultiplayerStreamConnection Function({
      required String matchId,
      required AuthToken token,
      required int afterOffset,
      required Stream<sp.MultiplayerClientMessage> input,
    });

class ServerpodMultiplayerStreamConnector {
  final String serverpodHost;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;
  final ServerpodMultiplayerStreamConnectionFactory? connectionFactory;

  const ServerpodMultiplayerStreamConnector(
    this.serverpodHost, {
    this.authKeyProviderFactory,
    this.connectionFactory,
  });

  Stream<sp.MultiplayerServerMessage> connect({
    required String matchId,
    required AuthToken token,
    required int afterOffset,
    required Stream<sp.MultiplayerClientMessage> input,
  }) {
    // Create the client lazily on listen. A subscription can be closed while
    // awaiting a refreshed token, in which case _connectOnce deliberately
    // never listens to this stream and no client should be allocated.
    return _ownedConnectionStream(() {
      final injectedFactory = connectionFactory;
      return injectedFactory == null
          ? _serverpodConnection(
              matchId: matchId,
              token: token,
              afterOffset: afterOffset,
              input: input,
            )
          : injectedFactory(
              matchId: matchId,
              token: token,
              afterOffset: afterOffset,
              input: input,
            );
    });
  }

  ServerpodMultiplayerStreamConnection _serverpodConnection({
    required String matchId,
    required AuthToken token,
    required int afterOffset,
    required Stream<sp.MultiplayerClientMessage> input,
  }) {
    final authKeyProvider = authKeyProviderFactory?.call();
    final client = createServerpodClient(
      serverpodHost,
      token: authKeyProvider == null ? token : null,
      authKeyProvider: authKeyProvider,
    );
    try {
      return (
        messages: client.multiplayer.connect(matchId, afterOffset, input),
        close: client.close,
      );
    } catch (_) {
      client.close();
      rethrow;
    }
  }
}

Stream<sp.MultiplayerServerMessage> _ownedConnectionStream(
  ServerpodMultiplayerStreamConnection Function() createConnection,
) {
  StreamSubscription<sp.MultiplayerServerMessage>? upstream;
  ServerpodMultiplayerStreamConnection? connection;
  var connectionClosed = false;
  late final StreamController<sp.MultiplayerServerMessage> controller;

  void closeConnection() {
    if (connectionClosed) return;
    connectionClosed = true;
    connection?.close();
  }

  Future<void> cancelUpstream() async {
    final active = upstream;
    upstream = null;
    try {
      await active?.cancel();
    } finally {
      closeConnection();
    }
  }

  controller = StreamController<sp.MultiplayerServerMessage>(
    onListen: () {
      try {
        final created = createConnection();
        connection = created;
        upstream = created.messages.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            upstream = null;
            closeConnection();
            unawaited(controller.close());
          },
        );
      } catch (error, stackTrace) {
        closeConnection();
        controller.addError(error, stackTrace);
        unawaited(controller.close());
      }
    },
    onPause: () => upstream?.pause(),
    onResume: () => upstream?.resume(),
    onCancel: cancelUpstream,
  );
  return controller.stream;
}

class LiveEventSubscription implements LiveMultiplayerEvents {
  final EventCodec eventCodec;
  final SnapshotCodec snapshotCodec;
  final MultiplayerStreamConnector _connect;

  LiveEventSubscription({
    required String serverpodHost,
    MultiplayerStreamConnector? connector,
    this.eventCodec = const EventCodec(),
    this.snapshotCodec = const SnapshotCodec(),
  }) : _connect =
           connector ??
           ServerpodMultiplayerStreamConnector(serverpodHost).connect;

  @override
  Future<LiveEventSubscriptionHandle> subscribe({
    required String matchId,
    required AuthToken token,
    MultiplayerAuthTokenReader? tokenReader,
    required int fromOffset,
    int Function()? nextOffset,
    required void Function(LiveServerEvent event) onEvent,
    required void Function(CanonicalGameSnapshot snapshot) onSnapshotResync,
    void Function(WireMatch match)? onMatch,
    void Function()? onConnected,
    void Function()? onReconnecting,
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
    List<Duration> reconnectDelays = _defaultReconnectDelays,
  }) async {
    final controller = _LiveEventSubscriptionController(
      connect: _connect,
      eventCodec: eventCodec,
      snapshotCodec: snapshotCodec,
      matchId: matchId,
      token: token,
      tokenReader: tokenReader,
      fromOffset: fromOffset,
      nextOffset: nextOffset,
      onEvent: onEvent,
      onSnapshotResync: onSnapshotResync,
      onMatch: onMatch,
      onConnected: onConnected,
      onReconnecting: onReconnecting,
      onError: onError,
      onDone: onDone,
      reconnectDelays: reconnectDelays,
    );
    await controller.start();
    return LiveEventSubscriptionHandle._(controller);
  }

  @visibleForTesting
  static void resetLocalCommandEchoGuardForTesting() {
    _localCommandEchoGuard.clear();
  }
}

final _localCommandEchoGuard = _LocalCommandEchoGuard();

class _LiveEventSubscriptionController {
  final MultiplayerStreamConnector connect;
  final EventCodec eventCodec;
  final SnapshotCodec snapshotCodec;
  final String matchId;
  final AuthToken token;
  final MultiplayerAuthTokenReader? tokenReader;
  final int Function()? nextOffset;
  final void Function(LiveServerEvent event) onEvent;
  final void Function(CanonicalGameSnapshot snapshot) onSnapshotResync;
  final void Function(WireMatch match)? onMatch;
  final void Function()? onConnected;
  final void Function()? onReconnecting;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function()? onDone;
  final List<Duration> reconnectDelays;

  StreamController<sp.MultiplayerClientMessage>? _input;
  StreamSubscription<sp.MultiplayerServerMessage>? _subscription;
  final Queue<Completer<WireCommandAck>> _pendingAcks = Queue();
  var _trackedNextOffset = 0;
  var _closed = false;
  var _reconnecting = false;

  _LiveEventSubscriptionController({
    required this.connect,
    required this.eventCodec,
    required this.snapshotCodec,
    required this.matchId,
    required this.token,
    required this.tokenReader,
    required int fromOffset,
    required this.nextOffset,
    required this.onEvent,
    required this.onSnapshotResync,
    required this.onMatch,
    required this.onConnected,
    required this.onReconnecting,
    required this.onError,
    required this.onDone,
    required this.reconnectDelays,
  }) : _trackedNextOffset = fromOffset;

  Future<void> start() {
    return _connectOnce();
  }

  Future<void> close() async {
    _closed = true;
    _failPendingAcks(TimeoutException('Live event stream closed.'));
    await _disconnectCurrent();
  }

  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final input = _input;
    if (_closed || input == null || input.isClosed) {
      throw TimeoutException('Live event stream is not ready for commands.');
    }

    final ack = Completer<WireCommandAck>();
    _pendingAcks.add(ack);
    try {
      _localCommandEchoGuard.remember(wire);
      input.add(
        sp.MultiplayerClientMessage(
          clientMessageId: clientMessageId,
          lastSeenOffset: afterOffset,
          requestSnapshot: false,
          command: wire,
        ),
      );
    } catch (error, stackTrace) {
      _pendingAcks.remove(ack);
      ack.completeError(error, stackTrace);
    }

    return ack.future.timeout(
      timeout,
      onTimeout: () {
        _pendingAcks.remove(ack);
        throw TimeoutException('Serverpod command ACK timed out.');
      },
    );
  }

  Future<void> _connectOnce() async {
    final currentToken = await tokenReader?.call() ?? token;
    final input = StreamController<sp.MultiplayerClientMessage>();
    late final Stream<sp.MultiplayerServerMessage> messages;
    try {
      messages = connect(
        matchId: matchId,
        token: currentToken,
        afterOffset: _afterOffsetForReconnect(),
        input: input.stream,
      );
    } catch (_) {
      await input.close();
      rethrow;
    }
    if (_closed) {
      await input.close();
      return;
    }
    onConnected?.call();
    _input = input;
    _subscription = messages.listen(
      (message) {
        try {
          _handleMessage(message);
        } catch (error, stackTrace) {
          _reportError(error, stackTrace);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace);
        unawaited(_reconnect());
      },
      onDone: () {
        if (_closed) return;
        onDone?.call();
        unawaited(_reconnect());
      },
      cancelOnError: false,
    );
  }

  void _handleMessage(sp.MultiplayerServerMessage message) {
    final ack = message.ack;
    if (ack != null) _completeNextAck(ack);

    final match = message.match;
    if (match != null) {
      onMatch?.call(match);
    }

    final snapshot = message.snapshot;
    final event = message.event;
    CanonicalGameSnapshot? saveSnapshot;
    if (snapshot != null) {
      saveSnapshot = snapshotCodec.fromWire(snapshot);
      _advanceTrackedOffset(saveSnapshot.eventLogOffset);
      if (event == null) {
        onSnapshotResync(saveSnapshot);
      }
    }

    if (event != null) {
      _advanceTrackedOffset(event.offset);
      if (_localCommandEchoGuard.isLocalEcho(event)) return;
      onEvent(
        LiveServerEvent.fromWire(
          wire: event,
          events: eventCodec.eventsFromWire(event),
          combatAnimations: eventCodec.combatAnimationFactsFromWire(event),
          snapshot: saveSnapshot,
        ),
      );
    }
  }

  Future<void> _reconnect() async {
    if (_closed || _reconnecting) return;
    _reconnecting = true;
    onReconnecting?.call();
    await _disconnectCurrent();
    var attempt = 0;
    while (!_closed) {
      final delay = _reconnectDelay(attempt);
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (_closed) break;
      try {
        await _connectOnce();
        _reconnecting = false;
        return;
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
        if (error is NetworkSessionAuthenticationException) {
          _closed = true;
          await _disconnectCurrent();
          break;
        }
        attempt += 1;
      }
    }
    _reconnecting = false;
  }

  Future<void> _disconnectCurrent() async {
    final subscription = _subscription;
    final input = _input;
    _subscription = null;
    _input = null;
    _failPendingAcks(TimeoutException('Live event stream disconnected.'));
    await subscription?.cancel();
    await input?.close();
  }

  void _reportError(Object error, StackTrace stackTrace) {
    onError?.call(mapServerpodMultiplayerFailure(error), stackTrace);
  }

  int _offsetForReconnect() {
    final offset = nextOffset?.call() ?? _trackedNextOffset;
    return offset < 0 ? 0 : offset;
  }

  int _afterOffsetForReconnect() {
    final next = _offsetForReconnect();
    return next <= 0 ? 0 : next - 1;
  }

  void _advanceTrackedOffset(int offset) {
    if (offset >= _trackedNextOffset) {
      _trackedNextOffset = offset + 1;
    }
  }

  Duration _reconnectDelay(int attempt) {
    if (reconnectDelays.isEmpty) return Duration.zero;
    if (attempt < reconnectDelays.length) return reconnectDelays[attempt];
    return reconnectDelays.last;
  }

  void _completeNextAck(WireCommandAck ack) {
    if (_pendingAcks.isEmpty) return;
    final pending = _pendingAcks.removeFirst();
    if (!pending.isCompleted) pending.complete(ack);
  }

  void _failPendingAcks(Object error, [StackTrace? stackTrace]) {
    while (_pendingAcks.isNotEmpty) {
      final pending = _pendingAcks.removeFirst();
      if (!pending.isCompleted) {
        pending.completeError(error, stackTrace);
      }
    }
  }
}

class LiveEventSubscriptionHandle implements LiveMultiplayerEventHandle {
  final _LiveEventSubscriptionController _controller;

  const LiveEventSubscriptionHandle._(this._controller);

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _controller.sendCommand(
      afterOffset: afterOffset,
      wire: wire,
      clientMessageId: clientMessageId,
      timeout: timeout,
    );
  }
}
