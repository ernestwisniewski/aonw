import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_parts.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_metrics.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';

class MultiplayerAvatarTile extends StatelessWidget {
  const MultiplayerAvatarTile({
    required this.player,
    required this.playerName,
    required this.status,
    required this.timerLabel,
    required this.onTap,
    this.relationStatus,
    this.width = MultiplayerAvatarsRailMetrics.itemWidth,
    super.key,
  });

  final Player player;
  final String playerName;
  final MultiplayerAvatarStatus status;
  final String? timerLabel;
  final DiplomaticRelationStatus? relationStatus;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playerColor = PlayerColorTheme.resolve(player.colorValue);
    final statusColor = MultiplayerAvatarStatusStyle.color(status, playerColor);
    final active =
        status == MultiplayerAvatarStatus.active ||
        status == MultiplayerAvatarStatus.thinking;
    final statusLabel = MultiplayerAvatarStatusStyle.label(l10n, status);

    final relationLabel = relationStatus == null
        ? null
        : MultiplayerRelationStatusStyle.label(l10n, relationStatus!);

    return Tooltip(
      message: relationLabel == null
          ? l10n.multiplayerAvatarTooltip(playerName, statusLabel)
          : l10n.multiplayerAvatarTooltipWithRelation(
              playerName,
              statusLabel,
              relationLabel,
            ),
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: GameUiTheme.pillBorderRadius,
          child: Container(
            key: Key('multiplayerAvatarTile.${player.id}.${status.name}'),
            width: width,
            height: MultiplayerAvatarsRailMetrics.itemHeight,
            decoration: SurfaceElevation.raised.decoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SurfaceElevation.raised.fill(
                    background: GameUiTheme.surface,
                    alpha: 230,
                  ),
                  SurfaceElevation.raised.fill(
                    background: GameUiTheme.surfaceDeep,
                    alpha: 230,
                  ),
                ],
              ),
              shape: SurfaceShape.pill,
              border: BorderEmphasis.regular,
              includeShadow: false,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: SurfaceElevation.flat.fill(
                          background: GameUiTheme.copper,
                          alpha: 90,
                        ),
                        blurRadius: 16,
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                PlayerColorDot(color: playerColor, active: active),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.actionLabel.copyWith(
                      color: active
                          ? GameUiTheme.textBright
                          : GameUiTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (timerLabel != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    timerLabel!,
                    style: GameUiTheme.bodySmall.copyWith(
                      color: statusColor,
                      fontSize: 10,
                    ),
                  ),
                ],
                if (relationStatus != null) ...[
                  const SizedBox(width: 5),
                  _RelationChip(status: relationStatus!),
                ],
                const SizedBox(width: 7),
                MultiplayerStatusIcon(status: status, color: statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompactMultiplayerAvatarTile extends StatelessWidget {
  const CompactMultiplayerAvatarTile({
    required this.data,
    required this.onTap,
    super.key,
  });

  final MultiplayerAvatarTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playerColor = PlayerColorTheme.resolve(data.player.colorValue);
    final active =
        data.status == MultiplayerAvatarStatus.active ||
        data.status == MultiplayerAvatarStatus.thinking;
    final initials = data.playerName.trim().isEmpty
        ? '?'
        : GameText.uppercase(data.playerName.trim().characters.first);

    final relationLabel = data.relationStatus == null
        ? null
        : MultiplayerRelationStatusStyle.label(l10n, data.relationStatus!);

    return Tooltip(
      message: relationLabel == null
          ? l10n.multiplayerAvatarTooltip(
              data.playerName,
              MultiplayerAvatarStatusStyle.label(l10n, data.status),
            )
          : l10n.multiplayerAvatarTooltipWithRelation(
              data.playerName,
              MultiplayerAvatarStatusStyle.label(l10n, data.status),
              relationLabel,
            ),
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
          child: Container(
            key: Key(
              'multiplayerCompactAvatarTile.${data.player.id}.${data.status.name}',
            ),
            width: MultiplayerAvatarsRailMetrics.compactItemSize,
            height: MultiplayerAvatarsRailMetrics.compactItemSize,
            decoration: SurfaceElevation.raised.decoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SurfaceElevation.raised.fill(
                    background: GameUiTheme.surface,
                    alpha: 230,
                  ),
                  SurfaceElevation.raised.fill(
                    background: GameUiTheme.surfaceDeep,
                    alpha: 230,
                  ),
                ],
              ),
              shape: SurfaceShape.card,
              border: BorderEmphasis.regular,
              includeShadow: false,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: SurfaceElevation.flat.fill(
                          background: GameUiTheme.copper,
                          alpha: 90,
                        ),
                        blurRadius: 16,
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Text(
                    initials,
                    style: GameUiTheme.actionLabel.copyWith(
                      color: active
                          ? GameUiTheme.textBright
                          : GameUiTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: CompactStatusBadge(
                    status: data.status,
                    color: MultiplayerAvatarStatusStyle.color(
                      data.status,
                      playerColor,
                    ),
                  ),
                ),
                if (data.relationStatus != null)
                  Positioned(
                    left: -2,
                    top: -2,
                    child: _CompactRelationBadge(status: data.relationStatus!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationChip extends StatelessWidget {
  const _RelationChip({required this.status});

  final DiplomaticRelationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = MultiplayerRelationStatusStyle.color(status);
    return Container(
      key: Key('multiplayerRelationChip.${status.name}'),
      constraints: const BoxConstraints(minWidth: 34, maxWidth: 42),
      height: 16,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        border: Border.all(color: color.withAlpha(150), width: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        MultiplayerRelationStatusStyle.shortLabel(
          AppLocalizations.of(context),
          status,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: GameUiTheme.chipLabel.copyWith(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactRelationBadge extends StatelessWidget {
  const _CompactRelationBadge({required this.status});

  final DiplomaticRelationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = MultiplayerRelationStatusStyle.color(status);
    return Container(
      width: 11,
      height: 11,
      decoration: ShapeDecoration(
        color: color,
        shape: const CircleBorder(
          side: BorderSide(color: GameUiTheme.surfaceDeep, width: 1.5),
        ),
      ),
    );
  }
}
