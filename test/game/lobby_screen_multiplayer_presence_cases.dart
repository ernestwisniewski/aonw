part of 'lobby_screen_test.dart';

void _registerLobbyScreenMultiplayerPresenceCases() {
  testWidgets('shows selected multiplayer country in quickplay lobby', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    final client = _FakeNetworkSessionClient();
    final store = _multiplayerSessionStore();
    await _pumpMultiplayerLobby(tester, repository, client, store);

    expect(find.byKey(const Key('game-length-dropdown')), findsNothing);
    final countryDropdown = find.byKey(
      const Key('multiplayer.countryDropdown'),
    );
    await tester.ensureVisible(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(countryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Russia').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('multiplayer.quickplayAction')));
    await tester.pumpAndSettle();

    expect(client.quickplayRequest?.country, PlayerCountry.russia);
    expect(find.byKey(const Key('multiplayer.queuePanel')), findsOneWidget);
    expect(find.textContaining('Russia'), findsOneWidget);
    expect(find.text('HOST'), findsNothing);
  });

  testWidgets('connection presence takes precedence over ready status', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    final client = _FakeNetworkSessionClient()
      ..quickplayConnectionState = WirePlayerConnectionState.offline
      ..quickplayReady = true;
    await _pumpMultiplayerLobby(
      tester,
      repository,
      client,
      _multiplayerSessionStore(),
      liveEvents: _NoopLiveEvents(),
    );
    await _enterQuickplay(tester);

    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('ready'), findsNothing);
    expect(find.text('HOST'), findsNothing);
  });

  testWidgets('system back leaves quickplay through the lobby handler', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    final client = _FakeNetworkSessionClient();
    await _pumpMultiplayerLobby(
      tester,
      repository,
      client,
      _multiplayerSessionStore(),
      liveEvents: _NoopLiveEvents(),
    );
    await _enterQuickplay(tester);
    expect(find.byKey(const Key('multiplayer.queuePanel')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(client.leftMatchIds, ['match_1']);
    expect(find.byKey(const Key('multiplayer.queuePanel')), findsNothing);
    expect(
      find.byKey(const Key('multiplayer.quickplayAction')),
      findsOneWidget,
    );
  });

  testWidgets('lobby live callbacks publish the shared transport status', (
    tester,
  ) async {
    final repository = _FakeGameRepository();
    final client = _FakeNetworkSessionClient();
    final live = _NoopLiveEvents();
    await _pumpMultiplayerLobby(
      tester,
      repository,
      client,
      _multiplayerSessionStore(),
      liveEvents: live,
    );
    await _enterQuickplay(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LobbyScreen)),
    );

    expect(container.read(networkSessionProvider)?.matchId, 'match_1');
    expect(
      container.read(multiplayerConnectionStatusProvider)?.status,
      NetworkConnectionStatus.connected,
    );
    live.emitReconnecting();
    await tester.pumpAndSettle();
    var status = container.read(multiplayerConnectionStatusProvider);
    expect(status?.saveId, 'match_1');
    expect(status?.status, NetworkConnectionStatus.reconnecting);
    expect(status?.message, 'Live event stream reconnecting');
    expect(container.read(networkSessionProvider)?.isConnected, isTrue);
    live.emitDone();
    await tester.pumpAndSettle();
    status = container.read(multiplayerConnectionStatusProvider);
    expect(status?.status, NetworkConnectionStatus.reconnecting);
    expect(status?.message, 'Live event stream closed');
    live.emitConnected();
    await tester.pumpAndSettle();
    status = container.read(multiplayerConnectionStatusProvider);
    expect(status?.status, NetworkConnectionStatus.connected);
    expect(status?.message, isNull);
  });
}

_FakeNetworkSessionStore _multiplayerSessionStore() {
  return _FakeNetworkSessionStore(
    const StoredNetworkSession(
      userId: 'user_1',
      refreshToken: 'refresh-token',
      displayName: 'Alice',
    ),
  );
}

Future<void> _pumpMultiplayerLobby(
  WidgetTester tester,
  _FakeGameRepository repository,
  _FakeNetworkSessionClient client,
  _FakeNetworkSessionStore store, {
  LiveMultiplayerEvents? liveEvents,
}) async {
  await _pumpLobby(
    tester,
    repository,
    flow: NewGameFlow.multiplayer,
    overrides: [
      networkSessionClientProvider.overrideWithValue(client),
      networkSessionStoreProvider.overrideWithValue(store),
      if (liveEvents != null)
        liveMultiplayerEventsProvider.overrideWithValue(liveEvents),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _enterQuickplay(WidgetTester tester) async {
  final action = find.byKey(const Key('multiplayer.quickplayAction'));
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

final class _NoopLiveEvents implements LiveMultiplayerEvents {
  void Function()? _onConnected;
  void Function()? _onReconnecting;
  void Function()? _onDone;

  @override
  Future<LiveMultiplayerEventHandle> subscribe({
    required String matchId,
    required AuthToken token,
    Future<AuthToken> Function()? tokenReader,
    required int fromOffset,
    int Function()? nextOffset,
    required void Function(LiveServerEvent event) onEvent,
    required void Function(CanonicalGameSnapshot snapshot) onSnapshotResync,
    void Function(WireMatch match)? onMatch,
    void Function()? onConnected,
    void Function()? onReconnecting,
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
  }) async {
    _onConnected = onConnected;
    _onReconnecting = onReconnecting;
    _onDone = onDone;
    onConnected?.call();
    return const _NoopLiveEventHandle();
  }

  void emitConnected() => _onConnected?.call();
  void emitReconnecting() => _onReconnecting?.call();
  void emitDone() => _onDone?.call();
}

final class _NoopLiveEventHandle implements LiveMultiplayerEventHandle {
  const _NoopLiveEventHandle();

  @override
  Future<void> close() async {}

  @override
  Future<WireCommandAck> sendCommand({
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    throw UnsupportedError('Lobby stream does not send commands.');
  }
}
