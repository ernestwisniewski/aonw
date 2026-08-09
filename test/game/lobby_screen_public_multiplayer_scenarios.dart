part of 'lobby_screen_test.dart';

void _registerLobbyScreenPublicMultiplayerScenarios() {
  testWidgets('browses and refreshes public multiplayer matches', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    final client = _FakeNetworkSessionClient()
      ..publicMatches = [
        WireMatch(
          id: 'public_match_1',
          ownerUserId: 'owner_user',
          name: 'Open table',
          mapName: 'verdantia',
          players: const [
            WirePlayer(
              id: 'owner_player',
              userId: 'owner_user',
              name: 'Host',
              colorValue: 0xFFDC2626,
              country: PlayerCountry.france,
              kind: WirePlayerKind.human,
              connectionState: WirePlayerConnectionState.connected,
            ),
          ],
          maxPlayers: 4,
          minPlayers: 2,
          quickplay: false,
          turn: 0,
          state: 'open',
          createdAt: DateTime.utc(2026, 7, 11, 12),
        ),
      ];
    final store = _FakeNetworkSessionStore(
      const StoredNetworkSession(
        userId: 'user_1',
        refreshToken: 'refresh-token',
        displayName: 'Alice',
      ),
    );
    await _pumpLobby(
      tester,
      repository,
      flow: NewGameFlow.multiplayer,
      overrides: [
        networkSessionClientProvider.overrideWithValue(client),
        networkSessionStoreProvider.overrideWithValue(store),
      ],
    );

    await tester.pumpAndSettle();
    final browseAction = find.byKey(
      const Key('multiplayer.browsePublicAction'),
    );
    await tester.ensureVisible(browseAction);
    await tester.pumpAndSettle();
    await tester.tap(browseAction);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('multiplayer.publicBrowserPanel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('multiplayer.publicMatch.public_match_1')),
      findsOneWidget,
    );
    expect(find.text('Open table'), findsOneWidget);
    expect(client.listMatchesCalls, 1);

    client.publicMatches = const [];
    final refreshAction = find.byKey(
      const Key('multiplayer.publicRefreshAction'),
    );
    await tester.ensureVisible(refreshAction);
    await tester.pumpAndSettle();
    await tester.tap(refreshAction);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('multiplayer.publicEmpty')), findsOneWidget);
    expect(client.listMatchesCalls, 2);
  });

  for (final code in const [
    'unsupported_multiplayer_version',
    'unsupported_match_protocol',
  ]) {
    testWidgets('$code uses the localized update-required message', (
      tester,
    ) async {
      final repository = _FakeGameRepository();
      final client = _FakeNetworkSessionClient()
        ..listMatchesError = MultiplayerFailure.multiplayer(
          code: code,
          message: 'Raw server compatibility message',
        );
      final store = _FakeNetworkSessionStore(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-token',
          displayName: 'Alice',
        ),
      );
      await _pumpLobby(
        tester,
        repository,
        flow: NewGameFlow.multiplayer,
        overrides: [
          networkSessionClientProvider.overrideWithValue(client),
          networkSessionStoreProvider.overrideWithValue(store),
        ],
      );
      await tester.pumpAndSettle();

      final browseAction = find.byKey(
        const Key('multiplayer.browsePublicAction'),
      );
      await tester.ensureVisible(browseAction);
      await tester.pumpAndSettle();
      await tester.tap(browseAction);
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LobbyScreen)),
      );
      final queueError = find.byKey(const Key('multiplayer.queueError'));
      expect(queueError, findsOneWidget);
      expect(tester.widget<Text>(queueError).data, l10n.mainMenuUpdateSoonBody);
      expect(find.text('Raw server compatibility message'), findsNothing);
    });
  }
}
