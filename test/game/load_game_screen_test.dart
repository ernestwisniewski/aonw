import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/game/load_game_screen.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows empty state when there are no saves', (tester) async {
    await _pumpLoadGameScreen(tester, const _FakeGameRepository());

    expect(find.text('Saved games'), findsOneWidget);
    expect(find.text('No game has been started yet.'), findsOneWidget);
    expect(find.text('Saves: 0'), findsOneWidget);
    expect(find.text('No saved games.'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
  });

  testWidgets('renders save cards from gameSavesIndexProvider', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          GameSaveIndex(
            id: 'save_1',
            name: 'Campaign',
            mapName: 'verdantia',
            mapSource: MapSource.asset,
            turn: 3,
            savedAt: DateTime(2026, 4, 25, 9),
            replayAvailable: true,
          ),
        ],
      ),
    );

    expect(
      find.text('Return to recent matches and continue from the saved turn.'),
      findsOneWidget,
    );
    expect(find.text('Saves: 1'), findsOneWidget);
    expect(find.text('Campaign'), findsOneWidget);
    expect(find.text('VERDANTIA · TURN 3'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(find.text('REPLAY'), findsOneWidget);
  });

  testWidgets('opens replay route for playable saves', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          GameSaveIndex(
            id: 'save_1',
            name: 'Campaign',
            mapName: 'verdantia',
            mapSource: MapSource.asset,
            turn: 3,
            savedAt: DateTime(2026, 4, 25, 9),
            replayAvailable: true,
          ),
        ],
      ),
    );

    await tester.tap(find.text('REPLAY'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('replay-screen')), findsOneWidget);
  });

  testWidgets('marks corrupted saves as unavailable', (tester) async {
    await _pumpLoadGameScreen(
      tester,
      _FakeGameRepository(
        saves: [
          GameSaveIndex(
            id: 'broken_save',
            name: 'Broken save',
            mapName: '',
            turn: 0,
            savedAt: DateTime(2026, 4, 25, 9),
            corrupted: true,
            corruptionMessage: 'Unsupported save schema version',
          ),
        ],
      ),
    );

    expect(find.text('Broken save'), findsOneWidget);
    expect(find.text('Corrupted save'), findsOneWidget);
    expect(find.textContaining('cannot be read'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);

    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-screen')), findsNothing);
  });
}

Future<void> _pumpLoadGameScreen(
  WidgetTester tester,
  _FakeGameRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/load',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox(key: Key('home-screen')),
      ),
      GoRoute(
        path: '/load',
        builder: (context, state) => const LoadGameScreen(),
      ),
      GoRoute(
        path: '/new-game',
        builder: (context, state) => const SizedBox(key: Key('new-game')),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const SizedBox(key: Key('game-screen')),
      ),
      GoRoute(
        path: '/replay',
        builder: (context, state) => const SizedBox(key: Key('replay-screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repository),
        gameClockProvider.overrideWithValue(
          _FixedClock(DateTime(2026, 4, 25, 12)),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeGameRepository implements GameRepository {
  final List<GameSaveIndex> saves;

  const _FakeGameRepository({this.saves = const []});

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => 'save_1';

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => saves;

  @override
  Future<SaveSnapshot> load(String saveId) async => throw UnimplementedError();

  @override
  Future<void> save(SaveSnapshot snapshot) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}
