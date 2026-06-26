import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_navigation_coordinator.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyMatchNavigationCoordinator', () {
    test('defers navigation and stores the match session', () {
      final harness = _Harness();

      harness.coordinator.enter(session: harness.session, match: harness.match);
      expect(harness.stoppedCount, 1);
      expect(harness.routes, isEmpty);

      harness.flushDeferred();

      expect(harness.sessions.single.matchId, 'match_1');
      expect(harness.sessions.single.playerId, 'player_1');
      final route = Uri.parse(harness.routes.single);
      expect(route.path, '/game');
      expect(route.queryParameters['saveId'], 'match_1');
      expect(route.queryParameters['name'], 'verdantia prime');
      expect(route.queryParameters['source'], 'asset');
    });

    test('ignores duplicate enters until the deferred enter resolves', () {
      final harness = _Harness();

      harness.coordinator.enter(session: harness.session, match: harness.match);
      harness.coordinator.enter(session: harness.session, match: harness.match);
      harness.flushDeferred();

      expect(harness.stoppedCount, 1);
      expect(harness.routes, hasLength(1));
    });

    test('drops stale, disconnected or unmounted deferred enters', () {
      final stale = _Harness(activeMatch: _match(id: 'other_match'));
      stale.coordinator.enter(session: stale.session, match: stale.match);
      stale.flushDeferred();
      expect(stale.routes, isEmpty);

      final disconnected = _Harness(session: _session(connected: false));
      disconnected.coordinator.enter(
        session: disconnected.session,
        match: disconnected.match,
      );
      disconnected.flushDeferred();
      expect(disconnected.routes, isEmpty);

      final unmounted = _Harness(canContinue: false);
      unmounted.coordinator.enter(
        session: unmounted.session,
        match: unmounted.match,
      );
      unmounted.flushDeferred();
      expect(unmounted.routes, isEmpty);
    });

    test('allows retry after a stale deferred enter clears the guard', () {
      final harness = _Harness(activeMatch: _match(id: 'other_match'));
      final coordinator = harness.coordinator;
      final session = harness.session;
      final match = harness.match;
      void enter() => coordinator.enter(session: session, match: match);

      enter();
      harness
        ..flushDeferred()
        ..activeMatch = match;
      enter();
      harness.flushDeferred();

      expect(harness.routes, hasLength(1));
    });

    test('builds a map-source aware game location', () {
      final location = LobbyMatchNavigationCoordinator.gameLocation(
        match: _match(mapName: 'generated coast'),
        mapSource: MapSource.saved,
      );

      final route = Uri.parse(location);
      expect(route.path, '/game');
      expect(route.queryParameters['name'], 'generated coast');
      expect(route.queryParameters['source'], 'saved');
    });
  });
}

final class _Harness {
  final NetworkSession session;
  final WireMatch match;
  final bool canContinue;

  WireMatch? activeMatch;
  var stoppedCount = 0;
  final deferred = <void Function()>[];
  final sessions = <NetworkSession>[];
  final routes = <String>[];

  _Harness({
    NetworkSession? session,
    WireMatch? match,
    WireMatch? activeMatch,
    this.canContinue = true,
  }) : session = session ?? _session(),
       match = match ?? _match() {
    this.activeMatch = activeMatch ?? this.match;
  }

  late final LobbyMatchNavigationCoordinator coordinator =
      LobbyMatchNavigationCoordinator(
        activeMatch: () => activeMatch,
        canContinue: () => canContinue,
        sessionForMatch: ({required session, required match}) {
          return session.copyWith(
            matchId: match.id,
            playerId: match.players.first.id,
          );
        },
        setSession: sessions.add,
        navigateTo: routes.add,
        stopLobbyUpdates: () => stoppedCount += 1,
        defer: deferred.add,
      );

  void flushDeferred() {
    final actions = List<void Function()>.of(deferred);
    deferred.clear();
    for (final action in actions) {
      action();
    }
  }
}

NetworkSession _session({bool connected = true}) {
  return NetworkSession(
    userId: 'user_1',
    token: AuthToken('token'),
    connectionState: NetworkConnectionState(
      status: connected
          ? NetworkConnectionStatus.connected
          : NetworkConnectionStatus.offline,
    ),
  );
}

WireMatch _match({String id = 'match_1', String mapName = 'verdantia prime'}) {
  return WireMatch(
    id: id,
    ownerUserId: 'user_1',
    name: 'Quickplay',
    mapName: mapName,
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
    minPlayers: 1,
    turn: 1,
    state: 'loading',
    createdAt: DateTime.utc(2026, 6, 2),
  );
}
