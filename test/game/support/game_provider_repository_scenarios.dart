import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart' as api;
import 'package:aonw/game/infrastructure/persistence/json_game_repository.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void registerGameRepositoryProviderScenarios() {
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
