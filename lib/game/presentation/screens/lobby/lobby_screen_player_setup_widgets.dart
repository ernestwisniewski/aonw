part of 'lobby_screen.dart';

class _PlayerKindToggle extends StatelessWidget {
  final PlayerKind value;
  final ValueChanged<PlayerKind> onChanged;

  const _PlayerKindToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<PlayerKind>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: PlayerKind.human,
          icon: const Icon(Icons.person_outline, size: 14),
          label: Text(GameText.actionLabel(l10n.playerKindHuman)),
        ),
        ButtonSegment(
          value: PlayerKind.ai,
          icon: const Icon(Icons.smart_toy_outlined, size: 14),
          label: Text(GameText.actionLabel(l10n.playerKindAi)),
        ),
      ],
      selected: {value},
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        minimumSize: WidgetStateProperty.all(const Size(0, 34)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GameUiTheme.bg;
          }
          return GameUiTheme.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GameUiTheme.textPrimary;
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: GameUiTheme.textSecondary),
        ),
        textStyle: WidgetStateProperty.all(
          GameUiTheme.labelSmall.copyWith(fontSize: 9),
        ),
      ),
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _PlayerKindBadge extends StatelessWidget {
  final PlayerKind value;

  const _PlayerKindBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ai = value == PlayerKind.ai;
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(90),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.textSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ai ? Icons.smart_toy_outlined : Icons.person_outline,
            size: 14,
            color: GameUiTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            GameText.actionLabel(ai ? l10n.playerKindAi : l10n.playerKindHuman),
            style: GameUiTheme.labelSmall.copyWith(
              color: GameUiTheme.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCountryDropdown extends StatelessWidget {
  final PlayerCountry value;
  final List<PlayerCountry> options;
  final ValueChanged<PlayerCountry> onChanged;

  const _PlayerCountryDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortedOptions = GameDisplayNames.sortedPlayerCountries(
      l10n,
      countries: options,
    );
    return DropdownButtonFormField<PlayerCountry>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: GameUiTheme.surface,
      iconEnabledColor: GameUiTheme.textSecondary,
      style: GameUiTheme.inputText,
      decoration: GameUiTheme.textFieldDecoration(hintText: l10n.countryLabel),
      selectedItemBuilder: (context) => [
        for (final country in sortedOptions)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              GameDisplayNames.playerCountry(l10n, country),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.inputText,
            ),
          ),
      ],
      items: [
        for (final country in sortedOptions)
          DropdownMenuItem(
            value: country,
            child: Text(
              GameDisplayNames.playerCountry(l10n, country),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (country) {
        if (country != null) onChanged(country);
      },
    );
  }
}

class _PlayerCountryBadge extends StatelessWidget {
  const _PlayerCountryBadge({required this.country});

  final PlayerCountry country;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(90),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.textSecondary),
      ),
      child: SizedBox(
        height: 34,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(
                Icons.flag_circle_outlined,
                size: 14,
                color: GameUiTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  GameDisplayNames.playerCountry(l10n, country),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.labelSmall.copyWith(
                    color: GameUiTheme.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
