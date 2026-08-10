import 'dart:async';

import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/layout/hud_side_menu_metrics.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_layouts.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatars_rail_metrics.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_status_sheet.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'multiplayer_avatars_rail_gamepad.dart';
part 'multiplayer_avatars_rail_overlay.dart';
part 'multiplayer_avatars_sheet.dart';

class MultiplayerAvatarsRail extends StatelessWidget {
  static const double itemWidth = MultiplayerAvatarsRailMetrics.itemWidth;
  static const double itemHeight = MultiplayerAvatarsRailMetrics.itemHeight;
  static const double compactItemSize =
      MultiplayerAvatarsRailMetrics.compactItemSize;

  const MultiplayerAvatarsRail({
    required this.gameSave,
    required this.activePlayerId,
    required this.onAvatarTapped,
    this.timerLabels = const {},
    this.timedOutPlayerIds = const {},
    this.diplomacy = DiplomacyState.empty,
    this.gameState,
    this.gamepadFocusedTargetId,
    this.gamepadInputListenable,
    this.onGamepadSheetOpenChanged,
    super.key,
  });

  final GameSave gameSave;
  final String activePlayerId;
  final ValueChanged<String> onAvatarTapped;
  final Map<String, String> timerLabels;
  final Set<String> timedOutPlayerIds;
  final DiplomacyState diplomacy;
  final GameClientState? gameState;
  final String? gamepadFocusedTargetId;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;
  final ValueChanged<bool>? onGamepadSheetOpenChanged;

  @override
  Widget build(BuildContext context) {
    if (gameSave.gameMode != GameMode.multiplayer || gameSave.players.isEmpty) {
      return const SizedBox.shrink();
    }
    final size = MediaQuery.sizeOf(context);
    final compact = MultiplayerAvatarsRailMetrics.useCompactLayout(
      width: size.width,
      height: size.height,
    );
    final tiles = tileDataFor(
      context: context,
      gameSave: gameSave,
      activePlayerId: activePlayerId,
      diplomacy: diplomacy,
      gameState: gameState,
      timerLabels: timerLabels,
      timedOutPlayerIds: timedOutPlayerIds,
    );
    if (compact) {
      return CompactMultiplayerAvatarsRail(
        tiles: tiles,
        onAvatarTapped: onAvatarTapped,
        gamepadFocusedTargetId: gamepadFocusedTargetId,
        onOpenFullList: () => unawaited(_showFullListSheet(context, tiles)),
      );
    }
    return ExpandedMultiplayerAvatarsRail(
      key: const Key('multiplayerAvatarsRail'),
      tiles: tiles,
      onAvatarTapped: onAvatarTapped,
      gamepadFocusedTargetId: gamepadFocusedTargetId,
      onOpenFullList: () => unawaited(_showFullListSheet(context, tiles)),
    );
  }

  MultiplayerAvatarStatus statusFor(Player player) => statusForPlayer(
    player: player,
    gameSave: gameSave,
    activePlayerId: activePlayerId,
    timedOutPlayerIds: timedOutPlayerIds,
  );

  static MultiplayerAvatarStatus statusForPlayer({
    required Player player,
    required GameSave gameSave,
    required String activePlayerId,
    Set<String> timedOutPlayerIds = const {},
  }) {
    if (timedOutPlayerIds.contains(player.id)) {
      return MultiplayerAvatarStatus.timeout;
    }
    if (gameSave.playerStates[player.id] == PlayerTurnState.finished) {
      return MultiplayerAvatarStatus.submitted;
    }
    if (player.isAi) return MultiplayerAvatarStatus.thinking;
    if (player.id == activePlayerId) return MultiplayerAvatarStatus.active;
    return MultiplayerAvatarStatus.waiting;
  }

  static List<MultiplayerAvatarTileData> tileDataFor({
    required BuildContext context,
    required GameSave gameSave,
    required String activePlayerId,
    DiplomacyState diplomacy = DiplomacyState.empty,
    GameClientState? gameState,
    Map<String, String> timerLabels = const {},
    Set<String> timedOutPlayerIds = const {},
  }) {
    final l10n = AppLocalizations.of(context);
    return [
      for (final player in gameSave.players)
        MultiplayerAvatarTileData(
          player: player,
          playerName: GameDisplayNames.player(l10n, player),
          status: statusForPlayer(
            player: player,
            gameSave: gameSave,
            activePlayerId: activePlayerId,
            timedOutPlayerIds: timedOutPlayerIds,
          ),
          timerLabel: timerLabels[player.id],
          relationStatus:
              activePlayerId.isEmpty ||
                  player.id == activePlayerId ||
                  !_hasDiplomaticContact(
                    gameState: gameState,
                    diplomacy: diplomacy,
                    playerId: activePlayerId,
                    targetPlayerId: player.id,
                  )
              ? null
              : diplomacy.statusBetween(activePlayerId, player.id),
        ),
    ];
  }

  static Future<void> showPlayersSheet(
    BuildContext context, {
    required GameSave gameSave,
    required String activePlayerId,
    required ValueChanged<String> onAvatarTapped,
    DiplomacyState diplomacy = DiplomacyState.empty,
    Map<String, String> timerLabels = const {},
    Set<String> timedOutPlayerIds = const {},
    GameClientState? gameState,
    Key? sheetRouteKey,
    ValueListenable<GamepadInputSnapshot>? gamepadInputListenable,
  }) {
    return _showPlayersSheet(
      context,
      tiles: tileDataFor(
        context: context,
        gameSave: gameSave,
        activePlayerId: activePlayerId,
        diplomacy: diplomacy,
        gameState: gameState,
        timerLabels: timerLabels,
        timedOutPlayerIds: timedOutPlayerIds,
      ),
      gameState: gameState,
      onAvatarTapped: onAvatarTapped,
      sheetRouteKey: sheetRouteKey,
      gamepadInputListenable: gamepadInputListenable,
    );
  }

  Future<void> _showFullListSheet(
    BuildContext context,
    List<MultiplayerAvatarTileData> tiles,
  ) async {
    onGamepadSheetOpenChanged?.call(true);
    try {
      await _showPlayersSheet(
        context,
        tiles: tiles,
        gameState: gameState,
        onAvatarTapped: onAvatarTapped,
        gamepadInputListenable: gamepadInputListenable,
      );
    } finally {
      onGamepadSheetOpenChanged?.call(false);
    }
  }

  static bool _hasDiplomaticContact({
    required GameClientState? gameState,
    required DiplomacyState diplomacy,
    required String playerId,
    required String targetPlayerId,
  }) {
    if (playerId.isEmpty ||
        targetPlayerId.isEmpty ||
        playerId == targetPlayerId) {
      return false;
    }
    if (diplomacy.hasContact(playerId, targetPlayerId)) return true;
    if (gameState == null) return false;
    return DiplomaticContact.hasContact(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: gameState.fogOfWar,
      units: gameState.units,
      cities: gameState.cities,
    );
  }
}
