part of 'multiplayer_status_sheet.dart';

class _EmpireStatsPanel extends StatelessWidget {
  const _EmpireStatsPanel({required this.data});

  final MultiplayerStatusSheetData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('multiplayerStatusStats.panel'),
      decoration: SurfaceElevation.flat.decoration(
        accent: GameUiTheme.gold,
        backgroundAlpha: 190,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmpireStatsHeader(label: l10n.commonEmpire),
          const SizedBox(height: 10),
          _EmpireShareBars(data: data, l10n: l10n),
          const SizedBox(height: 12),
          _PlayerStatsList(players: data.players),
        ],
      ),
    );
  }
}

class _EmpireStatsHeader extends StatelessWidget {
  const _EmpireStatsHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GameIcon(
          GameIcons.stats,
          size: GameIconSize.small,
          color: GameUiTheme.gold,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.sectionHeader,
          ),
        ),
      ],
    );
  }
}

class _EmpireShareBars extends StatelessWidget {
  const _EmpireShareBars({required this.data, required this.l10n});

  final MultiplayerStatusSheetData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShareBar(
          key: const Key('multiplayerStatusStats.shareBar.cities'),
          icon: GameIcons.cityFilled,
          label: l10n.commonCities,
          total: data.totalCities,
          players: data.players,
          valueFor: (player) => player.cityCount,
        ),
        const SizedBox(height: 8),
        _ShareBar(
          key: const Key('multiplayerStatusStats.shareBar.units'),
          icon: GameIcons.army,
          label: l10n.unitsSection,
          total: data.totalUnits,
          players: data.players,
          valueFor: (player) => player.unitCount,
        ),
        const SizedBox(height: 8),
        _ShareBar(
          key: const Key('multiplayerStatusStats.shareBar.population'),
          icon: GameIcons.population,
          label: l10n.commonPopulation,
          total: data.totalPopulation,
          players: data.players,
          valueFor: (player) => player.population,
        ),
        const SizedBox(height: 8),
        _ShareBar(
          key: const Key('multiplayerStatusStats.shareBar.artifacts'),
          icon: GameIcons.artifact,
          label: l10n.empireStatsStoredArtifacts,
          total: data.totalStoredArtifacts,
          players: data.players,
          valueFor: (player) => player.storedArtifactCount,
        ),
      ],
    );
  }
}

class _PlayerStatsList extends StatelessWidget {
  const _PlayerStatsList({required this.players});

  final List<MultiplayerPlayerStats> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < players.length; index++) ...[
          _PlayerStatsRow(stats: players[index]),
          if (index < players.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

typedef _PlayerStatValue = int? Function(MultiplayerPlayerStats player);

class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.icon,
    required this.label,
    required this.total,
    required this.players,
    required this.valueFor,
    super.key,
  });

  final GameIconData icon;
  final String label;
  final int total;
  final List<MultiplayerPlayerStats> players;
  final _PlayerStatValue valueFor;

  @override
  Widget build(BuildContext context) {
    final visiblePlayers = [
      for (final player in players)
        if ((valueFor(player) ?? 0) > 0) player,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShareBarHeader(icon: icon, label: label, total: total),
        const SizedBox(height: 5),
        _ShareBarDistribution(players: visiblePlayers, valueFor: valueFor),
      ],
    );
  }
}

class _ShareBarHeader extends StatelessWidget {
  const _ShareBarHeader({
    required this.icon,
    required this.label,
    required this.total,
  });

  final GameIconData icon;
  final String label;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GameIcon(icon, size: GameIconSize.tiny, color: GameUiTheme.gold),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.chipLabel.copyWith(
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
        Text(
          total.toString(),
          style: GameUiTheme.bodyStrong.copyWith(color: GameUiTheme.textBright),
        ),
      ],
    );
  }
}

class _ShareBarDistribution extends StatelessWidget {
  const _ShareBarDistribution({required this.players, required this.valueFor});

  final List<MultiplayerPlayerStats> players;
  final _PlayerStatValue valueFor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: GameUiTheme.pillBorderRadius,
      child: Container(
        height: 9,
        decoration: BoxDecoration(
          color: GameUiTheme.surfaceDeep.withAlpha(210),
        ),
        child: players.isEmpty
            ? const SizedBox.expand()
            : Row(
                children: [
                  for (final player in players)
                    Expanded(
                      flex: math.max(1, valueFor(player) ?? 0),
                      child: ColoredBox(
                        color: PlayerColorTheme.resolve(
                          player.tile.player.colorValue,
                        ).withAlpha(224),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
