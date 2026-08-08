part of 'live_event_subscription.dart';

extension _LiveEventSubscriptionConnection on _LiveEventSubscriptionController {
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
        final mapped = _reportError(error, stackTrace);
        if (_isTerminalConnectionError(mapped)) {
          _closed = true;
          unawaited(_disconnectCurrent());
          return;
        }
        unawaited(_reconnect());
      },
      onDone: () {
        if (_closed) return;
        onDone?.call();
        unawaited(_reconnect());
      },
      cancelOnError: false,
    );
    _startHeartbeat(input);
    onConnected?.call();
  }

  Future<void> _reconnect() async {
    if (_closed || _reconnecting) return;
    _reconnecting = true;
    _stopHeartbeat();
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
        final mapped = _reportError(error, stackTrace);
        if (mapped is NetworkSessionAuthenticationException ||
            _isTerminalConnectionError(mapped)) {
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
    _stopHeartbeat();
    final subscription = _subscription;
    final input = _input;
    _subscription = null;
    _input = null;
    _failPendingAcks(TimeoutException('Live event stream disconnected.'));
    await subscription?.cancel();
    await input?.close();
  }

  Object _reportError(Object error, StackTrace stackTrace) {
    final mapped = mapServerpodMultiplayerFailure(error);
    onError?.call(mapped, stackTrace);
    return mapped;
  }

  bool _isTerminalConnectionError(Object error) {
    return error is MultiplayerFailure && error.terminatesLobbyMembership;
  }

  void _startHeartbeat(StreamController<sp.MultiplayerClientMessage> input) {
    _stopHeartbeat();
    if (heartbeatInterval <= Duration.zero) return;
    _heartbeatTimer = heartbeatTimerFactory(heartbeatInterval, (_) {
      if (_closed ||
          _reconnecting ||
          !identical(_input, input) ||
          input.isClosed) {
        return;
      }
      try {
        _heartbeatSequence += 1;
        input.add(
          sp.MultiplayerClientMessage(
            clientMessageId: 'heartbeat:$_heartbeatSequence',
            lastSeenOffset: _afterOffsetForReconnect(),
            requestSnapshot: false,
          ),
        );
      } catch (error, stackTrace) {
        final mapped = _reportError(error, stackTrace);
        if (_isTerminalConnectionError(mapped)) {
          _closed = true;
          unawaited(_disconnectCurrent());
          return;
        }
        unawaited(_reconnect());
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
