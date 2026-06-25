part of 'lobby_screen.dart';

enum _GameLengthPreset { unlimited, standard60, long120 }

extension _GameLengthPresetUi on _GameLengthPreset {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _GameLengthPreset.unlimited => l10n.gameLengthPresetUnlimited,
      _GameLengthPreset.standard60 => l10n.gameLengthPresetStandard60,
      _GameLengthPreset.long120 => l10n.gameLengthPresetLong120,
    };
  }

  IconData get icon {
    return switch (this) {
      _GameLengthPreset.unlimited => Icons.all_inclusive,
      _GameLengthPreset.standard60 => Icons.schedule_outlined,
      _GameLengthPreset.long120 => Icons.hourglass_bottom_outlined,
    };
  }

  GameLengthConfig get config {
    return switch (this) {
      _GameLengthPreset.unlimited => GameLengthConfig.unlimited,
      _GameLengthPreset.standard60 => GameLengthConfig.standard60,
      _GameLengthPreset.long120 => GameLengthConfig.long120,
    };
  }
}

class _GameLengthSelector extends StatelessWidget {
  final _GameLengthPreset value;
  final ValueChanged<_GameLengthPreset> onPresetChanged;

  const _GameLengthSelector({
    required this.value,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = value.config;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(120),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<_GameLengthPreset>(
              key: const Key('game-length-dropdown'),
              initialValue: value,
              isExpanded: true,
              dropdownColor: GameUiTheme.surface,
              iconEnabledColor: GameUiTheme.textSecondary,
              style: GameUiTheme.inputText,
              decoration: GameUiTheme.textFieldDecoration(
                hintText: l10n.gameLengthPresetHint,
              ),
              selectedItemBuilder: (context) => [
                for (final preset in _GameLengthPreset.values)
                  _GameLengthOptionLabel(preset: preset),
              ],
              items: [
                for (final preset in _GameLengthPreset.values)
                  DropdownMenuItem(
                    value: preset,
                    child: _GameLengthOptionLabel(preset: preset),
                  ),
              ],
              onChanged: (preset) {
                if (preset != null) onPresetChanged(preset);
              },
            ),
            const SizedBox(height: 10),
            Text(
              _summaryFor(l10n, config),
              style: GameUiTheme.bodyStrong.copyWith(
                color: GameUiTheme.goldLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(_rulesFor(l10n, config), style: GameUiTheme.cardMeta),
          ],
        ),
      ),
    );
  }

  String _summaryFor(AppLocalizations l10n, GameLengthConfig config) {
    final turns = config.turnLimit;
    if (config.kind == GameLengthKind.unlimited) {
      return l10n.gameLengthUnlimitedSummary;
    }
    final targetMinutes = config.targetMinutes;
    if (targetMinutes == null || turns == null) {
      return l10n.gameLengthUnlimitedSummary;
    }
    return l10n.gameLengthTimedSummary(targetMinutes, turns);
  }

  String _rulesFor(AppLocalizations l10n, GameLengthConfig config) {
    final rules = VictoryRules.forGameLength(config);
    final fallback = rules.scoreFallbackEnabled
        ? l10n.gameLengthScoreFallbackOn
        : l10n.gameLengthScoreFallbackOff;
    return l10n.gameLengthVictoryRules(
      rules.dominationControlPercent.toStringAsFixed(0),
      rules.dominationHoldTurns,
      fallback,
    );
  }
}

class _GameLengthOptionLabel extends StatelessWidget {
  final _GameLengthPreset preset;

  const _GameLengthOptionLabel({required this.preset});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Icon(preset.icon, size: 16, color: GameUiTheme.goldLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            GameText.actionLabel(preset.label(l10n)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.inputText,
          ),
        ),
      ],
    );
  }
}

class _MapValidationNotice extends StatelessWidget {
  final MapValidationResult? result;
  final bool loading;
  final Object? loadError;

  const _MapValidationNotice({
    required this.result,
    required this.loading,
    required this.loadError,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = this.result;
    final issues = result == null
        ? const <MapValidationIssue>[]
        : [...result.errors, ...result.warnings];
    if (!loading && loadError == null && issues.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasErrors = loadError != null || result?.errors.isNotEmpty == true;
    final color = hasErrors ? GameUiTheme.danger : GameUiTheme.gold;
    final title = hasErrors
        ? l10n.mapValidationErrorTitle
        : loading
        ? l10n.mapValidationLoadingTitle
        : l10n.mapValidationWarningTitle;
    final messages = loadError != null
        ? [l10n.mapValidationLoadError('$loadError')]
        : loading
        ? [l10n.mapValidationLoadingMessage]
        : [for (final issue in issues.take(3)) _issueText(l10n, issue)];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        key: const Key('lobby.mapValidationNotice'),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: GameUiTheme.borderRadius,
          border: Border.all(color: color.withAlpha(105)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasErrors ? Icons.error_outline : Icons.warning_amber_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GameUiTheme.bodyStrong.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < messages.length; i++) ...[
                      Text(
                        messages[i],
                        style: GameUiTheme.cardMeta.copyWith(
                          color: GameUiTheme.textSecondary,
                          height: 1.2,
                        ),
                      ),
                      if (i < messages.length - 1) const SizedBox(height: 3),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _issueText(AppLocalizations l10n, MapValidationIssue issue) {
    return switch (issue.code) {
      'short_game_slow_first_contact' =>
        l10n.mapValidationIssueSlowFirstContact,
      'short_game_large_map' => l10n.mapValidationIssueLargeMap,
      'invalid_player_count' => l10n.mapValidationIssueInvalidPlayerCount,
      'map_has_no_tiles' => l10n.mapValidationIssueNoTiles,
      'low_passable_tile_ratio' => l10n.mapValidationIssueLowPassableTileRatio,
      'low_food_resource_density' =>
        l10n.mapValidationIssueLowFoodResourceDensity,
      'low_strategic_resource_density' =>
        l10n.mapValidationIssueLowStrategicResourceDensity,
      'low_luxury_resource_density' =>
        l10n.mapValidationIssueLowLuxuryResourceDensity,
      'start_site_not_foundable' =>
        l10n.mapValidationIssueStartSiteNotFoundable,
      'start_site_low_land_ring' => l10n.mapValidationIssueStartSiteLowLandRing,
      'start_site_low_food' => l10n.mapValidationIssueStartSiteLowFood,
      'start_site_low_city_control' =>
        l10n.mapValidationIssueStartSiteLowCityControl,
      'start_sites_too_close' => l10n.mapValidationIssueStartSitesTooClose,
      _ => issue.message,
    };
  }
}

class _LobbyStartSummary extends StatelessWidget {
  final String mapName;
  final int playerCount;

  const _LobbyStartSummary({required this.mapName, required this.playerCount});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        const Icon(Icons.flag_outlined, size: 18, color: GameUiTheme.gold),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            l10n.lobbyMapPlayersSummary(mapName, playerCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodyStrong.copyWith(
              color: GameUiTheme.goldLight,
            ),
          ),
        ),
      ],
    );
  }
}
