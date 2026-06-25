import 'dart:async';
import 'dart:collection';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/foundation.dart';

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

class LiveServerEvent {
  final WireEvent wire;
  final List<GameEvent> events;
  final SaveSnapshot? snapshot;

  const LiveServerEvent({
    required this.wire,
    required this.events,
    this.snapshot,
  });
}

class ServerpodMultiplayerStreamConnector {
  final String serverpodHost;

  const ServerpodMultiplayerStreamConnector(this.serverpodHost);

  Stream<sp.MultiplayerServerMessage> connect({
    required String matchId,
    required AuthToken token,
    required int afterOffset,
    required Stream<sp.MultiplayerClientMessage> input,
  }) {
    final client = createServerpodClient(serverpodHost, token: token);
    return client.multiplayer.connect(matchId, afterOffset, input);
  }
}

class LiveEventSubscription {
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

  Future<LiveEventSubscriptionHandle> subscribe({
    required String matchId,
    required AuthToken token,
    required int fromOffset,
    int Function()? nextOffset,
    required void Function(LiveServerEvent event) onEvent,
    required void Function(SaveSnapshot snapshot) onSnapshotResync,
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
  final int Function()? nextOffset;
  final void Function(LiveServerEvent event) onEvent;
  final void Function(SaveSnapshot snapshot) onSnapshotResync;
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
  var _nextClientMessageId = 0;

  _LiveEventSubscriptionController({
    required this.connect,
    required this.eventCodec,
    required this.snapshotCodec,
    required this.matchId,
    required this.token,
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
    Duration timeout = const Duration(seconds: 10),
  }) {
    final input = _input;
    if (_closed || input == null || input.isClosed) {
      throw TimeoutException('Live event stream is not ready for commands.');
    }

    final ack = Completer<WireCommandAck>();
    _pendingAcks.add(ack);
    final clientMessageId = _nextCommandClientMessageId(wire);
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
    final input = StreamController<sp.MultiplayerClientMessage>();
    final messages = connect(
      matchId: matchId,
      token: token,
      afterOffset: _afterOffsetForReconnect(),
      input: input.stream,
    );
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
          onError?.call(error, stackTrace);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        onError?.call(error, stackTrace);
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
    if (ack != null) {
      _completeNextAck(ack);
    }

    final match = message.match;
    if (match != null) {
      onMatch?.call(match);
    }

    final snapshot = message.snapshot;
    final event = message.event;
    SaveSnapshot? saveSnapshot;
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
        LiveServerEvent(
          wire: event,
          events: eventCodec.eventsFromWire(event),
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
        onError?.call(error, stackTrace);
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

  String _nextCommandClientMessageId(WireCommand wire) {
    _nextClientMessageId += 1;
    return 'live-cmd-${wire.actorPlayerId}-${wire.tick}-$_nextClientMessageId';
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

class _LocalCommandEchoGuard {
  static const _ttl = Duration(seconds: 10);
  static const _maxKeys = 128;

  final Queue<_LocalCommandEchoKey> _keys = Queue();

  void remember(WireCommand wire) {
    _prune();
    _keys.addLast(
      _LocalCommandEchoKey(
        matchId: wire.matchId,
        actorPlayerId: wire.actorPlayerId,
        tick: wire.tick,
        rememberedAt: DateTime.now(),
      ),
    );
    while (_keys.length > _maxKeys) {
      _keys.removeFirst();
    }
  }

  bool isLocalEcho(WireEvent event) {
    _prune();
    for (final key in _keys) {
      if (key.matches(event)) return true;
    }
    return false;
  }

  void clear() {
    _keys.clear();
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(_ttl);
    while (_keys.isNotEmpty && _keys.first.rememberedAt.isBefore(cutoff)) {
      _keys.removeFirst();
    }
  }
}

class _LocalCommandEchoKey {
  const _LocalCommandEchoKey({
    required this.matchId,
    required this.actorPlayerId,
    required this.tick,
    required this.rememberedAt,
  });

  final String matchId;
  final String actorPlayerId;
  final int tick;
  final DateTime rememberedAt;

  bool matches(WireEvent event) {
    return event.matchId == matchId &&
        event.actorPlayerId == actorPlayerId &&
        event.tick == tick;
  }
}

class LiveEventSubscriptionHandle {
  final _LiveEventSubscriptionController _controller;

  const LiveEventSubscriptionHandle._(this._controller);

  Future<void> close() async {
    await _controller.close();
  }

  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _controller.sendCommand(
      afterOffset: afterOffset,
      wire: wire,
      timeout: timeout,
    );
  }
}
