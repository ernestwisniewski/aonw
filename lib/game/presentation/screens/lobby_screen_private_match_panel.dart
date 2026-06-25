part of 'lobby_screen.dart';

class _PrivateMatchPanel extends StatelessWidget {
  final bool busy;
  final String? error;
  final WireMatch? match;
  final String? currentUserId;
  final TextEditingController inviteCodeController;
  final bool joining;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onBack;

  const _PrivateMatchPanel({
    required this.busy,
    required this.error,
    required this.match,
    required this.currentUserId,
    required this.inviteCodeController,
    required this.joining,
    required this.onShare,
    required this.onCopy,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final match = this.match;
    final humanPlayerCount = LobbyMatchStatusRules.humanPlayerCount(match);
    final minPlayers = LobbyMatchStatusRules.requiredHumanPlayers(match);
    final waitingForPlayers = match != null && humanPlayerCount < minPlayers;
    final isHost = LobbyMatchStatusRules.isOwner(match, currentUserId);
    final statusText = match == null
        ? null
        : waitingForPlayers
        ? l10n.multiplayerQueueWaitingForPlayers(minPlayers)
        : isHost
        ? l10n.multiplayerPrivateHostReady
        : l10n.multiplayerPrivateWaitingForHost;
    return DecoratedBox(
      key: const Key('multiplayer.privatePanel'),
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
                    GameText.sectionLabel(l10n.multiplayerPrivateTitle),
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
            if (joining && match == null) ...[
              const SizedBox(height: 8),
              Text(l10n.multiplayerJoinCodeHelp, style: GameUiTheme.bodySmall),
              const SizedBox(height: 12),
              TextField(
                key: const Key('multiplayer.inviteCodeInput'),
                controller: inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                style: GameUiTheme.inputText,
                decoration: GameUiTheme.textFieldDecoration(
                  hintText: l10n.multiplayerInviteCodeHint,
                ),
              ),
              const SizedBox(height: 12),
            ] else if (match != null) ...[
              if (match.inviteCode case final code?) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.multiplayerInviteCodeLabel,
                  style: GameUiTheme.cardMeta,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  code,
                  key: const Key('multiplayer.inviteCode'),
                  textAlign: TextAlign.center,
                  style: GameUiTheme.screenTitle.copyWith(
                    color: GameUiTheme.goldLight,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : onCopy,
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(GameText.actionLabel(l10n.copyAction)),
                      style: GameUiTheme.outlinedButtonStyle(
                        foreground: GameUiTheme.textSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: busy ? null : onShare,
                      icon: const Icon(Icons.ios_share, size: 16),
                      label: Text(GameText.actionLabel(l10n.shareAction)),
                      style: GameUiTheme.primaryButtonStyle(),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _MultiplayerReadinessSummary(
                key: const Key('multiplayer.privatePlayers'),
                players: humanPlayerCount,
                minPlayers: minPlayers,
                maxPlayers: match.maxPlayers,
                waiting: waitingForPlayers,
              ),
              const SizedBox(height: 10),
              if (statusText != null) ...[
                _MultiplayerLobbyStatusCallout(
                  waiting: waitingForPlayers,
                  text: statusText,
                ),
                const SizedBox(height: 10),
              ],
              _LobbyPlayerList(
                key: const Key('multiplayer.privatePlayersList'),
                players: match.players,
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
