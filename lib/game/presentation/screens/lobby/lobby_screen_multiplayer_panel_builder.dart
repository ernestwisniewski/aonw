part of 'lobby_screen.dart';

extension _LobbyScreenMultiplayerPanelBuilder on _LobbyScreenState {
  Widget _buildMultiplayerPanel() {
    return switch (_connection.mode) {
      LobbyMultiplayerMode.home => _MultiplayerHomePanel(
        busy: _connection.busy,
        error: _connection.error,
        onQuickplay: ref.withMenuClickAsync(_connection.startQuickplayQueue),
        onBrowsePublic: ref.withMenuClickAsync(_connection.openPublicLobby),
        onCreatePrivate: ref.withMenuClickAsync(_connection.createPrivateMatch),
        onJoinPrivate: ref.withMenuClick(_connection.openJoinPrivateMatch),
      ),
      LobbyMultiplayerMode.quickplay => _MultiplayerQueuePanel(
        busy: _connection.busy,
        error: _connection.error,
        match: _connection.activeMatch,
        currentUserId: ref.watch(networkSessionProvider)?.userId,
        nowUtc: ref.watch(gameClockProvider).nowUtc(),
      ),
      LobbyMultiplayerMode.publicBrowse => _PublicLobbyBrowserPanel(
        busy: _connection.busy,
        error: _connection.error,
        matches: _connection.publicMatches,
        loaded: _connection.publicMatchesLoaded,
        nameController: _nameController,
        onRefresh: ref.withMenuClickAsync(_connection.refreshPublicMatches),
        onCreate: ref.withMenuClickAsync(_createPublicMatch),
        onJoin: ref.withMenuClickValueAsync(
          (match) => _connection.joinPublicMatch(matchId: match.id),
        ),
        onBack: ref.withMenuClick(_connection.returnHome),
      ),
      LobbyMultiplayerMode.publicMatch => _PublicMatchPanel(
        busy: _connection.busy,
        error: _connection.error,
        match: _connection.activeMatch,
        currentUserId: ref.watch(networkSessionProvider)?.userId,
        onBack: ref.withMenuClickAsync(_connection.back),
      ),
      LobbyMultiplayerMode.privateHost ||
      LobbyMultiplayerMode.privateJoin => _PrivateMatchPanel(
        busy: _connection.busy,
        error: _connection.error,
        match: _connection.activeMatch,
        currentUserId: ref.watch(networkSessionProvider)?.userId,
        inviteCodeController: _inviteCodeController,
        joining:
            _connection.mode == LobbyMultiplayerMode.privateJoin &&
            _connection.activeMatch == null,
        onShare: ref.withMenuClickAsync(_shareInviteCode),
        onCopy: ref.withMenuClickAsync(_copyInviteCode),
        onBack: ref.withMenuClickAsync(_connection.back),
      ),
    };
  }

  Widget _buildMultiplayerProfilePanel() {
    return _MultiplayerProfilePanel(
      nicknameController: _players.nameControllerAt(0),
      countryControl: _playerCountryControl(
        0,
        key: const Key('multiplayer.countryDropdown'),
      ),
      onNicknameChanged: (_) => _handleConnectionChanged(),
      signedIn: ref.watch(networkSessionProvider) != null,
      onSignOut: ref.withMenuClickAsync(_signOutMultiplayerAccount),
    );
  }
}
