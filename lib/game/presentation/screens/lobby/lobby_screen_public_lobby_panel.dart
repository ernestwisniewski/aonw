part of 'lobby_screen.dart';

class _PublicLobbyBrowserPanel extends StatelessWidget {
  const _PublicLobbyBrowserPanel({
    required this.busy,
    required this.error,
    required this.matches,
    required this.loaded,
    required this.nameController,
    required this.onRefresh,
    required this.onCreate,
    required this.onJoin,
    required this.onBack,
  });

  final bool busy;
  final String? error;
  final List<WireMatch> matches;
  final bool loaded;
  final TextEditingController nameController;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<WireMatch> onJoin;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      key: const Key('multiplayer.publicBrowserPanel'),
      decoration: BoxDecoration(
        color: GameUiTheme.surface,
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    GameText.sectionLabel(l10n.multiplayerPublicLobbyTitle),
                    style: GameUiTheme.bodyStrong,
                  ),
                ),
                IconButton(
                  key: const Key('multiplayer.publicRefreshAction'),
                  onPressed: busy ? null : onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: GameUiTheme.textSecondary,
                  tooltip: l10n.refreshAction,
                ),
                IconButton(
                  onPressed: busy ? null : onBack,
                  icon: const Icon(Icons.close, size: 18),
                  color: GameUiTheme.textSecondary,
                  tooltip: l10n.cancelAction,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.multiplayerPublicLobbySubtitle,
              style: GameUiTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('multiplayer.publicNameInput'),
              controller: nameController,
              enabled: !busy,
              maxLength: 80,
              style: GameUiTheme.inputText,
              decoration: GameUiTheme.textFieldDecoration(
                hintText: l10n.multiplayerPublicMatchNameLabel,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              key: const Key('multiplayer.publicCreateAction'),
              onPressed: busy ? null : onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                GameText.actionLabel(l10n.multiplayerPublicCreateAction),
              ),
              style: GameUiTheme.primaryButtonStyle(),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: GameUiTheme.border),
            const SizedBox(height: 14),
            if (error != null) ...[
              _MultiplayerErrorText(error: error!),
              const SizedBox(height: 12),
            ],
            if (!loaded && busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (loaded && matches.isEmpty)
              _PublicLobbyEmptyState(message: l10n.multiplayerPublicEmpty)
            else
              for (final match in matches) ...[
                _PublicLobbyMatchTile(
                  match: match,
                  busy: busy,
                  onJoin: () => onJoin(match),
                ),
                if (match != matches.last) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _PublicLobbyEmptyState extends StatelessWidget {
  const _PublicLobbyEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('multiplayer.publicEmpty'),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(
            Icons.groups_outlined,
            color: GameUiTheme.textTertiary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GameUiTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PublicLobbyMatchTile extends StatelessWidget {
  const _PublicLobbyMatchTile({
    required this.match,
    required this.busy,
    required this.onJoin,
  });

  final WireMatch match;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playerCount = LobbyMatchStatusRules.connectedHumanCount(match);
    final mapName = MapSelection(
      name: match.mapName,
      source: MapSource.asset,
    ).displayName;
    return DecoratedBox(
      key: Key('multiplayer.publicMatch.${match.id}'),
      decoration: BoxDecoration(
        color: GameUiTheme.surfaceDeep,
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.public_outlined,
              color: GameUiTheme.accentLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$mapName · ${l10n.matchPlayersCount(playerCount, match.maxPlayers)}',
                    style: GameUiTheme.cardMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              key: Key('multiplayer.publicJoin.${match.id}'),
              onPressed: busy ? null : onJoin,
              style: GameUiTheme.outlinedButtonStyle(
                foreground: GameUiTheme.goldLight,
              ),
              child: Text(GameText.actionLabel(l10n.joinMatchAction)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicMatchPanel extends StatelessWidget {
  const _PublicMatchPanel({
    required this.busy,
    required this.error,
    required this.match,
    required this.currentUserId,
    required this.onBack,
  });

  final bool busy;
  final String? error;
  final WireMatch? match;
  final String? currentUserId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final match = this.match;
    final connectedPlayers = LobbyMatchStatusRules.connectedHumanCount(match);
    final minPlayers = LobbyMatchStatusRules.requiredHumanPlayers(match);
    final waitingForPlayers = match != null && connectedPlayers < minPlayers;
    final isHost = LobbyMatchStatusRules.isOwner(match, currentUserId);
    final statusText = match == null
        ? l10n.multiplayerQueueConnectingSubtitle
        : waitingForPlayers
        ? l10n.multiplayerQueueWaitingForPlayers(minPlayers)
        : isHost
        ? l10n.multiplayerPublicHostReady
        : l10n.multiplayerPublicWaitingForHost;
    return DecoratedBox(
      key: const Key('multiplayer.publicMatchPanel'),
      decoration: BoxDecoration(
        color: GameUiTheme.surface,
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    GameText.sectionLabel(l10n.multiplayerPublicMatchTitle),
                    style: GameUiTheme.bodyStrong,
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : onBack,
                  icon: const Icon(Icons.close, size: 18),
                  color: GameUiTheme.textSecondary,
                  tooltip: l10n.cancelAction,
                ),
              ],
            ),
            if (match != null) ...[
              const SizedBox(height: 12),
              Text(match.name, style: GameUiTheme.cardTitle),
              const SizedBox(height: 14),
              _MultiplayerReadinessSummary(
                players: connectedPlayers,
                minPlayers: minPlayers,
                maxPlayers: match.maxPlayers,
                waiting: waitingForPlayers,
              ),
              const SizedBox(height: 10),
              _MultiplayerLobbyStatusCallout(
                waiting: waitingForPlayers,
                text: statusText,
              ),
              const SizedBox(height: 10),
              _LobbyPlayerList(
                key: const Key('multiplayer.publicPlayersList'),
                match: match,
                currentUserId: currentUserId,
                minPlayers: minPlayers,
                maxPlayers: match.maxPlayers,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 14),
              _MultiplayerErrorText(error: error!),
            ],
          ],
        ),
      ),
    );
  }
}
