part of 'new_game_screen.dart';

class _SinglePlayerCountryPanel extends StatelessWidget {
  const _SinglePlayerCountryPanel({
    super.key,
    required this.country,
    required this.onChanged,
  });

  final PlayerCountry country;
  final ValueChanged<PlayerCountry> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leader = GameDisplayNames.playerCountryLeader(l10n, country);
    final countries = GameDisplayNames.sortedPlayerCountries(l10n);
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
              l10n.newGameCountryTitle,
              style: GameUiTheme.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.newGameCountrySubtitle,
              style: GameUiTheme.cardMeta.copyWith(
                color: GameUiTheme.textTertiary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlayerCountry>(
              initialValue: country,
              isExpanded: true,
              dropdownColor: GameUiTheme.surface,
              iconEnabledColor: GameUiTheme.textSecondary,
              style: GameUiTheme.inputText,
              decoration: GameUiTheme.textFieldDecoration(
                hintText: l10n.countryLabel,
              ),
              selectedItemBuilder: (context) => [
                for (final value in countries)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      GameDisplayNames.playerCountry(l10n, value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.inputText,
                    ),
                  ),
              ],
              items: [
                for (final value in countries)
                  DropdownMenuItem(
                    value: value,
                    child: Text(
                      GameDisplayNames.playerCountry(l10n, value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
            const SizedBox(height: 10),
            _LeaderPreview(leader: leader),
          ],
        ),
      ),
    );
  }
}

class _SinglePlayerSettingsPanel extends StatelessWidget {
  const _SinglePlayerSettingsPanel({
    super.key,
    required this.gameLengthPreset,
    required this.aiDifficulty,
    required this.onGameLengthChanged,
    required this.onAiDifficultyChanged,
  });

  final _SinglePlayerGameLengthPreset gameLengthPreset;
  final AiDifficulty aiDifficulty;
  final ValueChanged<_SinglePlayerGameLengthPreset> onGameLengthChanged;
  final ValueChanged<AiDifficulty> onAiDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              l10n.newGameSinglePlayerSettingsTitle,
              style: GameUiTheme.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                final lengthDropdown =
                    _SettingsDropdown<_SinglePlayerGameLengthPreset>(
                      key: const Key('newGame.gameLengthSelector'),
                      value: gameLengthPreset,
                      hintText: l10n.newGameGameLengthLabel,
                      iconFor: (value) => value.icon,
                      labelFor: (value) => value.label(l10n),
                      values: _SinglePlayerGameLengthPreset.values,
                      onChanged: onGameLengthChanged,
                    );
                final difficultyDropdown = _SettingsDropdown<AiDifficulty>(
                  key: const Key('newGame.aiDifficultySelector'),
                  value: aiDifficulty,
                  hintText: l10n.aiDifficultyLabel,
                  iconFor: (value) => value.icon,
                  labelFor: (value) => value.label(l10n),
                  values: AiDifficulty.values,
                  onChanged: onAiDifficultyChanged,
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: lengthDropdown),
                      const SizedBox(width: 12),
                      Expanded(child: difficultyDropdown),
                    ],
                  );
                }
                return Column(
                  children: [
                    lengthDropdown,
                    const SizedBox(height: 12),
                    difficultyDropdown,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    super.key,
    required this.value,
    required this.hintText,
    required this.iconFor,
    required this.labelFor,
    required this.values,
    required this.onChanged,
  });

  final T value;
  final String hintText;
  final IconData Function(T value) iconFor;
  final String Function(T value) labelFor;
  final List<T> values;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: GameUiTheme.surface,
      iconEnabledColor: GameUiTheme.textSecondary,
      style: GameUiTheme.inputText,
      decoration: GameUiTheme.textFieldDecoration(hintText: hintText),
      selectedItemBuilder: (context) => [
        for (final option in values)
          _SettingsDropdownLabel(
            icon: iconFor(option),
            label: labelFor(option),
            selected: true,
          ),
      ],
      items: [
        for (final option in values)
          DropdownMenuItem(
            value: option,
            child: _SettingsDropdownLabel(
              icon: iconFor(option),
              label: labelFor(option),
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SettingsDropdownLabel extends StatelessWidget {
  const _SettingsDropdownLabel({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: selected ? GameUiTheme.goldLight : GameUiTheme.gold,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: selected ? GameUiTheme.inputText : null,
          ),
        ),
      ],
    );
  }
}

class _LeaderPreview extends StatelessWidget {
  const _LeaderPreview({required this.leader});

  final String leader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            const Icon(
              Icons.workspace_premium_outlined,
              size: 18,
              color: GameUiTheme.gold,
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 82,
              child: Text(
                GameText.sectionLabel(l10n.newGameLeaderLabel),
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
                leader,
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
