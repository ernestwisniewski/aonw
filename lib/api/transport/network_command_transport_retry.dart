part of 'network_command_transport.dart';

extension _NetworkCommandTransportRetry on NetworkCommandTransport {
  ({WireCommand wire, String clientMessageId})
  _wireCommandForRetryableDispatch({
    required String saveId,
    required String actorPlayerId,
    required int? turn,
    required DomainCommand command,
  }) {
    final retryable = _retryableCommand;
    if (retryable != null &&
        retryable.matches(
          saveId: saveId,
          actorPlayerId: actorPlayerId,
          turn: turn,
          command: command,
        )) {
      return (wire: retryable.wire, clientMessageId: retryable.clientMessageId);
    }

    _retryableCommand = null;
    final wire = commandCodec.toWire(
      matchId: saveId,
      tick: tickGenerator.next(),
      turn: turn,
      actorPlayerId: actorPlayerId,
      command: command,
    );
    return (wire: wire, clientMessageId: messageIdGenerator.next());
  }

  Future<WireCommandAck> _sendWireCommand({
    required String saveId,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    try {
      final currentToken = await tokenReader?.call() ?? token;
      return await commandDispatcher.send(
        saveId: saveId,
        token: currentToken,
        afterOffset: _lastKnownOffsetBySaveId[saveId] ?? 0,
        wire: wire,
        clientMessageId: clientMessageId,
      );
    } catch (error) {
      if (_isRetryableCommandSendError(error)) {
        _retryableCommand = _RetryableServerCommand(
          saveId: saveId,
          actorPlayerId: wire.actorPlayerId,
          turn: wire.turn,
          command: commandCodec.fromWire(wire),
          wire: wire,
          clientMessageId: clientMessageId,
        );
      } else {
        _clearRetryableCommand(wire);
      }
      rethrow;
    }
  }

  void _clearRetryableCommand(WireCommand wire) {
    final retryable = _retryableCommand;
    if (retryable == null || identical(retryable.wire, wire)) {
      _retryableCommand = null;
    }
  }

  bool _isRetryableCommandSendError(Object error) {
    return error is TimeoutException ||
        error is sp.MethodStreamException ||
        (error is sp.ServerpodClientException &&
            (error.statusCode < 0 || error.statusCode >= 500));
  }

  bool _isStaleCommandVersionError(NetworkCommandConflictException error) {
    return error.code == 'stale_tick' || error.code == 'stale_turn';
  }

  bool _isStaleAckReason(String? reason) {
    return reason == 'stale_tick' || reason == 'stale_turn';
  }

  bool _isStaleTickError(NetworkCommandConflictException error) {
    return error.code == 'stale_tick';
  }

  int? _nextTickFromStaleTickError(NetworkCommandConflictException error) {
    return error.nextTick;
  }
}

class _RetryableServerCommand {
  final String saveId;
  final String actorPlayerId;
  final int? turn;
  final DomainCommand command;
  final WireCommand wire;
  final String clientMessageId;

  const _RetryableServerCommand({
    required this.saveId,
    required this.actorPlayerId,
    required this.turn,
    required this.command,
    required this.wire,
    required this.clientMessageId,
  });

  bool matches({
    required String saveId,
    required String actorPlayerId,
    required int? turn,
    required DomainCommand command,
  }) {
    return this.saveId == saveId &&
        this.actorPlayerId == actorPlayerId &&
        this.turn == turn &&
        this.command == command;
  }

  bool isSameCommand({
    required String saveId,
    required String actorPlayerId,
    required DomainCommand command,
  }) {
    return this.saveId == saveId &&
        this.actorPlayerId == actorPlayerId &&
        this.command == command;
  }
}
