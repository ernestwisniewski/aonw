part of 'lobby_screen.dart';

class _MultiplayerActionSummary extends StatelessWidget {
  const _MultiplayerActionSummary({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: GameUiTheme.gold),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                GameText.actionLabel(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.cardMeta,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiplayerHomePanel extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onQuickplay;
  final VoidCallback onCreatePrivate;
  final VoidCallback onJoinPrivate;

  const _MultiplayerHomePanel({
    required this.busy,
    required this.error,
    required this.onQuickplay,
    required this.onCreatePrivate,
    required this.onJoinPrivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      key: const Key('multiplayer.homePanel'),
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
            Text(
              GameText.sectionLabel(l10n.multiplayerServerTitle),
              style: GameUiTheme.bodyStrong,
            ),
            const SizedBox(height: 8),
            Text(l10n.multiplayerHomeSubtitle, style: GameUiTheme.bodySmall),
            if (error != null) ...[
              const SizedBox(height: 12),
              _MultiplayerErrorText(error: error!),
            ],
            const SizedBox(height: 16),
            _MultiplayerActionTile(
              icon: Icons.flash_on_outlined,
              title: l10n.multiplayerQuickplayTitle,
              subtitle: l10n.multiplayerQuickplaySubtitle,
              buttonKey: const Key('multiplayer.quickplayAction'),
              primary: true,
              busy: busy,
              onPressed: onQuickplay,
            ),
            const SizedBox(height: 10),
            _MultiplayerActionTile(
              icon: Icons.ios_share_outlined,
              title: l10n.multiplayerCreatePrivateTitle,
              subtitle: l10n.multiplayerCreatePrivateSubtitle,
              buttonKey: const Key('multiplayer.createPrivateAction'),
              busy: busy,
              onPressed: onCreatePrivate,
            ),
            const SizedBox(height: 10),
            _MultiplayerActionTile(
              icon: Icons.key_outlined,
              title: l10n.multiplayerJoinPrivateTitle,
              subtitle: l10n.multiplayerJoinPrivateSubtitle,
              buttonKey: const Key('multiplayer.joinPrivateAction'),
              busy: busy,
              onPressed: onJoinPrivate,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiplayerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final bool busy;
  final VoidCallback onPressed;
  final Key? buttonKey;

  const _MultiplayerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onPressed,
    this.primary = false,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: buttonKey,
      onPressed: busy ? null : onPressed,
      style: primary
          ? GameUiTheme.primaryButtonStyle()
          : GameUiTheme.outlinedButtonStyle(
              foreground: GameUiTheme.textSecondary,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GameText.actionLabel(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardMeta.copyWith(
                      color: primary
                          ? GameUiTheme.bg.withAlpha(210)
                          : GameUiTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MultiplayerQueuePanel extends StatelessWidget {
  final bool busy;
  final String? error;
  final WireMatch? match;
  final String? currentUserId;
  final DateTime nowUtc;

  const _MultiplayerQueuePanel({
    required this.busy,
    required this.error,
    required this.match,
    required this.currentUserId,
    required this.nowUtc,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final match = this.match;
    final players = LobbyMatchStatusRules.humanPlayerCount(
      match,
      whenMissing: 1,
    );
    final maxPlayers = LobbyMatchStatusRules.maximumPlayers(match);
    final minPlayers = LobbyMatchStatusRules.requiredHumanPlayers(match);
    final waitingForPlayers = players < minPlayers;
    final readyToEnter = match != null && LobbyMatchStatusRules.canEnter(match);
    final title = readyToEnter
        ? l10n.multiplayerQueueReadyTitle
        : waitingForPlayers
        ? l10n.multiplayerQueueSearchingTitle
        : l10n.multiplayerQueueCountdownTitle;
    final subtitle = match == null
        ? l10n.multiplayerQueueConnectingSubtitle
        : waitingForPlayers
        ? l10n.multiplayerQueueWaitingForPlayers(minPlayers)
        : _countdownText(l10n, match.autoStartAt, nowUtc);
    final showCountdownClock =
        match != null && !waitingForPlayers && !readyToEnter;
    final secondsRemaining = showCountdownClock
        ? _countdownSeconds(match.autoStartAt, nowUtc)
        : null;
    return DecoratedBox(
      key: const Key('multiplayer.queuePanel'),
      decoration: BoxDecoration(
        color: GameUiTheme.surface,
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GameUiTheme.accent,
                    ),
                  )
                else
                  const Icon(
                    Icons.groups_2_outlined,
                    size: 18,
                    color: GameUiTheme.accentLight,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    GameText.sectionLabel(l10n.multiplayerServerTitle),
                    style: GameUiTheme.bodyStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(title, style: GameUiTheme.cardTitle),
            const SizedBox(height: 6),
            if (!showCountdownClock)
              Text(
                subtitle,
                key: const Key('multiplayer.queueCountdown'),
                style: GameUiTheme.bodySmall,
              )
            else
              _QueueCountdownClock(
                key: const Key('multiplayer.queueCountdown'),
                label: subtitle,
                secondsRemaining: secondsRemaining,
              ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (players / maxPlayers).clamp(0.0, 1.0).toDouble(),
                color: GameUiTheme.accentLight,
                backgroundColor: GameUiTheme.bg.withAlpha(180),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              GameText.sectionLabel(
                l10n.matchPlayersCount(players, maxPlayers),
              ),
              key: const Key('multiplayer.queuePlayers'),
              style: GameUiTheme.bodyStrong.copyWith(
                color: GameUiTheme.goldLight,
              ),
            ),
            const SizedBox(height: 12),
            _LobbyPlayerList(
              key: const Key('multiplayer.queuePlayersList'),
              players: match?.players ?? const [],
              currentUserId: currentUserId,
              minPlayers: minPlayers,
              maxPlayers: maxPlayers,
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              _MultiplayerErrorText(error: error!),
            ],
          ],
        ),
      ),
    );
  }

  static String _countdownText(
    AppLocalizations l10n,
    DateTime? autoStartAt,
    DateTime nowUtc,
  ) {
    if (autoStartAt == null) {
      return l10n.multiplayerQueuePreparingStart;
    }
    final seconds = autoStartAt.difference(nowUtc.toUtc()).inSeconds;
    if (seconds <= 0) return l10n.multiplayerQueueStartingNow;
    return l10n.multiplayerQueueStartingIn(seconds);
  }

  static int? _countdownSeconds(DateTime? autoStartAt, DateTime nowUtc) {
    if (autoStartAt == null) return null;
    final seconds = autoStartAt.difference(nowUtc.toUtc()).inSeconds;
    return seconds <= 0 ? 0 : seconds;
  }
}
