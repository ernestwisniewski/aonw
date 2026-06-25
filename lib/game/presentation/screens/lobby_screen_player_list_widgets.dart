part of 'lobby_screen.dart';

class _LobbyPlayerList extends StatelessWidget {
  const _LobbyPlayerList({
    required this.players,
    required this.currentUserId,
    required this.minPlayers,
    required this.maxPlayers,
    super.key,
  });

  final List<WirePlayer> players;
  final String? currentUserId;
  final int minPlayers;
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    final humans = players
        .where((player) => player.kind == WirePlayerKind.human)
        .toList(growable: false);
    final totalSlots = maxPlayers < humans.length ? humans.length : maxPlayers;
    return Column(
      key: const Key('multiplayer.playerList'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < humans.length; index++) ...[
          _LobbyPlayerTile(
            player: humans[index],
            currentUserId: currentUserId,
            host: index == 0,
          ),
          if (index < totalSlots - 1) const SizedBox(height: 7),
        ],
        for (var index = humans.length; index < totalSlots; index++) ...[
          _LobbyEmptyPlayerSlot(
            slotNumber: index + 1,
            requiredSlot: index < minPlayers,
          ),
          if (index < totalSlots - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _LobbyPlayerTile extends StatelessWidget {
  const _LobbyPlayerTile({
    required this.player,
    required this.currentUserId,
    required this.host,
  });

  final WirePlayer player;
  final String? currentUserId;
  final bool host;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = Color(player.colorValue);
    final isCurrent = currentUserId != null && player.userId == currentUserId;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(112),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(color: GameUiTheme.gold.withAlpha(66)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                isCurrent ? Icons.person_pin_circle_outlined : Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameUiTheme.bodyStrong.copyWith(
                            color: GameUiTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        _LobbyPlayerTag(label: l10n.lobbyPlayerYou),
                      if (host) ...[
                        if (isCurrent) const SizedBox(width: 5),
                        _LobbyPlayerTag(label: l10n.lobbyPlayerHost),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${GameDisplayNames.playerCountry(l10n, player.country)} - '
                    '${_playerStatusLabel(l10n, player)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardMeta.copyWith(
                      color: GameUiTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _playerStatusLabel(AppLocalizations l10n, WirePlayer player) {
    if (player.ready) return l10n.lobbyPlayerReady;
    return switch (player.connectionState) {
      WirePlayerConnectionState.connected => l10n.lobbyPlayerConnected,
      WirePlayerConnectionState.connecting => l10n.lobbyPlayerConnecting,
      WirePlayerConnectionState.reconnecting => l10n.lobbyPlayerReconnecting,
      WirePlayerConnectionState.offline => l10n.lobbyPlayerOffline,
    };
  }
}

class _LobbyPlayerTag extends StatelessWidget {
  const _LobbyPlayerTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.gold.withAlpha(28),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusPill),
        border: Border.all(color: GameUiTheme.gold.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          GameText.sectionLabel(label),
          style: GameUiTheme.chipLabel.copyWith(
            color: GameUiTheme.goldLight,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class _LobbyEmptyPlayerSlot extends StatelessWidget {
  const _LobbyEmptyPlayerSlot({
    required this.slotNumber,
    required this.requiredSlot,
  });

  final int slotNumber;
  final bool requiredSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      key: Key('multiplayer.playerSlot.empty.$slotNumber'),
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(62),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(color: GameUiTheme.gold.withAlpha(42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: GameUiTheme.surface.withAlpha(140),
                shape: BoxShape.circle,
                border: Border.all(color: GameUiTheme.gold.withAlpha(58)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_add_alt_1_outlined,
                size: 16,
                color: GameUiTheme.gold.withAlpha(150),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lobbyPlayerOpenSlot(slotNumber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.bodyStrong.copyWith(
                      color: GameUiTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    requiredSlot
                        ? l10n.lobbyPlayerRequiredSlot
                        : l10n.lobbyPlayerOptionalSlot,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.cardMeta.copyWith(
                      color: GameUiTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiplayerReadinessSummary extends StatelessWidget {
  final int players;
  final int minPlayers;
  final int maxPlayers;
  final bool waiting;

  const _MultiplayerReadinessSummary({
    super.key,
    required this.players,
    required this.minPlayers,
    required this.maxPlayers,
    required this.waiting,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(96),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              waiting
                  ? Icons.hourglass_top_rounded
                  : Icons.check_circle_outline,
              size: 18,
              color: waiting ? GameUiTheme.gold : GameUiTheme.accentLight,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                GameText.sectionLabel(
                  l10n.matchPlayersCount(players, maxPlayers),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
            Text(
              '$players/$minPlayers',
              style: GameUiTheme.cardMeta.copyWith(
                color: waiting
                    ? GameUiTheme.textSecondary
                    : GameUiTheme.accentLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
