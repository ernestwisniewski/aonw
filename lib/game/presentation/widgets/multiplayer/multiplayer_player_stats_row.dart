part of 'multiplayer_status_sheet.dart';

class _PlayerStatsRow extends StatelessWidget {
  const _PlayerStatsRow({required this.stats});

  final MultiplayerPlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('multiplayerStatusStats.player.${stats.tile.player.id}'),
      decoration: SurfaceElevation.raised.decoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SurfaceElevation.raised.fill(
              background: GameUiTheme.surface,
              alpha: 216,
            ),
            SurfaceElevation.raised.fill(
              background: GameUiTheme.surfaceDeep,
              alpha: 216,
            ),
          ],
        ),
        shape: SurfaceShape.card,
        border: BorderEmphasis.subtle,
        includeShadow: false,
      ),
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlayerStatsHeader(stats: stats),
          const SizedBox(height: 8),
          _PlayerStatChips(stats: stats),
        ],
      ),
    );
  }
}

class _PlayerStatsHeader extends StatelessWidget {
  const _PlayerStatsHeader({required this.stats});

  final MultiplayerPlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = stats.tile.player;
    final playerColor = PlayerColorTheme.resolve(player.colorValue);
    final relation = stats.tile.relationStatus;
    return Row(
      children: [
        PlayerColorDot(color: playerColor, active: false),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            stats.tile.playerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodyStrong.copyWith(
              color: GameUiTheme.textBright,
            ),
          ),
        ),
        _MiniStatusChip(
          label: MultiplayerAvatarStatusStyle.label(l10n, stats.tile.status),
          color: MultiplayerAvatarStatusStyle.color(
            stats.tile.status,
            playerColor,
          ),
        ),
        if (relation != null) ...[
          const SizedBox(width: 5),
          _MiniStatusChip(
            label: MultiplayerRelationStatusStyle.shortLabel(l10n, relation),
            color: MultiplayerRelationStatusStyle.color(relation),
          ),
        ],
      ],
    );
  }
}

class _PlayerStatChips extends StatelessWidget {
  const _PlayerStatChips({required this.stats});

  final MultiplayerPlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playerId = stats.tile.player.id;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _StatChip(
          key: Key('multiplayerStatusStats.player.$playerId.citiesValue'),
          icon: GameIcons.cityFilled,
          label: l10n.commonCities,
          value: stats.cityCount,
        ),
        _StatChip(
          key: Key('multiplayerStatusStats.player.$playerId.unitsValue'),
          icon: GameIcons.army,
          label: l10n.unitsSection,
          value: stats.unitCount,
        ),
        _StatChip(
          key: Key('multiplayerStatusStats.player.$playerId.populationValue'),
          icon: GameIcons.population,
          label: l10n.commonPopulation,
          value: stats.population,
        ),
        _StatChip(
          key: Key('multiplayerStatusStats.player.$playerId.artifactsValue'),
          icon: GameIcons.artifact,
          label: l10n.empireStatsStoredArtifacts,
          value: stats.storedArtifactCount,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final GameIconData icon;
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      decoration: BoxDecoration(
        color: GameUiTheme.chipSurface.withAlpha(164),
        borderRadius: GameUiTheme.chipBorderRadius,
        border: Border.all(color: GameUiTheme.border.withAlpha(54)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(icon, size: GameIconSize.tiny, color: GameUiTheme.gold),
          const SizedBox(width: 6),
          Text(
            value?.toString() ?? '?',
            style: GameUiTheme.bodyStrong.copyWith(
              color: GameUiTheme.textBright,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GameUiTheme.chipLabel.copyWith(
              color: GameUiTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: GameUiTheme.chipBorderRadius,
        border: Border.all(color: color.withAlpha(128)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.chipLabel.copyWith(color: color),
      ),
    );
  }
}
