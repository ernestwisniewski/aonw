import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/client_message_guard.dart';
import 'package:test/test.dart';

void main() {
  test('accepts and releases a well-formed command', () {
    final guard = ClientMessageGuard(expectedMatchId: 'match-1');

    guard.admit(_message());
    guard.release();
  });

  test('rejects malformed message metadata', () {
    final guard = ClientMessageGuard(expectedMatchId: 'match-1');

    for (final message in [
      _message(clientMessageId: ''),
      _message(clientMessageId: 'contains spaces'),
      _message(
        clientMessageId: _repeated(
          'x',
          ClientMessageGuard.maxClientMessageIdLength + 1,
        ),
      ),
      _message(lastSeenOffset: -1),
    ]) {
      expect(
        () => guard.admit(message),
        throwsA(_error('invalid_client_message')),
      );
    }
  });

  test('rejects command metadata that does not match the connection', () {
    final guard = ClientMessageGuard(expectedMatchId: 'match-1');

    for (final command in [
      _command(matchId: 'match-2'),
      _command(tick: -1),
      _command(turn: -1),
      _command(actorPlayerId: ''),
      _command(payload: const {}),
    ]) {
      expect(
        () => guard.admit(_message(command: command)),
        throwsA(_error('invalid_client_message')),
      );
    }
  });

  test('rejects command payloads that exceed the complexity budget', () {
    final guard = ClientMessageGuard(expectedMatchId: 'match-1');
    Object? nested = 'leaf';
    for (var depth = 0; depth <= ClientMessageGuard.maxPayloadDepth; depth++) {
      nested = [nested];
    }

    expect(
      () =>
          guard.admit(_message(command: _command(payload: {'nested': nested}))),
      throwsA(_error('invalid_client_message')),
    );
    expect(
      () => guard.admit(
        _message(
          command: _command(
            payload: {
              'value': _repeated(
                'x',
                ClientMessageGuard.maxPayloadStringUnits + 1,
              ),
            },
          ),
        ),
      ),
      throwsA(_error('invalid_client_message')),
    );
  });

  test('bounds the number of messages waiting for processing', () {
    final guard = ClientMessageGuard(
      expectedMatchId: 'match-1',
      maxPendingMessages: 2,
    );

    guard.admit(_message(clientMessageId: 'message-1'));
    guard.admit(_message(clientMessageId: 'message-2'));
    expect(
      () => guard.admit(_message(clientMessageId: 'message-3')),
      throwsA(_error('connection_backpressure')),
    );

    guard.release();
    guard.admit(_message(clientMessageId: 'message-3'));
  });

  test('refills the per-connection burst limit over time', () {
    var now = DateTime.utc(2026, 7, 10, 12);
    final guard = ClientMessageGuard(
      expectedMatchId: 'match-1',
      nowUtc: () => now,
      maxBurstMessages: 2,
      messagesPerSecond: 1,
    );

    guard.admit(_message(clientMessageId: 'message-1'));
    guard.release();
    guard.admit(_message(clientMessageId: 'message-2'));
    guard.release();
    expect(
      () => guard.admit(_message(clientMessageId: 'message-3')),
      throwsA(_error('rate_limit_exceeded')),
    );

    now = now.add(const Duration(seconds: 1));
    guard.admit(_message(clientMessageId: 'message-3'));
  });
}

MultiplayerClientMessage _message({
  String clientMessageId = 'message-1',
  int lastSeenOffset = 0,
  WireCommand? command,
}) {
  return MultiplayerClientMessage(
    clientMessageId: clientMessageId,
    lastSeenOffset: lastSeenOffset,
    requestSnapshot: false,
    command: command ?? _command(),
  );
}

WireCommand _command({
  String matchId = 'match-1',
  int tick = 1,
  int? turn = 1,
  String actorPlayerId = 'player-1',
  Map<String, dynamic> payload = const {'type': 'SubmitTurn'},
}) {
  return WireCommand(
    matchId: matchId,
    tick: tick,
    turn: turn,
    actorPlayerId: actorPlayerId,
    command: payload,
  );
}

Matcher _error(String code) {
  return isA<MultiplayerException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

String _repeated(String value, int count) => List.filled(count, value).join();
