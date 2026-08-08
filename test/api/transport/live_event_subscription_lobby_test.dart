import 'dart:async';

import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveEventSubscription lobby connection', () {
    test(
      'sends an empty heartbeat every ten seconds and stops on close',
      () async {
        final connector = _LobbyStreamConnector();
        late _ManualPeriodicTimer heartbeat;
        final live = LiveEventSubscription(
          serverpodHost: 'https://api.example.test',
          connector: connector.connect,
          heartbeatTimerFactory: (interval, onTick) {
            expect(interval, const Duration(seconds: 10));
            return heartbeat = _ManualPeriodicTimer(onTick);
          },
        );
        final handle = await live.subscribe(
          matchId: 'match_1',
          token: AuthToken('jwt-token'),
          fromOffset: 7,
          onEvent: (_) {},
          onSnapshotResync: (_) {},
        );
        final connection = connector.connections.single;

        heartbeat.fire();
        await Future<void>.delayed(Duration.zero);

        expect(connection.clientMessages, hasLength(1));
        final message = connection.clientMessages.single;
        expect(message.clientMessageId, 'heartbeat:1');
        expect(message.lastSeenOffset, 6);
        expect(message.requestSnapshot, isFalse);
        expect(message.command, isNull);

        await handle.close();
        expect(heartbeat.isActive, isFalse);
        heartbeat.fire();
        await Future<void>.delayed(Duration.zero);
        expect(connection.clientMessages, hasLength(1));
      },
    );

    test('replaces the heartbeat timer on reconnect', () async {
      final connector = _LobbyStreamConnector();
      final heartbeats = <_ManualPeriodicTimer>[];
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
        heartbeatTimerFactory: (_, onTick) {
          final timer = _ManualPeriodicTimer(onTick);
          heartbeats.add(timer);
          return timer;
        },
      );
      final handle = await live.subscribe(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        fromOffset: 0,
        reconnectDelays: const [Duration.zero],
        onEvent: (_) {},
        onSnapshotResync: (_) {},
      );

      await connector.connections.single.close();
      await _waitFor(() => connector.connections.length == 2);

      expect(heartbeats, hasLength(2));
      expect(heartbeats.first.isActive, isFalse);
      expect(heartbeats.last.isActive, isTrue);

      await handle.close();
      expect(heartbeats.last.isActive, isFalse);
      await connector.connections.last.close();
    });

    test('terminal membership failures never enter the retry loop', () async {
      const terminalCodes = [
        'not_match_player',
        'match_not_found',
        'match_abandoned',
        'match_not_open',
        'unsupported_match_protocol',
      ];
      for (final code in terminalCodes) {
        final connector = _LobbyStreamConnector();
        final errors = <Object>[];
        final live = LiveEventSubscription(
          serverpodHost: 'https://api.example.test',
          connector: connector.connect,
        );
        final handle = await live.subscribe(
          matchId: 'match_1',
          token: AuthToken('jwt-token'),
          fromOffset: 0,
          reconnectDelays: const [Duration.zero],
          onEvent: (_) {},
          onSnapshotResync: (_) {},
          onError: (error, _) => errors.add(error),
        );

        connector.connections.single.addError(
          MultiplayerFailure.multiplayer(code: code),
        );
        await _waitFor(() => errors.isNotEmpty);
        await Future<void>.delayed(Duration.zero);

        expect(connector.connections, hasLength(1), reason: code);
        expect((errors.single as MultiplayerFailure).code, code, reason: code);
        await handle.close();
        await connector.connections.single.close();
      }
    });
  });
}

final class _LobbyStreamConnector {
  final connections = <_LobbyStreamConnection>[];

  Stream<sp.MultiplayerServerMessage> connect({
    required String matchId,
    required AuthToken token,
    required int afterOffset,
    required Stream<sp.MultiplayerClientMessage> input,
  }) {
    final connection = _LobbyStreamConnection(input);
    connections.add(connection);
    return connection.stream;
  }
}

final class _LobbyStreamConnection {
  final clientMessages = <sp.MultiplayerClientMessage>[];
  final _messages = StreamController<sp.MultiplayerServerMessage>();

  _LobbyStreamConnection(Stream<sp.MultiplayerClientMessage> input) {
    input.listen(clientMessages.add);
  }

  Stream<sp.MultiplayerServerMessage> get stream => _messages.stream;

  void addError(Object error) {
    _messages.addError(error, StackTrace.empty);
  }

  Future<void> close() => _messages.close();
}

final class _ManualPeriodicTimer implements Timer {
  final void Function(Timer timer) onTick;
  var _active = true;
  var _ticks = 0;

  _ManualPeriodicTimer(this.onTick);

  void fire() {
    if (!_active) return;
    _ticks += 1;
    onTick(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => _ticks;

  @override
  void cancel() => _active = false;
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i += 1) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time.');
}
