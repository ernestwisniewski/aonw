import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';

final class ClientMessageGuard {
  ClientMessageGuard({
    required this.expectedMatchId,
    DateTime Function()? nowUtc,
    this.maxPendingMessages = 32,
    this.maxBurstMessages = 40,
    this.messagesPerSecond = 20,
  }) : assert(maxPendingMessages > 0),
       assert(maxBurstMessages > 0),
       assert(messagesPerSecond > 0),
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _availableTokens = maxBurstMessages.toDouble() {
    _lastRefill = _nowUtc();
  }

  static const int maxClientMessageIdLength = 128;
  static const int maxActorPlayerIdLength = 128;
  static const int maxPayloadDepth = 10;
  static const int maxPayloadNodes = 512;
  static const int maxPayloadStringUnits = 16 * 1024;

  static final RegExp _messageIdPattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._:-]*$',
  );

  final String expectedMatchId;
  final DateTime Function() _nowUtc;
  final int maxPendingMessages;
  final int maxBurstMessages;
  final int messagesPerSecond;

  late DateTime _lastRefill;
  double _availableTokens;
  int _pendingMessages = 0;

  void admit(MultiplayerClientMessage message) {
    _validate(message);
    if (_pendingMessages >= maxPendingMessages) {
      throw multiplayerException(
        'connection_backpressure',
        'Too many client messages are waiting to be processed.',
      );
    }

    _refillTokens();
    if (_availableTokens < 1) {
      throw multiplayerException(
        'rate_limit_exceeded',
        'Client message rate limit exceeded.',
      );
    }

    _availableTokens -= 1;
    _pendingMessages += 1;
  }

  void release() {
    if (_pendingMessages > 0) _pendingMessages -= 1;
  }

  void _validate(MultiplayerClientMessage message) {
    final messageId = message.clientMessageId;
    if (messageId.isEmpty ||
        messageId.length > maxClientMessageIdLength ||
        !_messageIdPattern.hasMatch(messageId)) {
      _invalid('Client message id is invalid.');
    }
    if (message.lastSeenOffset < 0) {
      _invalid('Last seen offset cannot be negative.');
    }

    final command = message.command;
    if (command == null) return;
    if (command.matchId != expectedMatchId) {
      _invalid('Command match id does not match the connection.');
    }
    if (command.tick < 0 || (command.turn != null && command.turn! < 0)) {
      _invalid('Command tick and turn cannot be negative.');
    }
    if (command.actorPlayerId.isEmpty ||
        command.actorPlayerId.length > maxActorPlayerIdLength) {
      _invalid('Command actor id is invalid.');
    }
    if (command.command.isEmpty) {
      _invalid('Command payload cannot be empty.');
    }

    _PayloadBudget().visit(command.command);
  }

  void _refillTokens() {
    final now = _nowUtc();
    final elapsedMicroseconds = now.difference(_lastRefill).inMicroseconds;
    if (elapsedMicroseconds <= 0) return;
    _lastRefill = now;
    final refill = elapsedMicroseconds * messagesPerSecond / 1000000;
    _availableTokens = (_availableTokens + refill).clamp(
      0,
      maxBurstMessages.toDouble(),
    );
  }

  Never _invalid(String message) {
    throw multiplayerException('invalid_client_message', message);
  }
}

final class _PayloadBudget {
  int _remainingNodes = ClientMessageGuard.maxPayloadNodes;
  int _remainingStringUnits = ClientMessageGuard.maxPayloadStringUnits;

  void visit(Object? value, [int depth = 0]) {
    if (depth > ClientMessageGuard.maxPayloadDepth || --_remainingNodes < 0) {
      _invalid();
    }

    switch (value) {
      case null || bool() || num():
        return;
      case String():
        _consumeString(value);
      case List<Object?>():
        for (final child in value) {
          visit(child, depth + 1);
        }
      case Map<Object?, Object?>():
        for (final entry in value.entries) {
          final key = entry.key;
          if (key is! String) _invalid();
          _consumeString(key);
          visit(entry.value, depth + 1);
        }
      default:
        _invalid();
    }
  }

  void _consumeString(String value) {
    _remainingStringUnits -= value.length;
    if (_remainingStringUnits < 0) _invalid();
  }

  Never _invalid() {
    throw multiplayerException(
      'invalid_client_message',
      'Command payload exceeds the allowed complexity.',
    );
  }
}
