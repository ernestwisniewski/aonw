import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';

class PlayerAvatarColumn extends StatelessWidget {
  final GameSave gameSave;
  final String activePlayerId;
  final ValueChanged<String> onAvatarTapped;
  final DiplomacyState diplomacy;
  final GameState? gameState;

  const PlayerAvatarColumn({
    required this.gameSave,
    required this.activePlayerId,
    required this.onAvatarTapped,
    this.diplomacy = DiplomacyState.empty,
    this.gameState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final players = gameSave.players;
    if (players.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];
    for (int index = 0; index < players.length; index++) {
      if (index == 1) {
        items.add(
          Container(width: 1, height: 8, color: const Color(0xFF2a2a40)),
        );
      }

      final player = players[index];
      final playerName = GameDisplayNames.player(l10n, player);
      final isDeviceActive = player.id == activePlayerId;
      final isFinished =
          gameSave.playerStates[player.id] == PlayerTurnState.finished;
      final relationStatus =
          activePlayerId.isEmpty ||
              player.id == activePlayerId ||
              !_hasDiplomaticContact(player.id)
          ? null
          : diplomacy.statusBetween(activePlayerId, player.id);
      final defaultName = l10n.defaultPlayerName(index + 1);
      final relationLabel = relationStatus == null
          ? null
          : MultiplayerRelationStatusStyle.label(l10n, relationStatus);

      items.add(
        Tooltip(
          message: relationLabel == null
              ? l10n.multiplayerPlayerTooltip(playerName, defaultName)
              : l10n.multiplayerPlayerTooltipWithRelation(
                  playerName,
                  defaultName,
                  relationLabel,
                ),
          preferBelow: false,
          child: GestureDetector(
            onTap: () => onAvatarTapped(player.id),
            child: _PlayerAvatar(
              player: player,
              playerName: playerName,
              isDeviceActive: isDeviceActive,
              isFinished: isFinished,
              relationStatus: relationStatus,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: item),
      ],
    );
  }

  bool _hasDiplomaticContact(String targetPlayerId) {
    if (activePlayerId.isEmpty ||
        targetPlayerId.isEmpty ||
        activePlayerId == targetPlayerId) {
      return false;
    }
    if (diplomacy.hasContact(activePlayerId, targetPlayerId)) return true;
    final state = gameState;
    if (state == null) return false;
    return DiplomaticContact.hasContact(
      playerId: activePlayerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final Player player;
  final String playerName;
  final bool isDeviceActive;
  final bool isFinished;
  final DiplomaticRelationStatus? relationStatus;

  const _PlayerAvatar({
    required this.player,
    required this.playerName,
    required this.isDeviceActive,
    required this.isFinished,
    this.relationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final color = PlayerColorTheme.resolve(player.colorValue);
    final size = isDeviceActive ? 44.0 : 34.0;
    final borderWidth = isDeviceActive ? 2.5 : 1.5;
    final borderColor = isDeviceActive
        ? SurfaceElevation.flat.fill(background: GameUiTheme.gold, alpha: 150)
        : SurfaceElevation.flat.fill(background: GameUiTheme.gold, alpha: 70);
    final initial = playerName.isNotEmpty
        ? GameText.uppercase(playerName[0])
        : '?';

    final Widget content = isFinished
        ? GameIcon(
            GameIcons.checkCircle,
            color: Colors.white,
            size: isDeviceActive ? GameIconSize.regular : GameIconSize.small,
          )
        : Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDeviceActive ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          );

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: CircleBorder(
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        shadows: isDeviceActive && !isFinished
            ? [
                BoxShadow(
                  color: SurfaceElevation.flat.fill(
                    background: GameUiTheme.copper,
                    alpha: 90,
                  ),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: content,
    );

    if (!isDeviceActive) {
      avatar = Opacity(opacity: 0.72, child: avatar);
    }

    // Active-dot badge — only shown when device-active AND not finished.
    if ((!isDeviceActive || isFinished) && relationStatus == null) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isDeviceActive && !isFinished)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: ShapeDecoration(
                color: Color.lerp(color, Colors.white, 0.45)!,
                shape: const CircleBorder(
                  side: BorderSide(color: GameUiTheme.surfaceDeep, width: 2),
                ),
                shadows: [
                  BoxShadow(
                    color: SurfaceElevation.flat.fill(
                      background: GameUiTheme.copper,
                      alpha: 90,
                    ),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        if (relationStatus != null)
          Positioned(
            top: -1,
            left: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: ShapeDecoration(
                color: MultiplayerRelationStatusStyle.color(relationStatus!),
                shape: const CircleBorder(
                  side: BorderSide(color: GameUiTheme.surfaceDeep, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
