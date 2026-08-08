part of 'lobby_screen.dart';

typedef _LobbyMapView = ({
  MapSelection selection,
  MapValidationResult? validation,
  Object? error,
  bool loading,
  bool hasErrors,
});

extension _LobbyScreenStateView on _LobbyScreenState {
  Widget _buildLobbyScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mapView = _resolveLobbyMapView();
    final lobbyPlayerCount = _isNetworkLobby
        ? _connection.connectedHumanPlayerCount()
        : _players.playerCount;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: GameUiTheme.bg,
        appBar: GameUiAppBar(
          title: GameText.screenTitle(widget.flow.menuLabel(l10n)),
          onClose: ref.withMenuBackAsync(_handleBack),
        ),
        bottomNavigationBar: _buildLobbyActionBar(
          selection: mapView.selection,
          hasMapValidationErrors: mapView.hasErrors,
          l10n: l10n,
        ),
        body: _buildLobbyBody(
          l10n: l10n,
          mapView: mapView,
          lobbyPlayerCount: lobbyPlayerCount,
        ),
      ),
    );
  }

  _LobbyMapView _resolveLobbyMapView() {
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );
    final mapAsync = ref.watch(activeMapProvider(selection));
    final MapValidationResult? validation;
    switch (mapAsync) {
      case AsyncData(:final value):
        _scheduleMapPlayerCapacitySync(value);
        validation = _validateMapSetup(value);
      default:
        validation = null;
    }
    final error = switch (mapAsync) {
      AsyncError(:final error) => error,
      _ => null,
    };
    final loading = switch (mapAsync) {
      AsyncLoading() => true,
      _ => false,
    };
    return (
      selection: selection,
      validation: validation,
      error: error,
      loading: loading,
      hasErrors: error != null || (validation?.errors.isNotEmpty ?? false),
    );
  }

  Widget _buildLobbyBody({
    required AppLocalizations l10n,
    required _LobbyMapView mapView,
    required int lobbyPlayerCount,
  }) {
    return MenuRouteBackdrop(
      maxContentWidth: 980,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          widget.flow.startsLocally ? 18 : 32,
        ),
        children: _buildLobbyContent(
          l10n: l10n,
          mapView: mapView,
          lobbyPlayerCount: lobbyPlayerCount,
        ),
      ),
    );
  }

  List<Widget> _buildLobbyContent({
    required AppLocalizations l10n,
    required _LobbyMapView mapView,
    required int lobbyPlayerCount,
  }) {
    return [
      _LobbyContentInset(
        child: GameUiScreenHeader(
          icon: widget.flow.icon,
          title: _lobbyHeaderTitle(l10n),
          subtitle: _lobbyHeaderSubtitle(l10n),
          meta: [
            MenuMetricPill(
              icon: widget.flow.icon,
              label: widget.flow.summaryLabel(l10n),
            ),
            MenuMetricPill(
              icon: Icons.person_outline,
              label: _isNetworkLobby
                  ? _networkPlayersSummary(l10n)
                  : '$lobbyPlayerCount',
            ),
          ],
        ),
      ),
      _LobbyContentInset(
        child: _LobbyStepRail(
          flow: widget.flow,
          multiplayerMode: _connection.mode,
          activeMatch: _connection.activeMatch,
        ),
      ),
      const SizedBox(height: 14),
      if (_isNetworkLobby) ...[
        if (_connection.showProfile) ...[
          _LobbyContentInset(child: _buildMultiplayerProfilePanel()),
          const SizedBox(height: 14),
        ],
        _LobbyContentInset(child: _buildMultiplayerPanel()),
      ] else
        _LobbyContentInset(
          child: _buildLocalSetup(
            l10n: l10n,
            mapValidation: mapView.validation,
            mapValidationLoading: mapView.loading,
            mapValidationError: mapView.error,
          ),
        ),
    ];
  }

  Future<void> _handleBack() async {
    if (!_isNetworkLobby) {
      context.go('/new-game?mode=${widget.flow.queryValue}');
      return;
    }
    if (_connection.mode == LobbyMultiplayerMode.quickplay) {
      await _connection.cancelQuickplayQueue();
      return;
    }
    if (_connection.mode != LobbyMultiplayerMode.home) {
      await _connection.back();
      return;
    }
    context.go('/');
  }

  String _lobbyHeaderTitle(AppLocalizations l10n) {
    if (_isNetworkLobby) return l10n.multiplayerLobbyHeaderTitle;
    return l10n.lobbyHeaderTitle;
  }

  String _lobbyHeaderSubtitle(AppLocalizations l10n) {
    if (_isNetworkLobby) return l10n.multiplayerLobbyHeaderSubtitle;
    return l10n.lobbyHeaderSubtitle;
  }

  String _networkPlayersSummary(AppLocalizations l10n) {
    final match = _connection.activeMatch;
    if (match == null) return l10n.matchPlayersCount(0, 4);
    return l10n.matchPlayersCount(
      LobbyMatchStatusRules.connectedHumanCount(match),
      match.maxPlayers,
    );
  }

  Widget _buildLocalSetup({
    required AppLocalizations l10n,
    required MapValidationResult? mapValidation,
    required bool mapValidationLoading,
    required Object? mapValidationError,
  }) {
    return _LobbyLocalSetupPanel(
      l10n: l10n,
      primaryCountryControl: _playerCountryControl(
        0,
        key: const Key('lobby.primaryCountryDropdown'),
      ),
      primaryLeaderName: GameDisplayNames.playerCountryLeader(
        l10n,
        _players.countryAt(0),
      ),
      selectedMapName: MapSelection(
        name: widget.mapName,
        source: widget.mapSource,
      ).displayName,
      nameController: _nameController,
      onNameChanged: (_) => _refreshState(),
      gameLengthPreset: _gameLengthPreset,
      onGameLengthPresetChanged: ref.withMenuClickValue(
        (preset) => _mutateState(() => _gameLengthPreset = preset),
      ),
      mapValidation: mapValidation,
      mapValidationLoading: mapValidationLoading,
      mapValidationError: mapValidationError,
      playerCount: _players.playerCount,
      maximumPlayers: _players.maximumPlayers,
      canAddPlayers: _canAddPlayers,
      playerRowBuilder: _buildPlayerRow,
      onAddPlayer: ref.withMenuClick(_addPlayer),
    );
  }

  Widget? _buildLobbyActionBar({
    required MapSelection selection,
    required bool hasMapValidationErrors,
    required AppLocalizations l10n,
  }) {
    return _LobbyActionBarBuilder(
      l10n: l10n,
      selection: selection,
      flow: widget.flow,
      localPlayerCount: _players.playerCount,
      canStartLocalGame: _canStart,
      starting: _starting,
      hasMapValidationErrors: hasMapValidationErrors,
      multiplayerMode: _connection.mode,
      networkBusy: _connection.busy,
      activeMatch: _connection.activeMatch,
      currentUserId: ref.watch(networkSessionProvider)?.userId,
      onStartLocalGame: ref.withMenuClickAsync(_start),
      onRetryQuickplay: ref.withMenuClickAsync(_connection.retryQuickplayQueue),
      onCancelQuickplay: ref.withMenuClickAsync(
        _connection.cancelQuickplayQueue,
      ),
      onJoinPrivateMatch: ref.withMenuClickAsync(_joinPrivateMatch),
      onStartPrivateMatch: ref.withMenuClickAsync(
        _connection.startPrivateMatch,
      ),
      onStartPublicMatch: ref.withMenuClickAsync(_connection.startPublicMatch),
      onBackToMultiplayerHome: ref.withMenuClickAsync(_connection.back),
    ).build();
  }

  Widget _buildPlayerRow(int index) {
    final canRemove =
        _canAddPlayers &&
        index > 0 &&
        _players.playerCount > LobbyPlayerSetupController.minimumPlayers;
    final countryControl = index == 0
        ? _PlayerCountryBadge(country: _players.countryAt(index))
        : _playerCountryControl(index);
    return _LobbyPlayerRow(
      index: index,
      nameController: _players.nameControllerAt(index),
      nameHint: _players.defaultNameFor(index, _defaultPlayerName),
      countryControl: countryControl,
      kindControl: _playerKindControl(index),
      showKindControl: index > 0,
      canRemove: canRemove,
      onNameChanged: (_) => _refreshState(),
      onRemove: canRemove
          ? ref.withMenuClick(() => _removePlayer(index))
          : null,
    );
  }

  Widget _playerKindControl(int index) {
    if (_canEditPlayerKinds) {
      return _PlayerKindToggle(
        value: _players.kindAt(index),
        onChanged: ref.withMenuClickValue(
          (kind) => _setPlayerKind(index, kind),
        ),
      );
    }
    return _PlayerKindBadge(value: _players.kindAt(index));
  }

  Widget _playerCountryControl(int index, {Key? key}) {
    return _PlayerCountryDropdown(
      key: key,
      value: _players.countryAt(index),
      options: _players.countryOptionsFor(index),
      onChanged: ref.withMenuClickValue(
        (country) => _setPlayerCountry(index, country),
      ),
    );
  }
}
