import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_live_match_coordinator.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyLiveMatchCoordinator', () {
    test(
      'subscribes once and applies live match updates asynchronously',
      () async {
        final deferred = <void Function()>[];
        final applied = <WireMatch>[];
        final subscriptions = <_SubscriptionRequest>[];
        var activeMatch = _match();
        final coordinator = LobbyLiveMatchCoordinator(
          activeMatch: () => activeMatch,
          canContinue: () => true,
          subscribe:
              ({
                required session,
                required match,
                required onMatch,
                required onError,
              }) async {
                subscriptions.add(
                  _SubscriptionRequest(
                    session: session,
                    match: match,
                    onMatch: onMatch,
                    onError: onError,
                  ),
                );
                return _FakeStreamHandle();
              },
          applyMatchUpdate: ({required session, required match}) {
            applied.add(match);
            activeMatch = match;
          },
          showError: (error) => fail('$error'),
          defer: deferred.add,
        );

        void watch(WireMatch match) {
          coordinator.watch(session: _session(), match: match);
        }

        watch(activeMatch);
        watch(activeMatch);
        await Future<void>.delayed(Duration.zero);

        expect(subscriptions, hasLength(1));
        final running = _match(state: 'loading');
        subscriptions.single.onMatch(running);

        expect(applied, isEmpty);
        deferred.single();
        expect(applied, [running]);
        expect(activeMatch.state, 'loading');
      },
    );

    test('closes stale streams and ignores stale updates', () async {
      final handles = <_FakeStreamHandle>[];
      final applied = <WireMatch>[];
      final subscriptions = <_SubscriptionRequest>[];
      var activeMatch = _match(id: 'match_1');
      final coordinator = LobbyLiveMatchCoordinator(
        activeMatch: () => activeMatch,
        canContinue: () => true,
        subscribe:
            ({
              required session,
              required match,
              required onMatch,
              required onError,
            }) async {
              subscriptions.add(
                _SubscriptionRequest(
                  session: session,
                  match: match,
                  onMatch: onMatch,
                  onError: onError,
                ),
              );
              final handle = _FakeStreamHandle();
              handles.add(handle);
              return handle;
            },
        applyMatchUpdate: ({required session, required match}) {
          applied.add(match);
        },
        showError: (error) => fail('$error'),
        defer: (action) => action(),
      );

      void watchActiveMatch() {
        coordinator.watch(session: _session(), match: activeMatch);
      }

      watchActiveMatch();
      await Future<void>.delayed(Duration.zero);
      activeMatch = _match(id: 'match_2');
      watchActiveMatch();
      await Future<void>.delayed(Duration.zero);

      expect(handles.first.closed, isTrue);
      subscriptions.first.onMatch(_match(id: 'match_1', state: 'loading'));
      subscriptions.last.onMatch(_match(id: 'match_2', state: 'loading'));

      expect(applied.map((match) => match.id), const ['match_2']);
    });

    test('skips terminal matches and reports current stream errors', () async {
      final errors = <Object>[];
      final subscriptions = <_SubscriptionRequest>[];
      final coordinator = LobbyLiveMatchCoordinator(
        activeMatch: () => _match(),
        canContinue: () => true,
        subscribe:
            ({
              required session,
              required match,
              required onMatch,
              required onError,
            }) async {
              subscriptions.add(
                _SubscriptionRequest(
                  session: session,
                  match: match,
                  onMatch: onMatch,
                  onError: onError,
                ),
              );
              return _FakeStreamHandle();
            },
        applyMatchUpdate: ({required session, required match}) {},
        showError: errors.add,
        defer: (action) => action(),
      );

      void watch(WireMatch match) {
        coordinator.watch(session: _session(), match: match);
      }

      watch(_match(state: 'finished'));
      expect(subscriptions, isEmpty);

      watch(_match());
      await Future<void>.delayed(Duration.zero);
      subscriptions.single.onError(StateError('boom'), StackTrace.empty);

      expect(errors.single, isA<StateError>());
    });

    test('can ignore transient current stream errors', () async {
      final errors = <Object>[];
      final subscriptions = <_SubscriptionRequest>[];
      final coordinator = LobbyLiveMatchCoordinator(
        activeMatch: () => _match(),
        canContinue: () => true,
        subscribe:
            ({
              required session,
              required match,
              required onMatch,
              required onError,
            }) async {
              subscriptions.add(
                _SubscriptionRequest(
                  session: session,
                  match: match,
                  onMatch: onMatch,
                  onError: onError,
                ),
              );
              return _FakeStreamHandle();
            },
        applyMatchUpdate: ({required session, required match}) {},
        showError: errors.add,
        reportStreamError: (_) => false,
        defer: (action) => action(),
      );

      final watch = coordinator.watch;
      watch(session: _session(), match: _match());
      await Future<void>.delayed(Duration.zero);
      subscriptions.single.onError(
        StateError('socket closed'),
        StackTrace.empty,
      );

      expect(errors, isEmpty);
    });
  });
}

NetworkSession _session() {
  return NetworkSession(
    userId: 'user_1',
    token: AuthToken('token'),
    connectionState: const NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
    ),
  );
}

WireMatch _match({String id = 'match_1', String state = 'open'}) {
  return WireMatch(
    id: id,
    ownerUserId: 'user_1',
    name: 'Quickplay',
    mapName: 'verdantia',
    players: const [
      WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF2563EB,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
    ],
    maxPlayers: 4,
    minPlayers: 2,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 6, 2),
  );
}

final class _SubscriptionRequest {
  final NetworkSession session;
  final WireMatch match;
  final void Function(WireMatch match) onMatch;
  final void Function(Object error, StackTrace stackTrace) onError;

  const _SubscriptionRequest({
    required this.session,
    required this.match,
    required this.onMatch,
    required this.onError,
  });
}

final class _FakeStreamHandle implements LobbyLiveMatchStreamHandle {
  var closed = false;

  @override
  Future<void> close() async {
    closed = true;
  }
}
