import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reducer = NetworkSessionReducer();
  final changedAt = DateTime.utc(2026, 8, 2, 12);

  group('NetworkSessionReducer', () {
    test('activates a match and describes persistence and status effects', () {
      final transition = reducer.reduce(
        NetworkSessionTransportState(session: _session()),
        ActivateNetworkMatchAction(
          expectedUserId: 'user_1',
          playerId: 'player_1',
          matchId: 'match_1',
          changedAt: changedAt,
        ),
      );

      expect(transition.state.session?.playerId, 'player_1');
      expect(transition.state.session?.matchId, 'match_1');
      expect(transition.state.transportSaveId, 'match_1');
      expect(
        transition.state.transportConnection.status,
        NetworkConnectionStatus.connected,
      );
      expect(transition.effects, hasLength(2));
      final status =
          transition.effects.first as PublishNetworkTransportStatusEffect;
      expect(status.saveId, 'match_1');
      expect(status.changedAt, changedAt);
      expect(
        (transition.effects.last as PersistNetworkMatchIdEffect).matchId,
        'match_1',
      );
    });

    test('rejects a stale account match transition', () {
      final current = NetworkSessionTransportState(session: _session());

      final transition = reducer.reduce(
        current,
        ActivateNetworkMatchAction(
          expectedUserId: 'other_user',
          playerId: 'player_1',
          matchId: 'match_1',
          changedAt: changedAt,
        ),
      );

      expect(transition.state, same(current));
      expect(transition.effects, isEmpty);
    });

    test('tracks live transport reconnect without disconnecting auth', () {
      final session = _session(matchId: 'match_1');
      final current = NetworkSessionTransportState(
        session: session,
        transportSaveId: 'match_1',
        transportConnection: session.connectionState,
      );

      final transition = reducer.reduce(
        current,
        ReportNetworkTransportStatusAction(
          saveId: 'match_1',
          status: NetworkConnectionStatus.reconnecting,
          changedAt: changedAt,
          message: 'stream closed',
        ),
      );

      expect(transition.state.session?.isConnected, isTrue);
      expect(
        transition.state.transportConnection.status,
        NetworkConnectionStatus.reconnecting,
      );
      expect(transition.state.transportMessage, 'stream closed');
      expect(
        transition.effects.single,
        isA<PublishNetworkTransportStatusEffect>(),
      );
    });

    test('deduplicates an unchanged transport report', () {
      final current = NetworkSessionTransportState(
        session: _session(matchId: 'match_1'),
        transportSaveId: 'match_1',
        transportConnection: NetworkConnectionState(
          status: NetworkConnectionStatus.reconnecting,
          changedAt: changedAt,
        ),
        transportMessage: 'stream closed',
      );

      final transition = reducer.reduce(
        current,
        ReportNetworkTransportStatusAction(
          saveId: 'match_1',
          status: NetworkConnectionStatus.reconnecting,
          changedAt: changedAt.add(const Duration(seconds: 1)),
          message: 'stream closed',
        ),
      );

      expect(transition.state, same(current));
      expect(transition.effects, isEmpty);
    });

    test('token rotation preserves the current live transport state', () {
      final current = NetworkSessionTransportState(
        session: _session(matchId: 'match_1'),
        transportSaveId: 'match_1',
        transportConnection: NetworkConnectionState(
          status: NetworkConnectionStatus.reconnecting,
          changedAt: changedAt,
        ),
        transportMessage: 'retrying',
      );

      final transition = reducer.reduce(
        current,
        ReplaceNetworkSessionAction(
          current.session!.copyWith(
            token: AuthToken('rotated-token'),
            refreshToken: 'rotated-refresh',
          ),
        ),
      );

      expect(transition.state.session?.token.value, 'rotated-token');
      expect(
        transition.state.transportConnection.status,
        NetworkConnectionStatus.reconnecting,
      );
      expect(transition.state.transportMessage, 'retrying');
      expect(transition.effects, isEmpty);
    });

    test('clears active match and emits cleanup effects', () {
      final session = _session(matchId: 'match_1');
      final transition = reducer.reduce(
        NetworkSessionTransportState(
          session: session,
          transportSaveId: 'match_1',
          transportConnection: session.connectionState,
        ),
        ClearNetworkMatchAction(expectedUserId: 'user_1', changedAt: changedAt),
      );

      expect(transition.state.session?.matchId, isNull);
      expect(transition.state.session?.playerId, isNull);
      expect(transition.state.transportSaveId, isNull);
      expect(
        transition.state.transportConnection.status,
        NetworkConnectionStatus.offline,
      );
      expect(transition.effects, hasLength(2));
      expect(
        (transition.effects.first as ClearNetworkTransportStatusEffect).saveId,
        'match_1',
      );
      expect(
        (transition.effects.last as PersistNetworkMatchIdEffect).matchId,
        isNull,
      );
    });

    test('remembers only the match owned by the current session', () {
      final current = NetworkSessionTransportState(
        session: _session(matchId: 'match_1'),
      );

      final accepted = reducer.reduce(
        current,
        const RememberNetworkMatchAction('match_1'),
      );
      final stale = reducer.reduce(
        current,
        const RememberNetworkMatchAction('match_2'),
      );

      expect(
        (accepted.effects.single as PersistNetworkMatchIdEffect).matchId,
        'match_1',
      );
      expect(stale.effects, isEmpty);
    });
  });

  test(
    'NetworkSessionEffectRunner executes effects and isolates failures',
    () async {
      final calls = <String>[];
      final errors = <Object>[];
      final runner = NetworkSessionEffectRunner(
        persistMatchId: (matchId) async {
          calls.add('persist:$matchId');
          throw StateError('storage unavailable');
        },
        publishTransportStatus: (effect) {
          calls.add('publish:${effect.saveId}:${effect.status.name}');
        },
        clearTransportStatus: (saveId) {
          calls.add('clear:$saveId');
        },
        onError: (error, _) => errors.add(error),
      );

      await runner.runAll([
        const PersistNetworkMatchIdEffect('match_1'),
        PublishNetworkTransportStatusEffect(
          saveId: 'match_1',
          status: NetworkConnectionStatus.reconnecting,
          changedAt: changedAt,
        ),
        const ClearNetworkTransportStatusEffect('match_1'),
      ]);

      expect(calls, [
        'persist:match_1',
        'publish:match_1:reconnecting',
        'clear:match_1',
      ]);
      expect(errors.single, isA<StateError>());
    },
  );

  test('NetworkSessionEffectRunner serializes persistence effects', () async {
    final firstWrite = Completer<void>();
    final calls = <String?>[];
    final runner = NetworkSessionEffectRunner(
      persistMatchId: (matchId) async {
        calls.add(matchId);
        if (matchId == 'match_1') await firstWrite.future;
      },
      publishTransportStatus: (_) {},
      clearTransportStatus: (_) {},
      onError: (_, _) {},
    );

    final first = runner.runAll([const PersistNetworkMatchIdEffect('match_1')]);
    final second = runner.runAll([
      const PersistNetworkMatchIdEffect('match_2'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(calls, ['match_1']);
    firstWrite.complete();
    await Future.wait([first, second]);
    expect(calls, ['match_1', 'match_2']);
  });
}

NetworkSession _session({String? matchId}) {
  return NetworkSession(
    userId: 'user_1',
    playerId: matchId == null ? null : 'player_1',
    token: AuthToken('token'),
    refreshToken: 'refresh',
    matchId: matchId,
    connectionState: NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
      changedAt: DateTime.utc(2026, 8, 2),
    ),
  );
}
