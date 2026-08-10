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

part 'multiplayer_empire_stats_panel.dart';
part 'multiplayer_player_stats_row.dart';

class MultiplayerStatusSheet extends StatelessWidget {
  const MultiplayerStatusSheet({
    required this.tiles,
    required this.onAvatarTapped,
    this.gameState,
    super.key,
  });

  final List<MultiplayerAvatarTileData> tiles;
  final GameClientState? gameState;
  final ValueChanged<String> onAvatarTapped;

  @override
  Widget build(BuildContext context) {
    final data = MultiplayerStatusSheetData.from(
      tiles: tiles,
      gameState: gameState,
    );
    return LayoutBuilder(
      builder: (context, constraints) => _MultiplayerStatusLayout(
        tiles: tiles,
        data: data,
        maxWidth: constraints.maxWidth,
        onAvatarTapped: onAvatarTapped,
      ),
    );
  }
}

class _MultiplayerStatusLayout extends StatelessWidget {
  static const _wideLayoutBreakpoint = 560.0;
  static const _minLeaderTileWidth = 260.0;
  static const _maxLeaderTileWidth = 340.0;

  const _MultiplayerStatusLayout({
    required this.tiles,
    required this.data,
    required this.maxWidth,
    required this.onAvatarTapped,
  });

  final List<MultiplayerAvatarTileData> tiles;
  final MultiplayerStatusSheetData data;
  final double maxWidth;
  final ValueChanged<String> onAvatarTapped;

  @override
  Widget build(BuildContext context) {
    final availableWidth = maxWidth.isFinite ? maxWidth : _minLeaderTileWidth;
    final wide = availableWidth >= _wideLayoutBreakpoint;
    final tileWidth = wide
        ? math.min(
            _maxLeaderTileWidth,
            math.max(_minLeaderTileWidth, availableWidth * 0.38),
          )
        : math.max(_minLeaderTileWidth, availableWidth);
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
  }
}
