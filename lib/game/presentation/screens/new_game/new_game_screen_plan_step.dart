part of 'new_game_screen.dart';

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.flow,
    required this.playerCountry,
    required this.gameLengthPreset,
    required this.aiDifficulty,
    required this.onFlowChanged,
    required this.onPlayerCountryChanged,
    required this.onGameLengthChanged,
    required this.onAiDifficultyChanged,
    super.key,
  });

  final NewGameFlow flow;
  final PlayerCountry playerCountry;
  final _SinglePlayerGameLengthPreset gameLengthPreset;
  final AiDifficulty aiDifficulty;
  final ValueChanged<NewGameFlow> onFlowChanged;
  final ValueChanged<PlayerCountry> onPlayerCountryChanged;
  final ValueChanged<_SinglePlayerGameLengthPreset> onGameLengthChanged;
  final ValueChanged<AiDifficulty> onAiDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MenuRouteSection(
      icon: Icons.auto_awesome,
      title: l10n.newGamePlanTitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final modeCards = [
            for (final value in NewGameFlowX.choiceOrder)
              _ModeChoiceCard(
                key: Key('newGame.mode.${value.queryValue}'),
                flow: value,
                selected: flow == value,
                enabled: value.enabled,
                disabledReason: value.disabledReason(l10n),
                onTap: value.enabled ? () => onFlowChanged(value) : null,
              ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModeChoiceBlock(wide: wide, cards: modeCards),
              const SizedBox(height: 12),
              if (flow == NewGameFlow.singlePlayer) ...[
                _SinglePlayerCountryPanel(
                  key: const Key('newGame.countryPanel'),
                  country: playerCountry,
                  onChanged: onPlayerCountryChanged,
                ),
                const SizedBox(height: 12),
                _SinglePlayerSettingsPanel(
                  key: const Key('newGame.singlePlayerSettingsPanel'),
                  gameLengthPreset: gameLengthPreset,
                  aiDifficulty: aiDifficulty,
                  onGameLengthChanged: onGameLengthChanged,
                  onAiDifficultyChanged: onAiDifficultyChanged,
                ),
                const SizedBox(height: 12),
              ],
              _VictoryTypesPanel(
                key: const Key('newGame.victoryPanel'),
                rules: VictoryRules.forGameLength(gameLengthPreset.config),
              ),
              const SizedBox(height: 12),
              _GamePremisePanel(
                key: const Key('newGame.premisePanel'),
                flow: flow,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeChoiceBlock extends StatelessWidget {
  const _ModeChoiceBlock({required this.wide, required this.cards});

  final bool wide;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index < cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          cards[index],
          if (index < cards.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _VictoryTypesPanel extends StatelessWidget {
  const _VictoryTypesPanel({required this.rules, super.key});

  final VictoryRules rules;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dominationPercent = rules.dominationControlPercent.toStringAsFixed(0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(138),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(92)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newGameVictoryTypesTitle,
              style: GameUiTheme.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            _VictoryPathRow(
              icon: Icons.flag_outlined,
              title: l10n.newGameVictoryDominationTitle,
              body: l10n.newGameVictoryDominationBody(
                dominationPercent,
                rules.dominationHoldTurns,
              ),
              accent: GameUiTheme.copper,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: GoldDivider(alpha: 64),
            ),
            _VictoryPathRow(
              icon: Icons.diamond_outlined,
              title: l10n.newGameVictoryArtifactsTitle,
              body: l10n.newGameVictoryArtifactsBody(
                rules.culturalRequiredArtifacts,
                rules.culturalHoldTurns,
              ),
              accent: GameUiTheme.goldLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _VictoryPathRow extends StatelessWidget {
  const _VictoryPathRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiTheme.surface.withAlpha(132),
            borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
            border: Border.all(color: accent.withAlpha(128)),
          ),
          child: SizedBox.square(
            dimension: 38,
            child: Icon(icon, size: 20, color: accent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: GameUiTheme.cardMeta.copyWith(
                  color: GameUiTheme.textTertiary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
