import 'dart:async';

import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/player_avatar_column.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamePlayerAvatarsOverlay extends ConsumerWidget {
  final GameSave gameSave;
  final DiplomacyState diplomacy;

  const GamePlayerAvatarsOverlay({
    required this.gameSave,
    this.diplomacy = DiplomacyState.empty,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gameSave.players.isEmpty) return const SizedBox.shrink();

    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.watch(gamePlayerControlControllerProvider),
      save: gameSave,
    );
    final gameState = ref.watch(gameStateProvider(gameSave.id)).value;
    final mapData = ref
        .watch(
          activeMapProvider(
            MapSelection(name: gameSave.mapName, source: gameSave.mapSource),
          ),
        )
        .value;

    return PlayerAvatarColumn(
      gameSave: gameSave,
      activePlayerId: playerControl.activePlayerId,
      diplomacy: gameState?.diplomacy ?? diplomacy,
      gameState: gameState,
      onAvatarTapped: (playerId) {
        if (playerId == playerControl.activePlayerId || gameState == null) {
          ref
              .read(gamePlayerControlControllerProvider.notifier)
              .selectPlayer(gameSave, playerId);
          return;
        }
        if (mapData == null) return;
        if (!_hasDiplomaticContact(
          gameState: gameState,
          diplomacy: gameState.diplomacy,
          playerId: playerControl.activePlayerId,
          targetPlayerId: playerId,
        )) {
          return;
        }
        unawaited(
          showDiplomacyPlayerModal(
            context,
            gameSave: gameSave,
            gameState: gameState,
            mapData: mapData,
            activePlayerId: playerControl.activePlayerId,
            targetPlayerId: playerId,
            onCommand: ref
                .read(gameCommandControllerProvider.notifier)
                .dispatch,
          ),
        );
      },
    );
  }

  bool _hasDiplomaticContact({
    required GameState gameState,
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
    return DiplomaticContact.hasContact(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: gameState.fogOfWar,
      units: gameState.units,
      cities: gameState.cities,
    );
  }
}
