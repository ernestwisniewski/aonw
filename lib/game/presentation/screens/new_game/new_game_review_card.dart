part of 'new_game_screen.dart';

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.flow,
    required this.map,
    required this.playerCountry,
    required this.gameLengthPreset,
    required this.aiDifficulty,
    required this.mapPickedManually,
    required this.singlePlayerPlayerCount,
  });

  final NewGameFlow flow;
  final MapSelection map;
  final PlayerCountry playerCountry;
  final _SinglePlayerGameLengthPreset gameLengthPreset;
  final AiDifficulty aiDifficulty;
  final bool mapPickedManually;
  final int singlePlayerPlayerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final singlePlayerAiOpponentCount =
        NewGameSinglePlayerSetup.aiOpponentCountForPlayerCount(
          singlePlayerPlayerCount,
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(138),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(96)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameUiEpicHeader(label: l10n.newGameExpeditionReady, compact: true),
            const SizedBox(height: 12),
            _ReviewRow(
              icon: flow.icon,
              label: l10n.gameModeLabel,
              value: flow.menuLabel(l10n),
            ),
            const SizedBox(height: 10),
            _ReviewRow(
              icon: Icons.map_outlined,
              label: l10n.newGameSelectedMapLabel,
              value: map.displayName,
            ),
            if (flow == NewGameFlow.singlePlayer) ...[
              const SizedBox(height: 10),
              _ReviewRow(
                icon: mapPickedManually
                    ? Icons.touch_app_outlined
                    : Icons.casino_outlined,
                label: l10n.newGameMapPickLabel,
                value: mapPickedManually
                    ? l10n.newGameMapPickManual
                    : l10n.newGameMapPickRandom,
              ),
            ],
            const SizedBox(height: 10),
            _ReviewRow(
              icon: Icons.layers_outlined,
              label: l10n.newGameWorldSourceLabel,
              value: map.sourceLabel,
            ),
            if (flow == NewGameFlow.singlePlayer) ...[
              const SizedBox(height: 10),
              _ReviewRow(
                icon: Icons.flag_circle_outlined,
                label: l10n.countryLabel,
                value: GameDisplayNames.playerCountry(l10n, playerCountry),
              ),
              const SizedBox(height: 10),
              _ReviewRow(
                icon: Icons.workspace_premium_outlined,
                label: l10n.newGameLeaderLabel,
                value: GameDisplayNames.playerCountryLeader(
                  l10n,
                  playerCountry,
                ),
              ),
              const SizedBox(height: 10),
              _ReviewRow(
                icon: gameLengthPreset.icon,
                label: l10n.newGameGameLengthLabel,
                value: gameLengthPreset.label(l10n),
              ),
              const SizedBox(height: 10),
              _ReviewRow(
                icon: aiDifficulty.icon,
                label: l10n.aiDifficultyLabel,
                value: aiDifficulty.label(l10n),
              ),
              const SizedBox(height: 10),
              _ReviewRow(
                icon: Icons.smart_toy_outlined,
                label: l10n.playersLabel,
                value: l10n.newGameSinglePlayerAiSummary(
                  singlePlayerAiOpponentCount,
                ),
              ),
            ],
            const SizedBox(height: 13),
            Text(
              flow == NewGameFlow.singlePlayer
                  ? l10n.newGameReviewSinglePlayerSubtitle(
                      singlePlayerAiOpponentCount,
                    )
                  : l10n.newGameReviewSubtitle,
              style: GameUiTheme.bodySmall.copyWith(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(130),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(color: GameUiTheme.gold.withAlpha(62)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: GameUiTheme.gold),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              child: Text(
                GameText.sectionLabel(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _flowDescription(AppLocalizations l10n, NewGameFlow flow) {
  return switch (flow) {
    NewGameFlow.singlePlayer => l10n.newGameModeSinglePlayerDescription,
    NewGameFlow.multiplayer => l10n.newGameModeMultiplayerDescription,
    NewGameFlow.hotSeat => l10n.newGameModeHotSeatDescription,
  };
}
