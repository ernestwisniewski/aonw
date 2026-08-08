part of 'lobby_screen.dart';

extension _LobbyScreenStateActions on _LobbyScreenState {
  GameMode get _gameMode => widget.flow.gameMode;

  bool get _isNetworkLobby => widget.flow == NewGameFlow.multiplayer;

  bool get _canEditPlayerKinds => _players.canEditPlayerKinds;

  bool get _canAddPlayers => _players.canAddPlayers;

  bool get _canStart => _players.canStartLocalGame;

  GameLengthConfig get _selectedGameLength => _gameLengthPreset.config;

  MatchRules get _selectedMatchRules {
    return MatchRules.forGameLength(_selectedGameLength);
  }

  void _addPlayer() {
    if (_players.addPlayer(_defaultPlayerName)) _refreshState();
  }

  String _defaultPlayerName(int zeroBasedIndex, PlayerCountry country) {
    final index = zeroBasedIndex + 1;
    final l10n = AppLocalizations.of(context);
    if (widget.flow == NewGameFlow.multiplayer && zeroBasedIndex == 0) {
      return _multiplayerDefaultPlayerName;
    }
    if (widget.flow == NewGameFlow.singlePlayer) {
      return GameDisplayNames.playerCountryLeader(l10n, country);
    }
    return l10n.defaultPlayerName(index);
  }

  String _randomMultiplayerPlayerName(math.Random random) {
    return 'Player${1000 + random.nextInt(9000)}';
  }

  void _removePlayer(int index) {
    if (_players.removePlayer(index)) _refreshState();
  }

  void _setPlayerKind(int index, PlayerKind kind) {
    if (_players.setKind(index, kind)) _refreshState();
  }

  void _setPlayerCountry(int index, PlayerCountry country) {
    if (_players.setCountry(index, country, _defaultPlayerName)) {
      _refreshState();
    }
  }

  Future<void> _start() async {
    if (!_canStart || _starting) return;
    _mutateState(() => _starting = true);

    final gameName = _nameController.text.trim();
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );

    try {
      final mapData = await ref.read(activeMapProvider(selection).future);
      if (_applyMapPlayerCapacity(mapData) && mounted) _refreshState();
      final players = _players.buildPlayers(_defaultPlayerName);
      final validation = _validateMapSetup(mapData);
      if (validation.errors.isNotEmpty) return;
      final saveId =
          await CreateLocalGameUseCase(
            repository: ref.read(gameRepositoryProvider),
            clock: ref.read(gameClockProvider),
          ).execute(
            name: gameName,
            selection: selection,
            mapData: mapData,
            gameMode: _gameMode,
            matchRules: _selectedMatchRules,
            players: players,
          );
      if (!mounted) return;
      context.go(
        '/game?saveId=$saveId'
        '&name=${Uri.encodeComponent(widget.mapName)}'
        '&source=${widget.mapSource.name}',
      );
    } finally {
      if (mounted) _mutateState(() => _starting = false);
    }
  }

  Future<void> _signOutMultiplayerAccount() async {
    final revoked = await _connection.signOut();
    if (!mounted || !revoked) return;
    GameToast.show(
      context,
      message: context.l10n.multiplayerAccountSignedOut,
      tone: GameToastTone.success,
    );
  }

  Future<void> _joinPrivateMatch() async {
    await _connection.joinPrivateMatch(inviteCode: _inviteCodeController.text);
  }

  Future<void> _createPublicMatch() async {
    await _connection.createPublicMatch(name: _nameController.text);
  }

  Future<void> _shareInviteCode() async {
    final code = _connection.inviteCode;
    if (code == null || code.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(text: context.l10n.multiplayerInviteShareText(code)),
    );
  }

  Future<void> _copyInviteCode() async {
    final code = _connection.inviteCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    GameToast.show(
      context,
      message: context.l10n.multiplayerInviteCopied,
      tone: GameToastTone.success,
    );
  }

  String _multiplayerDisplayName() {
    final value = _players.nameControllerAt(0).text.trim();
    return value.isEmpty
        ? _players.defaultNameFor(0, _defaultPlayerName)
        : value;
  }

  Future<void> _loadStoredMultiplayerDisplayName() async {
    final displayName = await ref
        .read(networkSessionStoreProvider)
        .loadDisplayName();
    if (!mounted || !_isNetworkLobby) return;
    final normalized = displayName.trim();
    if (normalized.isEmpty || normalized == 'Player') return;
    final controller = _players.nameControllerAt(0);
    final current = controller.text.trim();
    if (current.isNotEmpty && current != _multiplayerDefaultPlayerName) {
      return;
    }
    controller.text = normalized;
    _refreshState();
  }

  String _networkErrorText(Object error) {
    return _LobbyNetworkErrorMessages(
      l10n: context.l10n,
      apiHost: ref.read(apiConfigProvider).baseUrl.host,
    ).textFor(error);
  }

  Future<MapValidationResult> _validateQuickplayMap() async {
    final selection = MapSelection(
      name: widget.mapName,
      source: widget.mapSource,
    );
    final mapData = await ref.read(activeMapProvider(selection).future);
    return MapValidator.validate(
      mapData: mapData,
      playerCount: 2,
      gameLength: GameLengthConfig.unlimited,
    );
  }

  MapValidationResult _validateMapSetup(WorldMap mapData) {
    return MapValidator.validate(
      mapData: mapData,
      playerCount: _players.playerCount,
      gameLength: _selectedGameLength,
    );
  }

  bool _applyMapPlayerCapacity(WorldMap mapData) {
    return _players.updateMaximumPlayers(
      MapPlayerCapacityRules.maxPlayersForWorldMap(mapData),
    );
  }

  void _refreshAfterMapCapacityChange() => _refreshState();
}
