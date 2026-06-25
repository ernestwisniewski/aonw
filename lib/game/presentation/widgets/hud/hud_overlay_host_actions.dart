import 'dart:async';

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/hud/turn_action_hint.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HudOverlayHostActions {
  const HudOverlayHostActions({
    required this.ref,
    required this.session,
    required this.gameSave,
    required this.animatingUnitIdsListenable,
  });

  final WidgetRef ref;
  final GameSession session;
  final GameSave gameSave;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;

  void toggleCityBuildings() {
    ref
        .read(hudCommandDispatcherProvider)
        .toggleCityProductionPanel(state: currentState());
  }

  void toggleTechnologyPanel() {
    ref
        .read(hudCommandDispatcherProvider)
        .toggleTechnologyPanel(
          activePlayerId: readPlayerControl().activePlayerId,
          state: currentState(),
        );
  }

  void toggleEmpirePanel() {
    ref
        .read(hudCommandDispatcherProvider)
        .toggleEmpirePanel(
          activePlayerId: readPlayerControl().activePlayerId,
          state: currentState(),
        );
  }

  void toggleObjectivesPanel() {
    ref
        .read(hudCommandDispatcherProvider)
        .toggleObjectivesPanel(
          activePlayerId: readPlayerControl().activePlayerId,
          state: currentState(),
        );
  }

  void toggleActivityLogPanel() {
    ref
        .read(hudCommandDispatcherProvider)
        .toggleActivityLogPanel(
          activePlayerId: readPlayerControl().activePlayerId,
          state: currentState(),
        );
  }

  void closeTechnologyPanel() {
    ref
        .read(hudCommandDispatcherProvider)
        .closeTechnologyPanel(
          activePlayerId: readPlayerControl().activePlayerId,
          state: currentState(),
        );
  }

  void closeObjectivesPanel() {
    ref.read(hudCommandDispatcherProvider).closeObjectivesPanel();
  }

  void closeEmpirePanel() {
    ref.read(hudCommandDispatcherProvider).closeEmpirePanel();
  }

  void openActivityLogPanel() {
    ref
        .read(hudCommandDispatcherProvider)
        .openActivityLogPanel(
          activePlayerId: readPlayerControl().activePlayerId,
          state: currentState(),
        );
  }

  void closeActivityLogPanel() {
    ref.read(hudCommandDispatcherProvider).closeActivityLogPanel();
  }

  void nextAction() {
    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .focusNextAction(
            activePlayerId: readPlayerControl().activePlayerId,
            currentState: currentState,
          ),
    );
  }

  Future<void> endTurn() async {
    final playerControl = readPlayerControl();
    final activePlayerId = playerControl.activePlayerId;
    final gameState = currentState();
    final technologyViewModel = ref.read(
      technologyPanelViewModelProvider(session.saveId, activePlayerId),
    );
    final readyToEndTurn = hudPlayerReadyToEndTurn(
      gameState: gameState,
      activePlayerId: activePlayerId,
      technologyViewModel: technologyViewModel,
    );
    await ref
        .read(hudCommandDispatcherProvider)
        .endTurn(
          animatingUnitIdsListenable: animatingUnitIdsListenable,
          gameSave: gameSave,
          activePlayerId: activePlayerId,
          readyToEndTurn: readyToEndTurn,
          currentState: currentState,
        );
  }

  GameState? currentState() {
    if (session.saveId.isEmpty) return null;
    return ref.read(gameStateProvider(session.saveId)).value;
  }

  PlayerControlState readPlayerControl() {
    return PlayerControlCoordinator.normalize(
      current: ref.read(gamePlayerControlControllerProvider),
      save: gameSave,
    );
  }
}
