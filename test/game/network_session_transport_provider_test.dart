import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/api/transport/network_event_log.dart';
import 'package:aonw/api/transport/network_game_repository.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JWT rotation does not recreate active transport repositories', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final initial = NetworkSession(
      userId: 'user_1',
      playerId: 'player_1',
      token: AuthToken('jwt-1'),
      refreshToken: 'refresh-1',
      matchId: 'match_1',
      connectionState: const NetworkConnectionState(
        status: NetworkConnectionStatus.connected,
      ),
    );
    container.read(networkSessionStateProvider.notifier).set(initial);

    final repositoryBefore = container.read(networkGameRepositoryProvider);
    final eventLogBefore = container.read(networkEventLogProvider);
    container
        .read(networkSessionStateProvider.notifier)
        .set(
          initial.copyWith(
            token: AuthToken('jwt-2'),
            refreshToken: 'refresh-2',
          ),
        );

    expect(
      container.read(networkGameRepositoryProvider),
      same(repositoryBefore),
    );
    expect(container.read(networkEventLogProvider), same(eventLogBefore));
  });

  test('transport owners close clients when their scope is disposed', () {
    final container = ProviderContainer();
    final initial = NetworkSession(
      userId: 'user_1',
      playerId: 'player_1',
      token: AuthToken('jwt-1'),
      refreshToken: 'refresh-1',
      matchId: 'match_1',
      connectionState: const NetworkConnectionState(
        status: NetworkConnectionStatus.connected,
      ),
    );
    container.read(networkSessionStateProvider.notifier).set(initial);

    final firstRepository =
        container.read(networkGameRepositoryProvider) as NetworkGameRepository;
    final firstEventLog =
        container.read(networkEventLogProvider) as NetworkEventLog;
    final dispatcher =
        container.read(wireCommandDispatcherProvider)
            as ServerpodWireCommandDispatcher;
    final sessionClient = container.read(networkSessionClientProvider);

    container
        .read(networkSessionStateProvider.notifier)
        .set(initial.copyWith(matchId: 'match_2'));
    final secondRepository =
        container.read(networkGameRepositoryProvider) as NetworkGameRepository;
    final secondEventLog =
        container.read(networkEventLogProvider) as NetworkEventLog;

    expect(firstRepository.isClosed, isTrue);
    expect(firstEventLog.isClosed, isTrue);
    expect(secondRepository, isNot(same(firstRepository)));
    expect(secondEventLog, isNot(same(firstEventLog)));
    expect(dispatcher.isClosed, isFalse);
    expect(sessionClient.isClosed, isFalse);

    container.dispose();

    expect(secondRepository.isClosed, isTrue);
    expect(secondEventLog.isClosed, isTrue);
    expect(dispatcher.isClosed, isTrue);
    expect(sessionClient.isClosed, isTrue);
  });

  test(
    'live status is reduced separately from authenticated session',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = NetworkSession(
        userId: 'user_1',
        playerId: 'player_1',
        token: AuthToken('jwt-1'),
        matchId: 'match_1',
        connectionState: const NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
        ),
      );
      final changedAt = DateTime.utc(2026, 8, 2, 12);

      container.read(networkSessionStateProvider.notifier)
        ..set(session)
        ..reportTransportStatus(
          saveId: 'match_1',
          status: NetworkConnectionStatus.reconnecting,
          message: 'stream closed',
          changedAt: changedAt,
        );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(networkSessionProvider)?.isConnected, isTrue);
      final state = container.read(networkSessionStateProvider);
      expect(
        state.transportConnection.status,
        NetworkConnectionStatus.reconnecting,
      );
      expect(state.transportMessage, 'stream closed');
      final published = container.read(multiplayerConnectionStatusProvider);
      expect(published?.saveId, 'match_1');
      expect(published?.status, NetworkConnectionStatus.reconnecting);
      expect(published?.changedAt, changedAt);
    },
  );
}
