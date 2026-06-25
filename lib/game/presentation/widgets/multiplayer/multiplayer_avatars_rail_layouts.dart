import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_tile.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_metrics.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class ExpandedMultiplayerAvatarsRail extends StatelessWidget {
  const ExpandedMultiplayerAvatarsRail({
    required this.tiles,
    required this.onAvatarTapped,
    this.tileWidth = MultiplayerAvatarsRailMetrics.itemWidth,
    this.onOpenFullList,
    super.key,
  });

  final List<MultiplayerAvatarTileData> tiles;
  final ValueChanged<String> onAvatarTapped;
  final double tileWidth;
  final VoidCallback? onOpenFullList;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tile in tiles)
          Padding(
            padding: const EdgeInsets.only(
              bottom: MultiplayerAvatarsRailMetrics.itemGap,
            ),
            child: MultiplayerAvatarTile(
              key: Key('multiplayerAvatar.${tile.player.id}'),
              player: tile.player,
              playerName: tile.playerName,
              status: tile.status,
              timerLabel: tile.timerLabel,
              relationStatus: tile.relationStatus,
              width: tileWidth,
              onTap: () => onAvatarTapped(tile.player.id),
            ),
          ),
        if (onOpenFullList != null)
          _OpenStatusSheetButton(
            width: tileWidth,
            height: MultiplayerAvatarsRailMetrics.compactItemSize,
            borderRadius: GameUiTheme.radiusCard,
            onTap: onOpenFullList!,
          ),
      ],
    );
  }
}

class CompactMultiplayerAvatarsRail extends StatelessWidget {
  const CompactMultiplayerAvatarsRail({
    required this.tiles,
    required this.onAvatarTapped,
    required this.onOpenFullList,
    super.key,
  });

  final List<MultiplayerAvatarTileData> tiles;
  final ValueChanged<String> onAvatarTapped;
  final VoidCallback onOpenFullList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('multiplayerAvatarsRail'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tile in tiles)
          Padding(
            padding: const EdgeInsets.only(
              bottom: MultiplayerAvatarsRailMetrics.compactItemGap,
            ),
            child: CompactMultiplayerAvatarTile(
              data: tile,
              onTap: () => onAvatarTapped(tile.player.id),
            ),
          ),
        Tooltip(
          message: l10n.multiplayerStatusTooltip,
          preferBelow: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenFullList,
              borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
              child: const _OpenStatusSheetButton(
                width: MultiplayerAvatarsRailMetrics.compactItemSize,
                height: MultiplayerAvatarsRailMetrics.compactItemSize,
                borderRadius: GameUiTheme.radiusCard,
                onTap: null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpenStatusSheetButton extends StatelessWidget {
  const _OpenStatusSheetButton({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.onTap,
  });

  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      key: const Key('multiplayerAvatarsRail.openSheet'),
      width: width,
      height: height,
      decoration: SurfaceElevation.flat.decoration(
        accent: GameUiTheme.gold,
        backgroundAlpha: 202,
        border: BorderEmphasis.regular,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      child: const Center(
        child: GameIcon(
          GameIcons.activityLog,
          size: GameIconSize.small,
          color: GameUiTheme.gold,
        ),
      ),
    );

    if (onTap == null) return child;

    return Tooltip(
      message: AppLocalizations.of(context).multiplayerStatusTooltip,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      ),
    );
  }
}
