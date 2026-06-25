import 'dart:math' as math;

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_parts.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_layouts.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_status_sheet_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class MultiplayerStatusSheet extends StatelessWidget {
  static const double _wideLayoutBreakpoint = 560;
  static const double _minLeaderTileWidth = 260;
  static const double _maxLeaderTileWidth = 340;

  const MultiplayerStatusSheet({
    required this.tiles,
    required this.onAvatarTapped,
    this.gameState,
    super.key,
  });

  final List<MultiplayerAvatarTileData> tiles;
  final GameState? gameState;
  final ValueChanged<String> onAvatarTapped;

  @override
  Widget build(BuildContext context) {
    final data = MultiplayerStatusSheetData.from(
      tiles: tiles,
      gameState: gameState,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final availableWidth = maxWidth.isFinite
            ? maxWidth
            : _minLeaderTileWidth;
        final wide = availableWidth >= _wideLayoutBreakpoint;
        final narrowTileWidth = math.max(_minLeaderTileWidth, availableWidth);
        final wideTileWidth = math.min(
          _maxLeaderTileWidth,
          math.max(_minLeaderTileWidth, availableWidth * 0.38),
        );
        final tileWidth = wide ? wideTileWidth : narrowTileWidth;
        final playerList = ExpandedMultiplayerAvatarsRail(
          key: const Key('multiplayerAvatarsRail.fullList'),
          tiles: tiles,
          tileWidth: tileWidth,
          onAvatarTapped: onAvatarTapped,
        );

        if (!data.hasEmpireStats) {
          return Align(alignment: Alignment.centerLeft, child: playerList);
        }

        final statsPanel = _EmpireStatsPanel(data: data);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: tileWidth, child: playerList),
              const SizedBox(width: 12),
              Expanded(child: statsPanel),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [playerList, const SizedBox(height: 12), statsPanel],
        );
      },
    );
  }
}

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
          Row(
            children: [
              const GameIcon(
                GameIcons.stats,
                size: GameIconSize.small,
                color: GameUiTheme.gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.commonEmpire,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.sectionHeader,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 12),
          for (final player in data.players) ...[
            _PlayerStatsRow(stats: player),
            if (player != data.players.last) const SizedBox(height: 8),
          ],
        ],
      ),
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
        Row(
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
              style: GameUiTheme.bodyStrong.copyWith(
                color: GameUiTheme.textBright,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: GameUiTheme.pillBorderRadius,
          child: Container(
            height: 9,
            decoration: BoxDecoration(
              color: GameUiTheme.surfaceDeep.withAlpha(210),
            ),
            child: visiblePlayers.isEmpty
                ? const SizedBox.expand()
                : Row(
                    children: [
                      for (final player in visiblePlayers)
                        Expanded(
                          flex: math.max(1, valueFor(player) ?? 0),
                          child: Container(
                            color: PlayerColorTheme.resolve(
                              player.tile.player.colorValue,
                            ).withAlpha(224),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _PlayerStatsRow extends StatelessWidget {
  const _PlayerStatsRow({required this.stats});

  final MultiplayerPlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = stats.tile.player;
    final playerColor = PlayerColorTheme.resolve(player.colorValue);
    final statusColor = MultiplayerAvatarStatusStyle.color(
      stats.tile.status,
      playerColor,
    );
    final relation = stats.tile.relationStatus;

    return Container(
      key: Key('multiplayerStatusStats.player.${player.id}'),
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
          Row(
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
                label: MultiplayerAvatarStatusStyle.label(
                  l10n,
                  stats.tile.status,
                ),
                color: statusColor,
              ),
              if (relation != null) ...[
                const SizedBox(width: 5),
                _MiniStatusChip(
                  label: MultiplayerRelationStatusStyle.shortLabel(
                    l10n,
                    relation,
                  ),
                  color: MultiplayerRelationStatusStyle.color(relation),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StatChip(
                key: Key(
                  'multiplayerStatusStats.player.${player.id}.citiesValue',
                ),
                icon: GameIcons.cityFilled,
                label: l10n.commonCities,
                value: stats.cityCount,
              ),
              _StatChip(
                key: Key(
                  'multiplayerStatusStats.player.${player.id}.unitsValue',
                ),
                icon: GameIcons.army,
                label: l10n.unitsSection,
                value: stats.unitCount,
              ),
              _StatChip(
                key: Key(
                  'multiplayerStatusStats.player.${player.id}.populationValue',
                ),
                icon: GameIcons.population,
                label: l10n.commonPopulation,
                value: stats.population,
              ),
              _StatChip(
                key: Key(
                  'multiplayerStatusStats.player.${player.id}.artifactsValue',
                ),
                icon: GameIcons.artifact,
                label: l10n.empireStatsStoredArtifacts,
                value: stats.storedArtifactCount,
              ),
            ],
          ),
        ],
      ),
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
