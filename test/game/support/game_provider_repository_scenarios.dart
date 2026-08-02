part of '../game_providers_test.dart';

void _registerGameRepositoryProviderScenarios() {
  group('gameRepositoryProvider', () {
    test('uses JSON repository by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(gameRepositoryProvider), isA<JsonGameRepository>());
    });

    test(
      'keeps default repository local while multiplayer match can resume',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(networkSessionStateProvider.notifier)
            .set(
              api.NetworkSession(
                userId: 'user_1',
                playerId: 'player_1',
                token: AuthToken('token'),
                matchId: 'match_1',
                connectionState: const NetworkConnectionState(
                  status: NetworkConnectionStatus.connected,
                ),
              ),
            );

        expect(
          container.read(gameRepositoryProvider),
          isA<JsonGameRepository>(),
        );
      },
    );
  });
}
