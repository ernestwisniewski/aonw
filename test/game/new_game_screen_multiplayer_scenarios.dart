part of 'new_game_screen_test.dart';

void _registerNewGameScreenMultiplayerScenarios() {
  testWidgets('multiplayer direct route opens lobby with a random map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    final visitedLobbyUris = <Uri>[];
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) => const NewGameScreen(
            flow: NewGameFlow.multiplayer,
            startAtMap: true,
          ),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) {
            visitedLobbyUris.add(state.uri);
            return const SizedBox(key: Key('lobby-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNull);
    expect(find.byKey(const Key('lobby-screen')), findsOneWidget);
    expect(visitedLobbyUris.single.queryParameters['mode'], 'multiplayer');
    expect(visitedLobbyUris.single.queryParameters['name'], 'verdantia');
    expect(visitedLobbyUris.single.queryParameters['source'], 'asset');
    expect(
      PlayerCountry.values.map((country) => country.name),
      contains(visitedLobbyUris.single.queryParameters['country']),
    );
  });

  testWidgets('update-required status blocks direct multiplayer entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) => const NewGameScreen(
            flow: NewGameFlow.multiplayer,
            startAtMap: true,
          ),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) => const SizedBox(key: Key('lobby-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
          mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
          mainMenuUpdateNoticeProvider.overrideWith(
            (_) async => const MainMenuUpdateNotice(),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lobby-screen')), findsNothing);
    expect(find.byKey(const Key('newGame.plan')), findsOneWidget);
    expect(find.textContaining('A newer version is ready'), findsOneWidget);
  });

  testWidgets('multiplayer continue skips map choice and opens lobby', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeGameRepository();
    final visitedLobbyUris = <Uri>[];
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final router = GoRouter(
      initialLocation: '/new-game',
      routes: [
        GoRoute(
          path: '/new-game',
          builder: (context, state) =>
              const NewGameScreen(flow: NewGameFlow.multiplayer),
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) {
            visitedLobbyUris.add(state.uri);
            return const SizedBox(key: Key('lobby-screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          availableMapsProvider.overrideWithValue(const AsyncData([selection])),
          activeMapProvider(selection).overrideWithValue(AsyncData(_map())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GO TO LOBBY'), findsOneWidget);
    expect(find.text('Choose the world'), findsNothing);

    await tester.tap(find.byKey(const Key('newGame.multiplayerLobbyAction')));
    await tester.pumpAndSettle();

    expect(repository.createdRequest, isNull);
    expect(find.byKey(const Key('lobby-screen')), findsOneWidget);
    expect(visitedLobbyUris.single.queryParameters['mode'], 'multiplayer');
    expect(visitedLobbyUris.single.queryParameters['name'], 'verdantia');
    expect(
      PlayerCountry.values.map((country) => country.name),
      contains(visitedLobbyUris.single.queryParameters['country']),
    );
  });
}
