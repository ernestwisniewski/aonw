import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/screens/game/game_abandoned_match_boundary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matchId = 'match_abandoned';
const _selection = MapSelection(name: 'test', source: MapSource.asset);

final class _RecordingGameStateNotifier extends GameStateNotifier {
  var liveEventsClosed = false;

  @override
  Future<GameClientState> build(String saveId) async => GameClientState();

  @override
  Future<void> closeLiveEvents() async {
    liveEventsClosed = true;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an abandoned live match closes and returns to multiplayer', (
    tester,
  ) async {
    final gameState = _RecordingGameStateNotifier();
    final container = ProviderContainer(
      overrides: [gameStateProvider(_matchId).overrideWith(() => gameState)],
    );
    addTearDown(container.dispose);
    container
        .read(networkSessionStateProvider.notifier)
        .set(
          NetworkSession(
            userId: 'user_1',
            playerId: 'player_1',
            token: AuthToken('jwt-token'),
            refreshToken: 'refresh-token',
            matchId: _matchId,
            connectionState: NetworkConnectionState.offline,
          ),
        );
    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/game',
          builder: (context, state) => const Scaffold(
            body: GameAbandonedMatchBoundary(
              selection: _selection,
              saveId: _matchId,
              child: SizedBox(key: Key('running-game')),
            ),
          ),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) =>
              const SizedBox(key: Key('multiplayer-lobby-screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    container.read(multiplayerMatchProvider.notifier).upsert(_abandonedMatch());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(gameState.liveEventsClosed, isTrue);
    expect(container.read(networkSessionProvider)?.matchId, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('network.session.matchId'), isNull);
    expect(find.text('This match is no longer available.'), findsOneWidget);
    expect(find.byKey(const Key('multiplayer-lobby-screen')), findsOneWidget);
  });
}

WireMatch _abandonedMatch() => WireMatch(
  id: _matchId,
  ownerUserId: 'user_1',
  name: 'Abandoned game',
  mapName: _selection.name,
  players: const [],
  turn: 1,
  state: 'abandoned',
  createdAt: DateTime.utc(2026, 8, 8),
  endedAt: DateTime.utc(2026, 8, 8, 12),
);
