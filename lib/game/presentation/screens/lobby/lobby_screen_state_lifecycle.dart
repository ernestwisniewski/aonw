part of 'lobby_screen.dart';

extension _LobbyScreenStateLifecycle on _LobbyScreenState {
  void _initializeLobbyState() {
    final random = math.Random();
    _multiplayerDefaultPlayerName = _randomMultiplayerPlayerName(random);
    final initialCountry =
        widget.playerCountry ?? randomInitialPlayerCountry(random: random);
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );
    _nameController = TextEditingController(
      text: CreateLocalGameUseCase(
        repository: ref.read(gameRepositoryProvider),
        clock: ref.read(gameClockProvider),
      ).defaultNameFor(selection),
    );
    _inviteCodeController = TextEditingController();
    _players = LobbyPlayerSetupController(
      flow: widget.flow,
      primaryCountry: initialCountry,
      maximumPlayers: MapPlayerCapacityRules.maxPlayersForMapName(
        widget.mapName,
      ),
    );
    if (_isNetworkLobby) {
      unawaited(_loadStoredMultiplayerDisplayName());
    }
    _connection = _createLobbyConnection()
      ..addListener(_handleConnectionChanged);
  }

  LobbyConnectionController _createLobbyConnection() {
    return LobbyConnectionController(
      mapName: widget.mapName,
      mapSource: widget.mapSource,
      sessionClient: ref.read(networkSessionClientProvider),
      sessionStore: ref.read(networkSessionStoreProvider),
      sessionEffectRunner: ref.read(networkSessionEffectRunnerProvider),
      liveEvents: ref.read(liveMultiplayerEventsProvider),
      now: _nowUtc,
      canContinue: _isMounted,
      currentSession: _currentNetworkSession,
      ensureValidSession: _ensureValidNetworkSession,
      activateAuthenticatedSession: ref.read(
        lobbyAuthenticatedSessionActivatorProvider,
      ),
      terminateSession: _terminateNetworkSession,
      signOutSession: _signOutNetworkSession,
      setSession: _setNetworkSession,
      authenticate: _authenticateNetworkSession,
      displayName: _multiplayerDisplayName,
      setPrimaryDisplayName: _setPrimaryDisplayName,
      country: _primaryCountry,
      validateMap: _validateSelectedMultiplayerMap,
      mapNotReadyMessage: _mapNotReadyMessage,
      inviteCodeRequiredMessage: _inviteCodeRequiredMessage,
      errorTextFor: _networkErrorText,
      presentError: _presentNetworkError,
      reportSessionEffectError: lobbySessionEffectErrorReporter(
        ref.read(gameLoggerProvider),
      ),
      publishMatch: _publishMatch,
      invalidatePublishedMatch: _invalidatePublishedMatch,
      presentLobbyUnavailable: _presentLobbyUnavailable,
      reportTransportStatus: _reportTransportStatus,
      navigateTo: _navigateTo,
    );
  }

  DateTime _nowUtc() => ref.read(gameClockProvider).nowUtc();

  bool _isMounted() => mounted;

  NetworkSession? _currentNetworkSession() => ref.read(networkSessionProvider);

  Future<NetworkSession> _ensureValidNetworkSession() {
    return ref
        .read(networkSessionRefreshCoordinatorProvider)
        .ensureValidSession();
  }

  Future<void> _terminateNetworkSession() {
    return ref
        .read(networkSessionRefreshCoordinatorProvider)
        .terminateSession();
  }

  void _setNetworkSession(NetworkSession? session) {
    ref.read(networkSessionStateProvider.notifier).set(session);
  }

  void _setPrimaryDisplayName(String displayName) {
    if (!mounted) return;
    _players.nameControllerAt(0).text = displayName;
  }

  PlayerCountry _primaryCountry() => _players.countryAt(0);

  String _mapNotReadyMessage() => context.l10n.multiplayerMapNotReady;

  String _inviteCodeRequiredMessage() {
    return context.l10n.multiplayerInviteCodeRequired;
  }

  void _presentNetworkError(String message) {
    if (!mounted) return;
    GameToast.show(context, message: message, tone: GameToastTone.error);
  }

  void _publishMatch(WireMatch match) {
    ref.read(multiplayerMatchProvider.notifier).upsert(match);
  }

  void _invalidatePublishedMatch(String matchId) {
    ref.read(multiplayerMatchProvider.notifier).clear(matchId);
  }

  void _presentLobbyUnavailable() {
    if (!mounted) return;
    GameToast.show(
      context,
      message: context.l10n.multiplayerMatchUnavailable,
      tone: GameToastTone.error,
    );
  }

  void _reportTransportStatus({
    required String matchId,
    required NetworkConnectionStatus status,
    String? message,
  }) {
    if (!mounted) return;
    ref
        .read(networkSessionStateProvider.notifier)
        .reportTransportStatus(
          saveId: matchId,
          status: status,
          message: message,
          changedAt: _nowUtc(),
        );
  }

  void _navigateTo(String location) => context.go(location);

  void _applyLocalizedDefaults() {
    if (_localizedDefaultsApplied) return;
    _players.applyLocalizedDefaults(_defaultPlayerName);
    _localizedDefaultsApplied = true;
  }

  void _disposeLobbyState() {
    _connection
      ..removeListener(_handleConnectionChanged)
      ..dispose();
    _nameController.dispose();
    _inviteCodeController.dispose();
    _players.dispose();
  }

  void _handleConnectionChanged() {
    if (mounted) _refreshState();
  }
}
