part of 'lobby_screen.dart';

final class _LobbyActionBarBuilder {
  const _LobbyActionBarBuilder({
    required this.l10n,
    required this.selection,
    required this.flow,
    required this.localPlayerCount,
    required this.canStartLocalGame,
    required this.starting,
    required this.hasMapValidationErrors,
    required this.multiplayerMode,
    required this.networkBusy,
    required this.activeMatch,
    required this.currentUserId,
    required this.onStartLocalGame,
    required this.onRetryQuickplay,
    required this.onCancelQuickplay,
    required this.onJoinPrivateMatch,
    required this.onStartPrivateMatch,
    required this.onBackToMultiplayerHome,
  });

  final AppLocalizations l10n;
  final MapSelection selection;
  final NewGameFlow flow;
  final int localPlayerCount;
  final bool canStartLocalGame;
  final bool starting;
  final bool hasMapValidationErrors;
  final LobbyMultiplayerMode multiplayerMode;
  final bool networkBusy;
  final WireMatch? activeMatch;
  final String? currentUserId;
  final VoidCallback onStartLocalGame;
  final VoidCallback onRetryQuickplay;
  final VoidCallback onCancelQuickplay;
  final VoidCallback onJoinPrivateMatch;
  final VoidCallback onStartPrivateMatch;
  final VoidCallback onBackToMultiplayerHome;

  Widget? build() {
    if (flow.startsLocally) return _localGameActionBar();
    return switch (multiplayerMode) {
      LobbyMultiplayerMode.home => null,
      LobbyMultiplayerMode.quickplay => _quickplayActionBar(),
      LobbyMultiplayerMode.privateJoin when activeMatch == null =>
        _privateJoinActionBar(),
      LobbyMultiplayerMode.privateHost ||
      LobbyMultiplayerMode.privateJoin => _privateMatchActionBar(),
    };
  }

  Widget _localGameActionBar() {
    return MenuActionBar(
      summary: _LobbyStartSummary(
        mapName: selection.displayName,
        playerCount: localPlayerCount,
      ),
      primaryKey: const Key('lobby.startAction'),
      primaryLabel: GameText.actionLabel(l10n.startGameAction),
      primaryIcon: Icons.play_arrow_rounded,
      primaryBusy: starting,
      onPrimary: _canStartLocalGame ? onStartLocalGame : null,
    );
  }

  Widget _quickplayActionBar() {
    return MenuActionBar(
      summary: _MultiplayerActionSummary(
        icon: Icons.groups_2_outlined,
        title: _queueActionTitle(),
        subtitle: _playersSubtitle(activeMatch),
      ),
      primaryKey: const Key('multiplayer.queueRefreshAction'),
      primaryLabel: GameText.actionLabel(l10n.refreshAction),
      primaryIcon: Icons.refresh_rounded,
      onPrimary: _enabledWhenIdle(onRetryQuickplay),
      secondaryKey: const Key('multiplayer.queueCancelAction'),
      secondaryLabel: GameText.actionLabel(l10n.cancelAction),
      secondaryIcon: Icons.close_rounded,
      onSecondary: _enabledWhenIdle(onCancelQuickplay),
    );
  }

  Widget _privateJoinActionBar() {
    return MenuActionBar(
      summary: _MultiplayerActionSummary(
        icon: Icons.key_outlined,
        title: l10n.multiplayerJoinPrivateTitle,
        subtitle: l10n.multiplayerJoinCodeHelp,
      ),
      primaryKey: const Key('multiplayer.privateJoinAction'),
      primaryLabel: GameText.actionLabel(l10n.joinMatchAction),
      primaryIcon: Icons.login_rounded,
      onPrimary: _enabledWhenIdle(onJoinPrivateMatch),
      secondaryLabel: GameText.actionLabel(l10n.backAction),
      secondaryIcon: Icons.arrow_back_rounded,
      onSecondary: _enabledWhenIdle(onBackToMultiplayerHome),
    );
  }

  Widget _privateMatchActionBar() {
    final isHost = LobbyMatchStatusRules.isOwner(activeMatch, currentUserId);
    return MenuActionBar(
      summary: _MultiplayerActionSummary(
        icon: isHost
            ? Icons.admin_panel_settings_outlined
            : Icons.group_outlined,
        title: _privateMatchTitle(isHost),
        subtitle: _playersSubtitle(activeMatch),
      ),
      primaryKey: const Key('multiplayer.privateStartAction'),
      primaryLabel: isHost ? GameText.actionLabel(l10n.startGameAction) : null,
      primaryIcon: Icons.play_arrow_rounded,
      onPrimary: _canStartPrivateMatch ? onStartPrivateMatch : null,
      secondaryLabel: GameText.actionLabel(l10n.backAction),
      secondaryIcon: Icons.arrow_back_rounded,
      onSecondary: _enabledWhenIdle(onBackToMultiplayerHome),
    );
  }

  bool get _canStartLocalGame {
    return canStartLocalGame && !starting && !hasMapValidationErrors;
  }

  bool get _canStartPrivateMatch {
    return LobbyMatchStatusRules.canStartPrivateMatch(
      match: activeMatch,
      userId: currentUserId,
      busy: networkBusy,
    );
  }

  VoidCallback? _enabledWhenIdle(VoidCallback action) {
    return networkBusy ? null : action;
  }

  String _queueActionTitle() {
    final match = activeMatch;
    if (match == null) return l10n.multiplayerQueueSearchingTitle;
    if (LobbyMatchStatusRules.canEnter(match)) {
      return l10n.multiplayerQueueReadyTitle;
    }
    return _isWaitingForRequiredPlayers(match)
        ? l10n.multiplayerQueueSearchingTitle
        : l10n.multiplayerQueueCountdownTitle;
  }

  bool _isWaitingForRequiredPlayers(WireMatch match) {
    return LobbyMatchStatusRules.humanPlayerCount(match) <
        LobbyMatchStatusRules.requiredHumanPlayers(match);
  }

  String _privateMatchTitle(bool isHost) {
    return isHost
        ? l10n.multiplayerPrivateHostReady
        : l10n.multiplayerPrivateWaitingForHost;
  }

  String _playersSubtitle(WireMatch? match) {
    if (match == null) return l10n.multiplayerQueueConnectingSubtitle;
    return l10n.matchPlayersCount(
      LobbyMatchStatusRules.humanPlayerCount(match),
      match.maxPlayers,
    );
  }
}
