import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
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
}
